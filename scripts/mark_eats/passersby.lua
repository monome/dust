-- Passersby
--
-- MIDI controlled West Coast
-- style mono synth.
--
-- ENC1/KEY2 : Change page
-- KEY3 : Change tab
-- ENC2/3 : Adjust parameters
--
-- Responds to MIDI notes.
--
-- v1.0.0 Mark Eats
--

local MusicUtil = require "mark_eats/musicutil"
local Graph = require "mark_eats/graph"
local EnvGraph = require "mark_eats/envgraph"
local Passersby = require "mark_eats/passersby"

local SCREEN_FRAMERATE = 15
local screen_refresh_metro
local screen_dirty = true

local PAGES = 4
local page_id = 1
local tab_id = 1

local input_indicator_active = false
local input_indicator_metro
local wave_table = {}
local wave = {}
local wave_graph
local SUB_SAMPLING = 4
local fm_graph
local lpg_graph
local lpg_status = {}
local lpg_status_metro
local spring_path = {}
local lfo_graph
local dice_throw_vel = 0
local dice_throw_progress = 0
local dice_thrown = false
local dice_need_update = false
local dice = {}

local mod_wheel = 0
local wave_shape = {actual = 0, modu = 0, dirty = true}
local wave_folds = {actual = 0, modu = 0, dirty = true}
local fm1_amount = {actual = 0, modu = 0, dirty = true}
local fm2_amount = {actual = 0, modu = 0, dirty = true}
local lpg_peak = {actual = 0, modu = 1, dirty = true}
local lpg_decay = {actual = 0, modu = 0, dirty = true}
local reverb_mix = {actual = 0, modu = 0, dirty = true}
local lfo_freq = {dirty = true}
local lfo_amount = {dirty = true}
local lfo_destinations = {dirty = true}
local drift = {actual = 0, dirty = true}

engine.name = "Passersby"


-- Utilities

local function generate_wave_table(cycles, length)
  local wave_table = {{},{},{},{}}
  for sx = 1, length do
    local x = util.linlin(1, length, 0, cycles, sx)
    local square = math.abs(x * 2 % 2 - 1) - 0.5
    square = square > 0 and 0.5 or math.floor(square) * 0.5
    table.insert(wave_table[1], math.sin(x * 2 * math.pi)) -- Sine
    table.insert(wave_table[2], math.abs((x * 2 - 0.5) % 2 - 1) * 2 - 1) -- Tri
    table.insert(wave_table[3], square) -- Square
    table.insert(wave_table[4], (1 - (x + 0.25) % 1) * 2 - 1) -- Saw
  end
  return wave_table
end

local function generate_wave(x)
  
  x = util.round(x)
  local index_f = wave_shape.actual * (#wave_table - 1) + 1
  local index = util.round(index_f)
  local delta = index_f - index
  
  local index_offset = delta < 0 and -1 or 1
  local y
  
  -- Wave table lookup
  if delta == 0 then
    y = wave_table[index][x]
  else
    y = wave_table[index + index_offset][x] * math.abs(delta) + wave_table[index][x] * (1 - math.abs(delta))
  end
  
  -- Wave folding
  y = y * (1 + wave_folds.actual)
  local abs_y = math.abs(y)
  
  if abs_y > 1 then
    local folded = abs_y % 1
    if math.floor(abs_y - 1) % 2 == 0 then
      folded = 1 - folded
    else
      folded = folded
    end
    folded = folded * 2 - 1
    if y < 0 then folded = folded * -1 end
    y = folded
  end
  
  return y
end

local function generate_spring_path(width, height, turns)
  local spring_path = {}
  for y = 0, height - 1 do
    local progress = util.linlin(0, height - 1, 0, math.pi * turns * 2, y)
    table.insert(spring_path, {x = width * 0.5 + math.sin(progress) * width * 0.5, y = y})
  end
  return spring_path
end

local function generate_lfo_wave(x)
  x = x * util.linlin(Passersby.specs.LFO_FREQ.minval, Passersby.specs.LFO_FREQ.maxval, 0.5, 10, params:get("LFO Frequency"))
  return (math.abs((x * 2 - 0.5) % 2 - 1) * 2 - 1) * params:get("LFO Amount")
end

local function randomize_dice()
  for i = 1, 2 do
    local direction = 0
    if dice[i] then
      direction = (dice[i].top_angle - dice[i].table_angle > 0) and 1 or -1
    end
    dice[i] = {}
    dice[i].face = math.random(6)
    dice[i].top_angle = 1 + math.random() * 2
    if math.random() > 0.5 then dice[i].top_angle = dice[i].top_angle * -1 end
    dice[i].table_angle = math.random() * 0.5 - 0.25 + (2 * math.pi * direction)
  end
end

local function set_dice_throw_vel(vel_delta)
  dice_throw_vel = util.clamp(dice_throw_vel + vel_delta, -0.35, 0.3)
  dice_need_update = true
end

local function start_input_indicator_timeout()
  input_indicator_active = true
  screen_dirty = true
  if input_indicator_metro.is_running then
    input_indicator_metro:stop()
  end
  input_indicator_metro:start(0.25, 1)
end

local function start_lpg_status_timeout(status_text, x, y)
  lpg_status.text = status_text
  lpg_status.x, lpg_status.y = x, y
  if lpg_status_metro.is_running then
    lpg_status_metro:stop()
  end
  lpg_status_metro:start(1, 1)
end

local function update_tabs()
  if tab_id == 1 then
    wave_graph:set_active(true)
    lpg_graph:set_active(true)
    lfo_graph:set_active(true)
  else
    wave_graph:set_active(false)
    lpg_graph:set_active(false)
    lpg_status.text = ""
    lfo_graph:set_active(false)
  end
end

local function set_page(id)
  page_id = util.clamp(id, 1, PAGES)
  tab_id = 1
  lpg_status.text = ""
  update_tabs()
  screen_dirty = true
end

local function set_page_delta(delta, loop)
  local id
  if loop then
    id = page_id % PAGES + delta
  else
    id = page_id + delta
  end
  set_page(id)
end

local function set_tab(id)
  tab_id = util.clamp(id, 1, 2)
  update_tabs()
  screen_dirty = true
end

local function set_tab_delta(delta, loop)
  local id
  if loop then
    id = tab_id % 2 + delta
  else
    id = tab_id + delta
  end
  set_tab(id)
end


-- Engine functions

local function note_on(note_num, vel)
  engine.noteOn(note_num, MusicUtil.note_num_to_freq(note_num), util.linlin(0, 127, 0, 1, vel))
end

local function set_pitch_bend(bend_st)
  engine.pitchBend(MusicUtil.interval_to_ratio(bend_st))
end

local function set_mod_wheel(value)
  mod_wheel = value * 0.5
  engine.waveFolds(params:get("Wave Folds") + mod_wheel)
  wave_folds.dirty = true
end

-- Updaters

local function update_wave_shape()
  wave_shape.actual = util.clamp(params:get("Wave Shape") + wave_shape.modu, Passersby.specs.WAVE_SHAPE.minval, Passersby.specs.WAVE_SHAPE.maxval)
  wave_graph:update_functions()
  wave_shape.dirty = false
  screen_dirty = true
end

local function update_wave_folds()
  wave_folds.actual = util.clamp(params:get("Wave Folds") + mod_wheel + wave_folds.modu, Passersby.specs.WAVE_FOLDS.minval, Passersby.specs.WAVE_FOLDS.maxval)
  wave_graph:update_functions()
  wave_folds.dirty = false
  screen_dirty = true
end

local function update_fm1_amount()
  fm1_amount.actual = util.clamp(params:get("FM Low Amount") + fm1_amount.modu, Passersby.specs.FM_LOW_AMOUNT.minval, Passersby.specs.FM_LOW_AMOUNT.maxval)
  fm1_amount.dirty = false
  screen_dirty = true
end

local function update_fm2_amount()
  fm2_amount.actual = util.clamp(params:get("FM High Amount") + fm2_amount.modu, Passersby.specs.FM_HIGH_AMOUNT.minval, Passersby.specs.FM_HIGH_AMOUNT.maxval)
  fm2_amount.dirty = false
  screen_dirty = true
end

local function update_lpg_peak()
  lpg_peak.actual = util.clamp(params:get("LPG Peak") * lpg_peak.modu, Passersby.specs.LPG_PEAK.minval, Passersby.specs.LPG_PEAK.maxval)
  local norm_peak = util.explin(Passersby.specs.LPG_PEAK.minval * 0.5, Passersby.specs.LPG_PEAK.maxval, 0, 1, lpg_peak.actual)
  lpg_graph:edit_ar(nil, nil, norm_peak)
  lpg_peak.dirty = false
  screen_dirty = true
end

local function show_lpg_peak_status()
  local norm_peak = util.explin(Passersby.specs.LPG_PEAK.minval * 0.5, Passersby.specs.LPG_PEAK.maxval, 0, 1, params:get("LPG Peak") * lpg_peak.modu)
  start_lpg_status_timeout(params:string("LPG Peak"), 57, util.linlin(0, 1, 56, 26, norm_peak))
  screen_dirty = true
end

local function update_lpg_decay()
  lpg_decay.actual = util.clamp(params:get("LPG Decay") + lpg_decay.modu, Passersby.specs.LPG_DECAY.minval, Passersby.specs.LPG_DECAY.maxval)
  local norm_decay = util.explin(Passersby.specs.LPG_DECAY.minval * 0.5, Passersby.specs.LPG_DECAY.maxval, 0, 1, lpg_decay.actual)
  lpg_graph:edit_ar(nil, norm_decay)
  lpg_decay.dirty = false
  screen_dirty = true
end

local function show_lpg_decay_status()
  local norm_decay = util.explin(Passersby.specs.LPG_DECAY.minval * 0.5, Passersby.specs.LPG_DECAY.maxval, 0, 1, params:get("LPG Decay") + lpg_decay.modu)
  start_lpg_status_timeout(params:string("LPG Decay"), util.linlin(0, 1, 36, 58, norm_decay), 48)
  screen_dirty = true
end

local function update_reverb_mix()
  reverb_mix.actual = util.clamp(params:get("Reverb Mix") + reverb_mix.modu, Passersby.specs.REVERB_MIX.minval, Passersby.specs.REVERB_MIX.maxval)
  reverb_mix.dirty = false
  screen_dirty = true
end

local function update_lfo_freq()
  lfo_graph:update_functions()
  lfo_freq.dirty = false
  screen_dirty = true
end

local function update_lfo_amount()
  lfo_graph:update_functions()
  lfo_amount.dirty = false
  screen_dirty = true
end

local function update_lfo_destinations()
  lfo_destinations.dirty = false
  screen_dirty = true
end

local function update_drift()
  drift.dirty = false
  screen_dirty = true
end


-- Init

function init()
  
  -- Add params
  
  local channels = {"All"}
  for i = 1, 16 do table.insert(channels, i) end
  params:add_option("MIDI Channel", channels)
  
  params:add_separator()
  
  Passersby.add_params()
  
  -- Override param actions
  
  params:set_action("Wave Shape", function(value)
    engine.waveShape(value)
    wave_shape.dirty = true
  end)
  
  params:set_action("Wave Folds", function(value)
    engine.waveFolds(value + mod_wheel)
    wave_folds.dirty = true
  end)
  
  params:set_action("FM Low Amount", function(value)
    engine.fm1Amount(value)
    fm1_amount.dirty = true
  end)
  
  params:set_action("FM High Amount", function(value)
    engine.fm2Amount(value)
    fm2_amount.dirty = true
  end)
  
  params:set_action("LPG Peak", function(value)
    engine.lpgPeak(value)
    if page_id == 2 then show_lpg_peak_status() end
    lpg_peak.dirty = true
  end)
  
  params:set_action("LPG Decay", function(value)
    engine.lpgDecay(value)
    if page_id == 2 then show_lpg_decay_status() end
    lpg_decay.dirty = true
  end)
  
  params:set_action("Reverb Mix", function(value)
    engine.reverbMix(value)
    reverb_mix.dirty = true
  end)
  
  params:set_action("LFO Frequency", function(value)
    engine.lfoFreq(value)
    lfo_freq.dirty = true
  end)
  
  params:set_action("LFO Amount", function(value)
    engine.lfoAmount(value)
    lfo_amount.dirty = true
  end)
  
  for i = 1, 2 do
    params:set_action("LFO Destination " .. i, function(value)
      engine.lfoDest(i - 1, value - 1)
      lfo_destinations.dirty = true
    end)
  end
  
  params:set_action("Drift", function(value)
    engine.drift(value)
    drift.dirty = true
  end)
  
  wave_shape.actual = params:get("Wave Shape")
  wave_folds.actual = params:get("Wave Folds")
  fm1_amount.actual = params:get("FM Low Amount")
  fm2_amount.actual = params:get("FM High Amount")
  lpg_peak.actual = params:get("LPG Peak")
  lpg_decay.actual = params:get("LPG Decay")
  reverb_mix.actual = params:get("Reverb Mix")
  drift.actual = params:get("Drift")
  
  input_indicator_metro = metro.alloc()
  input_indicator_metro.callback = function(stage)
    input_indicator_active = false
    screen_dirty = true
  end

  -- Init graphs
  
  wave_graph = Graph.new(0, 2, "lin", -1, 1, "lin", nil, true, false)
  wave_graph:set_position_and_size(8, 22, 49, 36)
  wave_table = generate_wave_table(2, wave_graph:get_width() * SUB_SAMPLING)
  local wave_func = function(x)
    return generate_wave(util.linlin(0, 2, 1, wave_graph:get_width() * SUB_SAMPLING, x))
  end
  wave_graph:add_function(wave_func, SUB_SAMPLING)
  
  lpg_graph = EnvGraph.new_ar(0, 1, 0, 1, 0.003, util.explin(Passersby.specs.LPG_DECAY.minval * 0.5, Passersby.specs.LPG_DECAY.maxval, 0, 1, lpg_decay.actual), util.explin(Passersby.specs.LPG_PEAK.minval * 0.5, Passersby.specs.LPG_PEAK.maxval, 0, 1, lpg_peak.actual), -4)
  lpg_graph:set_position_and_size(8, 22, 49, 36)
  lpg_graph:set_show_x_axis(true)
  
  lfo_graph = Graph.new(0, 1, "lin", -1, 1, "lin", nil, true, false)
  lfo_graph:set_position_and_size(8, 18, 49, 36)
  lfo_graph:add_function(generate_lfo_wave, SUB_SAMPLING)
  
  lpg_status.text = ""
  lpg_status.x, lpg_status.y = 0, 0
  lpg_status_metro = metro.alloc()
  lpg_status_metro.callback = function(stage)
    lpg_status.text = ""
    screen_dirty = true
  end
  
  spring_path = generate_spring_path(10, 36, 5)
  
  randomize_dice()
  
  -- Init polls
  
  local wave_shape_poll = poll.set("waveShapeMod", function(value)
    if wave_shape.modu ~= value then
      wave_shape.modu = value
      wave_shape.dirty = true
    end
  end)
  wave_shape_poll:start()
  
  local wave_folds_poll = poll.set("waveFoldsMod", function(value)
    if wave_folds.modu ~= value then
      wave_folds.modu = value
      wave_folds.dirty = true
    end
  end)
  wave_folds_poll:start()
  
  local fm1_amount_poll = poll.set("fm1AmountMod", function(value)
    if fm1_amount.modu ~= value then
      fm1_amount.modu = value
      fm1_amount.dirty = true
    end
  end)
  fm1_amount_poll:start()
  
  local fm2_amount_poll = poll.set("fm2AmountMod", function(value)
    if fm2_amount.modu ~= value then
      fm2_amount.modu = value
      fm2_amount.dirty = true
    end
  end)
  fm2_amount_poll:start()
  
  local lpg_peak_poll = poll.set("lpgPeakMulMod", function(value)
    if lpg_peak.modu ~= value then
      lpg_peak.modu = value
      lpg_peak.dirty = true
    end
  end)
  lpg_peak_poll:start()
  
  local lpg_decay_poll = poll.set("lpgDecayMod", function(value)
    if lpg_decay.modu ~= value then
      lpg_decay.modu = value
      lpg_decay.dirty = true
    end
  end)
  lpg_decay_poll:start()
  
  local reverb_mix_poll = poll.set("reverbMixMod", function(value)
    if reverb_mix.modu ~= value then
      reverb_mix.modu = value
      reverb_mix.dirty = true
    end
  end)
  reverb_mix_poll:start()
  
  -- Start drawing to screen
  screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function(stage)
    update()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  
end



-- Input functions

-- Encoder input
function enc(n, delta)
  
  if n == 1 then
    -- Page scroll
    set_page_delta(util.clamp(delta, -1, 1), false)
  end
  
  if page_id == 1 then
    
      if tab_id == 1 then
        -- Wave
        if n == 2 then
          params:delta("Wave Shape", delta)
        elseif n == 3 then
          params:delta("Wave Folds", delta)
        end
        
      else
        -- FM
        if n == 2 then
          params:delta("FM Low Amount", delta)
        elseif n == 3 then
          params:delta("FM High Amount", delta)
        end
      end
      
  elseif page_id == 2 then
    
      if tab_id == 1 then
        -- LPG
        if n == 2 then
          params:delta("LPG Peak", delta)
        elseif n == 3 then
          params:delta("LPG Decay", delta)
        end
        
      else
        -- Reverb
        if n == 2 then
          params:delta("Reverb Mix", delta)
        end
      end
      
  elseif page_id == 3 then
    
    if tab_id == 1 then
      -- LFO
      if n == 2 then
        params:delta("LFO Frequency", delta)
      elseif n == 3 then
        params:delta("LFO Amount", delta)
      end
    
    else
      -- Destinations
      if n == 2 then
        params:delta("LFO Destination " .. 1, util.clamp(delta, -1, 1))
      elseif n == 3 then
        params:delta("LFO Destination " .. 2, util.clamp(delta, -1, 1))
      end
      
    end
      
  elseif page_id == 4 then
    
    -- Randomize
    if n == 2 then
      if not dice_thrown then set_dice_throw_vel(delta * 0.05) end
      
    -- Drift
    elseif n == 3 then
      params:delta("Drift", delta)
    end
    
  end
end

-- Key input
function key(n, z)
  if z == 1 then
    
    if n == 2 then
      set_page_delta(1, true)
      
    elseif n == 3 then
      set_tab_delta(1, true)
      
    end
  end
end

-- MIDI input
local function midi_event(data)
  
  if #data == 0 then return end
  
  local midi_status = data[1]
  local data1 = data[2]
  local data2 = data[3]
  
  -- Note on
  if (params:get("MIDI Channel") == 1 and midi_status >= 144 and midi_status <= 159 ) or (params:get("MIDI Channel") > 1 and midi_status == 144 + params:get("MIDI Channel") - 2) then
    note_on(data1, data2)
    start_input_indicator_timeout()
    
  -- Note off
  -- elseif (params:get("MIDI Channel") == 1 and midi_status >= 128 and midi_status <= 143 ) or (params:get("MIDI Channel") > 1 and midi_status == 128 + params:get("MIDI Channel") - 2) then
    
  -- CC
  elseif (params:get("MIDI Channel") == 1 and midi_status >= 176 and midi_status <= 191 ) or  (params:get("MIDI Channel") > 1 and midi_status == 176 + params:get("MIDI Channel") - 2) then
    -- Mod wheel
    if data1 == 1 then
      set_mod_wheel(util.linlin(0, 127, 0, 1, data2))
    end
    
  -- Pitch bend
  elseif (params:get("MIDI Channel") == 1 and midi_status >= 224 and midi_status <= 239 ) or  (params:get("MIDI Channel") > 1 and midi_status == 224 + params:get("MIDI Channel") - 2) then
    local bend_14bit = bit32.bor(bit32.lshift(data2, 7), data1)
    local bend_st = (util.round(bend_14bit / 2)) / 8192 * 2 -1 -- Convert to -1 to 1
    set_pitch_bend(bend_st * 2) -- 2 Semitones of bend
    
  end
end

midi.add = function(dev)
  dev.event = midi_event
end

function cleanup()
  for id, dev in pairs(midi.devices) do
    dev.event = nil
  end
end


-- Draw functions

local function rotate(x, y, center_x, center_y, angle_rads)
  local sin_a = math.sin(angle_rads)
  local cos_a = math.cos(angle_rads)
  x = x - center_x
  y = y - center_y
  return (x * cos_a - y * sin_a) + center_x, (x * sin_a + y * cos_a) + center_y
end

local function draw_page_dots(index, total_pages)
  local dots_y = util.round((64 - total_pages * 4 - (total_pages - 1) * 2) * 0.5)
  for i = 1, total_pages do
    if i == index then screen.level(5)
    else screen.level(1) end
    screen.rect(127, dots_y, 1, 4)
    screen.fill()
    dots_y = dots_y + 6
  end
end

local function draw_input_indicator()
  screen.level(4)
  screen.move(0, 1)
  screen.line(5, 1)
  screen.line(2.5, 4)
  screen.close()
  screen.fill()
end

local function draw_background_rects()
  screen.level(1)
  screen.rect(8, 18, 49, 44)
  screen.fill()
  screen.rect(71, 18, 49, 44)
  screen.fill()
end

local function draw_tabs(titles_array, active)
  local margin = 8
  local gutter = 14
  local col_width = (128 - (margin * 2) - gutter * (#titles_array - 1)) / #titles_array
  for i = 1, #titles_array do
    if i == active then screen.level(15)
    else screen.level(3) end
    screen.move(margin + col_width * 0.5 + ((col_width + gutter) * (i - 1)), 6)
    screen.text_center(titles_array[i])
  end
end

local function draw_dial(value, x, y, size, active)
  local radius = size * 0.5
  local start_angle = math.pi * 0.7
  local end_angle = math.pi * 2.3
  
  screen.level(5)
  screen.arc(x + radius, y + radius, radius - 0.5, util.linlin(0, 1, start_angle, end_angle, value), end_angle)
  screen.stroke()
  
  screen.level(15)
  screen.line_width(2.5)
  screen.arc(x + radius, y + radius, radius - 0.5, start_angle, util.linlin(0, 1, start_angle, end_angle, value))
  screen.stroke()
  screen.line_width(1)
  
  if active then screen.level(15) else screen.level(3) end
  screen.move(x + radius, y + size + 6)
  screen.text_center(util.round(value * 100, 1))
  screen.fill()
end

local function draw_slider(value, x, y, width, height, active)
  screen.level(3)
  screen.rect(x + 0.5, y + 0.5, width - 1, height - 1)
  screen.stroke()
  local filled_height = util.round(util.linlin(0, 1, 0, height, value))
  screen.rect(x, y + height - filled_height, width, filled_height)
  if active then screen.level(15) else screen.level(5) end
  screen.fill()
end

local function draw_spring(x, y, active)
  screen.move(x + spring_path[1].x + 0.5, y + spring_path[1].y + 0.5)
  for i = 2, #spring_path do
    screen.line(x + spring_path[i].x + 0.5, y + spring_path[i].y + 0.5)
  end
  if active then
    screen.level(15)
    screen.line_width(0.7)
  else
    screen.level(5)
  end
  screen.stroke()
  screen.line_width(1)
end

local function draw_die(x, y, rotation_rads, face)
  screen.level(15)
  local size = 9
  screen.move(rotate(x - size + 0.5, y - size + 0.5, x, y, rotation_rads))
  screen.line(rotate(x + size - 0.5, y - size + 0.5, x, y, rotation_rads))
  screen.line(rotate(x + size - 0.5, y + size - 0.5, x, y, rotation_rads))
  screen.line(rotate(x - size + 0.5, y + size - 0.5, x, y, rotation_rads))
  screen.close()
  screen.stroke()
  
  local dot_size = 1
  local dx, dy
  if face == 1 then
    dot_size = 1.5
    dx, dy = rotate(x, y, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
  elseif face == 2 then
    dx, dy = rotate(x + 3, y - 3, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x - 3, y + 3, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
  elseif face == 3 then
    dx, dy = rotate(x + 4, y - 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x, y, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x - 4, y + 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
  elseif face == 4 then
    dx, dy = rotate(x - 3, y - 3, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x + 3, y - 3, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x + 3, y + 3, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x - 3, y + 3, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
  elseif face == 5 then
    dx, dy = rotate(x, y, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x - 4, y - 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x + 4, y - 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x + 4, y + 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x - 4, y + 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
  elseif face == 6 then
    dx, dy = rotate(x - 3, y - 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x + 3, y - 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x - 3, y, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x + 3, y, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x - 3, y + 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
    dx, dy = rotate(x + 3, y + 4, x, y, rotation_rads)
    screen.circle(dx, dy, dot_size)
    screen.fill()
  end
end

local function draw_dice()
  draw_die(20, util.linlin(0, 1, 32, 17, dice_throw_progress), util.linlin(0, 1, dice[1].table_angle, dice[1].top_angle, dice_throw_progress), dice[1].face)
  draw_die(45, util.linlin(0, 1, 46, 61, dice_throw_progress), util.linlin(0, 1, dice[2].table_angle, dice[2].top_angle, dice_throw_progress), dice[2].face)
end

local function update_dice()
  if not dice_need_update then return end
  
  if dice_thrown then
    if dice_throw_progress < 0.05 then
      for i = 1, 2 do
        local direction = (dice[i].table_angle > 0) and 1 or -1
        dice[i].table_angle = dice[i].table_angle - (2 * math.pi * direction)
      end
      dice_thrown = false
    end
    set_dice_throw_vel(-0.08)
  else
    if dice_throw_progress > 0.9 then
      dice_thrown = true
      randomize_dice()
      Passersby.randomize_params()
      set_dice_throw_vel(-0.3)
    else
      set_dice_throw_vel(util.linlin(0, 1, -0.02, -0.03, dice_throw_progress))
    end
  end
  
  if dice_throw_progress <= 0 then
    dice_throw_vel = math.max(dice_throw_vel, 0)
  end
  
  dice_throw_progress = util.clamp(dice_throw_progress + dice_throw_vel, 0, 1)
  
  if page_id == 4 then screen_dirty = true end
  if dice_throw_progress == 0 and not dice_thrown then dice_need_update = false end
end

function update()
  
  if page_id == 1 then
    if wave_shape.dirty then update_wave_shape() end
    if wave_folds.dirty then update_wave_folds() end
    if fm1_amount.dirty then update_fm1_amount() end
    if fm2_amount.dirty then update_fm2_amount() end
  elseif page_id == 2 then
    if lpg_peak.dirty then update_lpg_peak() end
    if lpg_decay.dirty then update_lpg_decay() end
    if reverb_mix.dirty then update_reverb_mix() end
  elseif page_id == 3 then
    if lfo_freq.dirty then update_lfo_freq() end
    if lfo_amount.dirty then update_lfo_amount() end
    if lfo_destinations.dirty then update_lfo_destinations() end
  elseif page_id == 4 then
    if drift.dirty then update_drift() end
  end
  
  update_dice()
end

function redraw()
  screen.clear()
  screen.aa(1)
  
  draw_page_dots(page_id, PAGES)
  
  if input_indicator_active then draw_input_indicator() end
  
  -- draw_background_rects()
  
  if page_id == 1 then
    
    draw_tabs({"Wave", "FM"}, tab_id)
    
    -- Wave
    wave_graph:redraw()
    
    -- FM
    screen.level(3)
    screen.move(83, 33)
    screen.text_center("L")
    screen.move(108, 48)
    screen.text_center("H")
    screen.fill() -- Prevents extra line
    draw_dial(fm1_amount.actual, 72, 19, 22, tab_id == 2)
    draw_dial(fm2_amount.actual, 97, 34, 22, tab_id == 2)
    
  elseif page_id == 2 then
    
    draw_tabs({"LPG", "Reverb"}, tab_id)
    
    -- LPG
    lpg_graph:redraw()
    screen.level(3)
    screen.move(lpg_status.x, lpg_status.y)
    screen.text_right(lpg_status.text)
    
    -- Reverb
    screen.fill()
    draw_spring(82, 22, tab_id == 2)
    screen.rect(100, 40, 7, 1)
    screen.level(3)
    screen.fill()
    draw_slider(reverb_mix.actual, 102, 22, 3, 36, true)
    
  elseif page_id == 3 then
    
    draw_tabs({"LFO", "Targets"}, tab_id)
    
    -- LFO
    lfo_graph:redraw()
    screen.level(3)
    screen.move(8, 62)
    screen.text(params:string("LFO Frequency"))
    
    -- LFO Targets
    if tab_id == 2 then screen.level(15) else screen.level(3) end
    screen.move(71, 33)
    screen.text(Passersby.LFO_DESTINATIONS[params:get("LFO Destination 1")])
    screen.move(71, 49)
    screen.text(Passersby.LFO_DESTINATIONS[params:get("LFO Destination 2")])
    
  elseif page_id == 4 then
    
    draw_tabs({"Fate"}, 1)
    
    -- Dice
    draw_dice()
    
    -- Drift
    screen.move(96, 23)
    screen.text_center("Drift")
    screen.fill()
    draw_dial(params:get("Drift"), 85, 28, 22, true)
    
  end
  
  screen.update()
end
