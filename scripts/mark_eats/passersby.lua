-- Passersby
--
-- MIDI controlled West Coast
-- style mono synth.
--
-- ENC1/KEY2 : Change page
-- KEY3 : Change tab
-- ENC2/3 : Adjust parameters
--
-- v1.1.0 Mark Eats
--

local MusicUtil = require "mark_eats/musicutil"
local UI = require "mark_eats/ui"
local Graph = require "mark_eats/graph"
local EnvGraph = require "mark_eats/envgraph"
local Passersby = require "mark_eats/passersby"

local SCREEN_FRAMERATE = 15
local screen_refresh_metro
local screen_dirty = true

local midi_in_device
local active_notes = {}

local pages
local tabs
local tab_titles = {{"Wave", "FM"}, {"Env", "Reverb"}, {"LFO", "Targets"}, {"Fate"}}

local input_indicator_active = false
local wave_table = {}
local wave = {}
local wave_graph
local SUB_SAMPLING = 4
local fm1_dial
local fm2_dial
local env_graph
local env_status = {}
local env_status_metro
local spring_path = {}
local reverb_slider
local lfo_graph
local dice_throw_vel = 0
local dice_throw_progress = 0
local dice_thrown = false
local dice_need_update = false
local dice = {}
local drift_dial

local timbre = 0
local wave_shape = {actual = 0, modu = 0, dirty = true}
local wave_folds = {actual = 0, modu = 0, dirty = true}
local fm1_amount = {actual = 0, modu = 0, dirty = true}
local fm2_amount = {actual = 0, modu = 0, dirty = true}
local attack = {actual = 0, modu = 0, dirty = true}
local peak = {actual = 0, modu = 1, dirty = true}
local decay = {actual = 0, modu = 0, dirty = true}
local reverb_mix = {actual = 0, modu = 0, dirty = true}
local lfo_shape = {dirty = true}
local lfo_freq = {dirty = true}
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
  
  local lfo_shape = params:get("lfo_shape")
  x = x * util.linlin(Passersby.specs.LFO_FREQ.minval, Passersby.specs.LFO_FREQ.maxval, 0.5, 10, params:get("lfo_freq"))
  
  if lfo_shape == 1 then -- Tri
    x = math.abs((x * 2 - 0.5) % 2 - 1) * 2 - 1
  elseif lfo_shape == 2 then -- Ramp
    x = ((x + 0.25) % 1) * 2 - 1
  elseif lfo_shape == 3 then -- Square
    x = math.abs(x * 2 % 2 - 1) - 0.5
    x = x > 0 and 1 or math.floor(x)
  elseif lfo_shape == 4 then -- Random
    local NOISE = {0.7, -0.65, 0.2, 0.9, -0.1, -0.5, 0.7, -0.9, 0.25, 1.0, -0.6, -0.2, 0.6, -0.35, 0.7, 0.1, -0.5, 0.7, 0.2, -0.85, -0.3}
    x = NOISE[util.round(x * 2) + 1]
  end
  
  return x * 0.75
end

local function update_lfo_amounts_list()
  lfo_amounts_list.entries = {
    util.round(params:get("lfo_to_freq_amount") * 100, 1),
    util.round(params:get("lfo_to_wave_shape_amount") * 100, 1),
    util.round(params:get("lfo_to_wave_folds_amount") * 100, 1),
    util.round(params:get("lfo_to_fm_low_amount") * 100, 1),
    util.round(params:get("lfo_to_fm_high_amount") * 100, 1),
    util.round(params:get("lfo_to_attack_amount") * 100, 1),
    util.round(params:get("lfo_to_peak_amount") * 100, 1),
    util.round(params:get("lfo_to_decay_amount") * 100, 1),
    util.round(params:get("lfo_to_reverb_mix_amount") * 100, 1)
  }
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

local function start_env_status_timeout(status_text, x, y)
  env_status.text = status_text
  env_status.x, env_status.y = x, y
  if env_status_metro.is_running then
    env_status_metro:stop()
  end
  env_status_metro:start(1, 1)
end

local function update_tabs()
  
  wave_graph:set_active(tabs.index == 1)
  env_graph:set_active(tabs.index == 1 or params:get("env_type") == 2)
  lfo_graph:set_active(tabs.index == 1)
  
  if tabs.index == 2 then env_status.text = "" end
  lfo_destinations_list.active = tabs.index == 2
  lfo_amounts_list.active = tabs.index == 2
  fm1_dial.active = tabs.index == 2
  fm2_dial.active = tabs.index == 2
  
  screen_dirty = true
end

local function update_pages()
  tabs:set_index(1)
  tabs.titles = tab_titles[pages.index]
  env_status.text = ""
  lfo_destinations_list:set_index(1)
  lfo_amounts_list:set_index(1)
  update_tabs()
end

local function init_env_graph(env_type)
  if env_type == 1 then
    env_graph = EnvGraph.new_ar(0, 1, 0, 1, 0.003, util.explin(Passersby.specs.DECAY.minval * 0.5, Passersby.specs.DECAY.maxval, 0, 1, decay.actual), util.explin(Passersby.specs.PEAK.minval * 0.5, Passersby.specs.PEAK.maxval, 0, 1, peak.actual), -4)
  else
    env_graph = EnvGraph.new_asr(0, 1, 0, 1, util.explin(Passersby.specs.ATTACK.minval, Passersby.specs.ATTACK.maxval, 0, 0.4, attack.actual), util.explin(Passersby.specs.DECAY.minval, Passersby.specs.DECAY.maxval, 0, 0.4, decay.actual), 1, -4)
  end
  env_graph:set_position_and_size(8, 22, 49, 36)
  env_graph:set_show_x_axis(true)
end


-- Engine functions

local function note_on(note_num, vel)
  engine.noteOn(note_num, MusicUtil.note_num_to_freq(note_num), vel)
  table.insert(active_notes, note_num)
  input_indicator_active = true
  screen_dirty = true
end

local function note_off(note_num)
  engine.noteOff(note_num)
  for i = #active_notes, 1, -1 do
    if active_notes[i] == note_num then
      table.remove(active_notes, i)
    end
  end
  if #active_notes == 0 then
    input_indicator_active = false
    screen_dirty = true
  end
end

local function set_pitch_bend(bend_st)
  engine.pitchBendAll(MusicUtil.interval_to_ratio(bend_st))
end

local function set_channel_pressure(pressure)
  engine.pressureAll(pressure)
end

local function set_channel_timbre(value)
  engine.timbreAll(value)
  timbre = value * 0.5
  wave_folds.dirty = true
end

-- Updaters

local function update_wave_shape()
  wave_shape.actual = util.clamp(params:get("wave_shape") + wave_shape.modu, Passersby.specs.WAVE_SHAPE.minval, Passersby.specs.WAVE_SHAPE.maxval)
  wave_graph:update_functions()
  wave_shape.dirty = false
  screen_dirty = true
end

local function update_wave_folds()
  wave_folds.actual = util.clamp(params:get("wave_folds") + timbre + wave_folds.modu, Passersby.specs.WAVE_FOLDS.minval, Passersby.specs.WAVE_FOLDS.maxval + 0.5)
  wave_graph:update_functions()
  wave_folds.dirty = false
  screen_dirty = true
end

local function update_fm1_amount()
  fm1_amount.actual = util.clamp(params:get("fm_low_amount") + fm1_amount.modu, Passersby.specs.FM_LOW_AMOUNT.minval, Passersby.specs.FM_LOW_AMOUNT.maxval)
  fm1_dial.value = fm1_amount.actual * 100
  fm1_amount.dirty = false
  screen_dirty = true
end

local function update_fm2_amount()
  fm2_amount.actual = util.clamp(params:get("fm_high_amount") + fm2_amount.modu, Passersby.specs.FM_HIGH_AMOUNT.minval, Passersby.specs.FM_HIGH_AMOUNT.maxval)
  fm2_dial.value = fm2_amount.actual * 100
  fm2_amount.dirty = false
  screen_dirty = true
end

local function update_attack()
  attack.actual = util.clamp(params:get("attack") + attack.modu, Passersby.specs.ATTACK.minval, Passersby.specs.ATTACK.maxval)
  if params:get("env_type") == 2 then
    local norm_attack = util.explin(Passersby.specs.ATTACK.minval, Passersby.specs.ATTACK.maxval, 0, 0.4, attack.actual)
    env_graph:edit_asr(norm_attack)
  end
  attack.dirty = false
  screen_dirty = true
end

local function show_attack_status()
  if params:get("env_type") == 2 then
    local norm_attack = util.explin(Passersby.specs.ATTACK.minval, Passersby.specs.ATTACK.maxval, 0, 0.4, params:get("attack") + attack.modu)
    local norm_peak = util.explin(Passersby.specs.PEAK.minval * 0.5, Passersby.specs.PEAK.maxval, 0, 1, params:get("peak") * peak.modu)
    local y
    if norm_peak > 0.6 then y = 46 else y = util.linlin(0, 1, 52, 18, norm_peak) end
    start_env_status_timeout(params:string("attack"), 38, y)
    screen_dirty = true
  end
end

local function update_peak()
  peak.actual = util.clamp(params:get("peak") * peak.modu, Passersby.specs.PEAK.minval, Passersby.specs.PEAK.maxval)
  local norm_peak = util.explin(Passersby.specs.PEAK.minval * 0.5, Passersby.specs.PEAK.maxval, 0, 1, peak.actual)
  if params:get("env_type") == 1 then
    env_graph:edit_ar(nil, nil, norm_peak)
  else
    env_graph:edit_asr(nil, nil, norm_peak)
  end
  peak.dirty = false
  screen_dirty = true
end

local function show_peak_status()
  local norm_peak = util.explin(Passersby.specs.PEAK.minval * 0.5, Passersby.specs.PEAK.maxval, 0, 1, params:get("peak") * peak.modu)
  if params:get("env_type") == 1 then
    start_env_status_timeout(params:string("peak"), 57, util.linlin(0, 1, 56, 26, norm_peak))
  else
    start_env_status_timeout(params:string("peak"), 45, util.linlin(0, 1, 52, 18, norm_peak))
  end
  screen_dirty = true
end

local function update_decay()
  decay.actual = util.clamp(params:get("decay") + decay.modu, Passersby.specs.DECAY.minval, Passersby.specs.DECAY.maxval)
  if params:get("env_type") == 1 then
    local norm_decay = util.explin(Passersby.specs.DECAY.minval * 0.5, Passersby.specs.DECAY.maxval, 0, 1, decay.actual)
    env_graph:edit_ar(nil, norm_decay)
  else
    local norm_decay = util.explin(Passersby.specs.DECAY.minval, Passersby.specs.DECAY.maxval, 0, 0.4, decay.actual)
    env_graph:edit_asr(nil, norm_decay)
  end
  decay.dirty = false
  screen_dirty = true
end

local function show_decay_status()
  local norm_decay
  if params:get("env_type") == 1 then
    norm_decay = util.explin(Passersby.specs.DECAY.minval * 0.5, Passersby.specs.DECAY.maxval, 0, 0.4, params:get("decay") + decay.modu)
    start_env_status_timeout(params:string("decay"), util.linlin(0, 1, 38, 80, norm_decay), 48)
  else
    norm_decay = util.explin(Passersby.specs.DECAY.minval, Passersby.specs.DECAY.maxval, 0.4, 0, params:get("decay") + decay.modu)
    local norm_peak = util.explin(Passersby.specs.PEAK.minval * 0.5, Passersby.specs.PEAK.maxval, 0, 1, params:get("peak") * peak.modu)
    local y
    if norm_peak > 0.6 then y = 53 else y = util.linlin(0, 1, 52, 18, norm_peak) end
    start_env_status_timeout(params:string("decay"), util.linlin(0, 1, 39, 74, norm_decay), y)
  end
  screen_dirty = true
end

local function update_reverb_mix()
  reverb_mix.actual = util.clamp(params:get("reverb_mix") + reverb_mix.modu, Passersby.specs.REVERB_MIX.minval, Passersby.specs.REVERB_MIX.maxval)
  reverb_slider.value = reverb_mix.actual
  reverb_mix.dirty = false
  screen_dirty = true
end


local function update_lfo_shape()
  lfo_graph:update_functions()
  lfo_shape.dirty = false
  screen_dirty = true
end

local function update_lfo_freq()
  lfo_graph:update_functions()
  lfo_freq.dirty = false
  screen_dirty = true
end

local function update_lfo_destinations()
  update_lfo_amounts_list()
  lfo_destinations.dirty = false
  screen_dirty = true
end

local function update_drift()
  drift_dial.value = params:get("drift") * 100
  drift.dirty = false
  screen_dirty = true
end


-- Input functions

-- Encoder input
function enc(n, delta)
  
  if n == 1 then
    -- Page scroll
    pages:set_index_delta(util.clamp(delta, -1, 1), false)
    update_pages()
  end
  
  if pages.index == 1 then
    
      if tabs.index == 1 then
        -- Wave
        if n == 2 then
          params:delta("wave_shape", delta)
        elseif n == 3 then
          params:delta("wave_folds", delta)
        end
        
      else
        -- FM
        if n == 2 then
          params:delta("fm_low_amount", delta)
        elseif n == 3 then
          params:delta("fm_high_amount", delta)
        end
      end
      
  elseif pages.index == 2 then
    
      if tabs.index == 1 then
        -- LPG
        if n == 2 then
          if params:get("env_type") == 1 then
            params:delta("peak", delta)
          else
            params:delta("attack", delta)
          end
        elseif n == 3 then
          if params:get("env_type") == 1 then
            params:delta("decay", delta)
          else
            params:delta("decay", -delta)
          end
        end
        
      else
        -- Peak
        if n == 2 and params:get("env_type") == 2 then
          params:delta("peak", delta)
        -- Reverb
        elseif n == 3 then
          params:delta("reverb_mix", delta)
        end
      end
      
  elseif pages.index == 3 then
    
    if tabs.index == 1 then
      -- LFO
      if n == 2 then
        params:delta("lfo_shape", util.clamp(delta, -1, 1))
      elseif n == 3 then
        params:delta("lfo_freq", delta)
      end
    
    else
      -- LFO scroll lists
      if n == 2 then
        lfo_destinations_list:set_index_delta(util.clamp(delta, -1, 1), false)
        lfo_amounts_list:set_index(lfo_destinations_list.index)
        screen_dirty = true
        
      -- LFO amounts
      elseif n == 3 then
        if lfo_destinations_list.index == 1 then
          params:delta("lfo_to_freq_amount", delta)
        elseif lfo_destinations_list.index == 2 then
          params:delta("lfo_to_wave_shape_amount", delta)
        elseif lfo_destinations_list.index == 3 then
          params:delta("lfo_to_wave_folds_amount", delta)
        elseif lfo_destinations_list.index == 4 then
          params:delta("lfo_to_fm_low_amount", delta)
        elseif lfo_destinations_list.index == 5 then
          params:delta("lfo_to_fm_high_amount", delta)
        elseif lfo_destinations_list.index == 6 then
          params:delta("lfo_to_attack_amount", delta)
        elseif lfo_destinations_list.index == 7 then
          params:delta("lfo_to_peak_amount", delta)
        elseif lfo_destinations_list.index == 8 then
          params:delta("lfo_to_decay_amount", delta)
        elseif lfo_destinations_list.index == 9 then
          params:delta("lfo_to_reverb_mix_amount", delta)
        end
      end
      
    end
      
  elseif pages.index == 4 then
    
    -- Randomize
    if n == 2 then
      if not dice_thrown then set_dice_throw_vel(delta * 0.05) end
      
    -- Drift
    elseif n == 3 then
      params:delta("drift", delta)
    end
    
  end
end

-- Key input
function key(n, z)
  if z == 1 then
    
    if n == 2 then
      pages:set_index_delta(1, true)
      update_pages()
      
    elseif n == 3 then
      tabs:set_index_delta(1, true)
      update_tabs()
      
    end
  end
end

-- MIDI input
local function midi_event(data)
  
  if #data == 0 then return end
  
  local msg = midi.to_msg(data)
  local channel_param = params:get("midi_channel")
  
  if channel_param == 1 or (channel_param > 1 and msg.ch == channel_param - 1) then
    
    -- Note on
    if msg.type == "note_on" then
      note_on(msg.note, msg.vel / 127)
      
    -- Note off
    elseif msg.type == "note_off" then
      note_off(msg.note)
      
    -- Pitch bend
    elseif msg.type == "pitchbend" then
      local bend_st = (util.round(msg.val / 2)) / 8192 * 2 -1 -- Convert to -1 to 1
      set_pitch_bend(bend_st * params:get("bend_range"))
      
    -- Pressure
    elseif msg.type == "channel_pressure" or msg.type == "key_pressure" then
      set_channel_pressure(msg.val / 127)
      
    end
  end
end


-- Init

function init()
  
  screen.aa(1)
  
  midi_in_device = midi.connect(1)
  midi_in_device.event = midi_event
  
  -- Add params
  
  params:add{type = "number", id = "midi_device", name = "MIDI Device", min = 1, max = 4, default = 1, action = function(value)
    midi_in_device:reconnect(value)
  end}
  
  local channels = {"All"}
  for i = 1, 16 do table.insert(channels, i) end
  params:add{type = "option", id = "midi_channel", name = "MIDI Channel", options = channels}
  
  params:add{type = "number", id = "bend_range", name = "Pitch Bend Range", min = 1, max = 48, default = 2}
  
  params:add_separator()
  
  Passersby.add_params()
  
  -- Override param actions
  
  params:set_action("wave_shape", function(value)
    engine.waveShape(value)
    wave_shape.dirty = true
  end)
  
  params:set_action("wave_folds", function(value)
    engine.waveFolds(value)
    wave_folds.dirty = true
  end)
  
  params:set_action("fm_low_amount", function(value)
    engine.fm1Amount(value)
    fm1_amount.dirty = true
  end)
  
  params:set_action("fm_high_amount", function(value)
    engine.fm2Amount(value)
    fm2_amount.dirty = true
  end)
  
  params:set_action("env_type", function(value)
    engine.envType(value - 1)
    init_env_graph(value)
    tab_titles[2][1] = params:string("env_type")
    if value == 1 then
      tab_titles[2][2] = "Reverb"
    else
      tab_titles[2][2] = "Peak/Reverb"
    end
    if pages.index == 2 then
      tabs.titles = tab_titles[2]
      update_tabs()
      screen_dirty = true
    end
  end)
  
  params:set_action("attack", function(value)
    engine.attack(value)
    if pages.index == 2 then show_attack_status() end
    attack.dirty = true
  end)
  
  params:set_action("peak", function(value)
    engine.peak(value)
    if pages.index == 2 then show_peak_status() end
    peak.dirty = true
  end)
  
  params:set_action("decay", function(value)
    engine.decay(value)
    if pages.index == 2 then show_decay_status() end
    decay.dirty = true
  end)
  
  params:set_action("reverb_mix", function(value)
    engine.reverbMix(value)
    reverb_mix.dirty = true
  end)
  
  params:set_action("lfo_shape", function(value)
    engine.lfoShape(value - 1)
    lfo_shape.dirty = true
  end)
  
  params:set_action("lfo_freq", function(value)
    engine.lfoFreq(value)
    lfo_freq.dirty = true
  end)
  
  params:set_action("lfo_to_freq_amount", function(value)
    engine.lfoToFreqAmount(value)
    lfo_destinations.dirty = true
  end)
  
  params:set_action("lfo_to_wave_shape_amount", function(value)
    engine.lfoToWaveShapeAmount(value)
    lfo_destinations.dirty = true
  end)
  
  params:set_action("lfo_to_wave_folds_amount", function(value)
    engine.lfoToWaveFoldsAmount(value)
    lfo_destinations.dirty = true
  end)
  
  params:set_action("lfo_to_fm_low_amount", function(value)
    engine.lfoToFm1Amount(value)
    lfo_destinations.dirty = true
  end)
  
  params:set_action("lfo_to_fm_high_amount", function(value)
    engine.lfoToFm2Amount(value)
    lfo_destinations.dirty = true
  end)
  
  params:set_action("lfo_to_attack_amount", function(value)
    engine.lfoToAttackAmount(value)
    lfo_destinations.dirty = true
  end)
  
  params:set_action("lfo_to_peak_amount", function(value)
    engine.lfoToPeakAmount(value)
    lfo_destinations.dirty = true
  end)
  
  params:set_action("lfo_to_decay_amount", function(value)
    engine.lfoToDecayAmount(value)
    lfo_destinations.dirty = true
  end)
  
  params:set_action("lfo_to_reverb_mix_amount", function(value)
    engine.lfoToReverbMixAmount(value)
    lfo_destinations.dirty = true
  end)
  
  params:set_action("drift", function(value)
    engine.drift(value)
    drift.dirty = true
  end)
  
  wave_shape.actual = params:get("wave_shape")
  wave_folds.actual = params:get("wave_folds")
  fm1_amount.actual = params:get("fm_low_amount")
  fm2_amount.actual = params:get("fm_high_amount")
  attack.actual = params:get("attack")
  peak.actual = params:get("peak")
  decay.actual = params:get("decay")
  reverb_mix.actual = params:get("reverb_mix")
  
  -- Init UI
  
  pages = UI.Pages.new(1, 4)
  tab_titles[2][1] = params:string("env_type")
  tabs = UI.Tabs.new(1, tab_titles[pages.index])
  
  fm1_dial = UI.Dial.new(72, 19, 22, fm1_amount.actual * 100, 0, 100, 1)
  fm2_dial = UI.Dial.new(97, 34, 22, fm2_amount.actual * 100, 0, 100, 1)
  
  reverb_slider = UI.Slider.new(102, 22, 3, 36, reverb_mix.actual, 0, 1, {0.5})
  
  lfo_destinations_list = UI.ScrollingList.new(71, 18, 1, {"Freq", "Shape", "Folds", "FM Low", "FM High", "Attack", "Peak", "Decay", "Reverb"})
  lfo_destinations_list.num_visible = 4
  lfo_destinations_list.num_above_selected = 0
  lfo_destinations_list.active = false
  
  lfo_amounts_list = UI.ScrollingList.new(120, 18)
  lfo_amounts_list.num_visible = 4
  lfo_amounts_list.num_above_selected = 0
  lfo_amounts_list.text_align = "right"
  lfo_amounts_list.active = false
  update_lfo_amounts_list()
  
  drift_dial = UI.Dial.new(85, 28, 22, params:get("drift") * 100, 0, 100, 1)

  -- Init graphs
  
  wave_graph = Graph.new(0, 2, "lin", -1, 1, "lin", nil, true, false)
  wave_graph:set_position_and_size(8, 22, 49, 36)
  wave_table = generate_wave_table(2, wave_graph:get_width() * SUB_SAMPLING)
  local wave_func = function(x)
    return generate_wave(util.linlin(0, 2, 1, wave_graph:get_width() * SUB_SAMPLING, x))
  end
  wave_graph:add_function(wave_func, SUB_SAMPLING)
  
  init_env_graph(params:get("env_type"))
  
  lfo_graph = Graph.new(0, 1, "lin", -1, 1, "lin", nil, true, false)
  lfo_graph:set_position_and_size(8, 18, 49, 36)
  lfo_graph:add_function(generate_lfo_wave, SUB_SAMPLING)
  
  env_status.text = ""
  env_status.x, env_status.y = 0, 0
  env_status_metro = metro.alloc()
  env_status_metro.callback = function()
    env_status.text = ""
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
  
  local attack_poll = poll.set("attackMod", function(value)
    if attack.modu ~= value then
      attack.modu = value
      attack.dirty = true
    end
  end)
  attack_poll:start()
  
  local peak_poll = poll.set("peakMulMod", function(value)
    if peak.modu ~= value then
      peak.modu = value
      peak.dirty = true
    end
  end)
  peak_poll:start()
  
  local decay_poll = poll.set("decayMod", function(value)
    if decay.modu ~= value then
      decay.modu = value
      decay.dirty = true
    end
  end)
  decay_poll:start()
  
  local reverb_mix_poll = poll.set("reverbMixMod", function(value)
    if reverb_mix.modu ~= value then
      reverb_mix.modu = value
      reverb_mix.dirty = true
    end
  end)
  reverb_mix_poll:start()
  
  -- Start drawing to screen
  screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function()
    update()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  
end


-- Draw functions

local function rotate(x, y, center_x, center_y, angle_rads)
  local sin_a = math.sin(angle_rads)
  local cos_a = math.cos(angle_rads)
  x = x - center_x
  y = y - center_y
  return (x * cos_a - y * sin_a) + center_x, (x * sin_a + y * cos_a) + center_y
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
  
  if pages.index == 4 then screen_dirty = true end
  if dice_throw_progress == 0 and not dice_thrown then dice_need_update = false end
end

function update()
  
  if pages.index == 1 then
    if wave_shape.dirty then update_wave_shape() end
    if wave_folds.dirty then update_wave_folds() end
    if fm1_amount.dirty then update_fm1_amount() end
    if fm2_amount.dirty then update_fm2_amount() end
  elseif pages.index == 2 then
    if attack.dirty then update_attack() end
    if peak.dirty then update_peak() end
    if decay.dirty then update_decay() end
    if reverb_mix.dirty then update_reverb_mix() end
  elseif pages.index == 3 then
    if lfo_shape.dirty then update_lfo_shape() end
    if lfo_freq.dirty then update_lfo_freq() end
    if lfo_destinations.dirty then update_lfo_destinations() end
  elseif pages.index == 4 then
    if drift.dirty then update_drift() end
  end
  
  update_dice()
end

function redraw()
  screen.clear()
  
  pages:redraw()
  tabs:redraw()
  
  if input_indicator_active then draw_input_indicator() end
  
  -- draw_background_rects()
  
  if pages.index == 1 then
    
    -- Wave
    wave_graph:redraw()
    
    -- FM
    fm1_dial:redraw()
    fm2_dial:redraw()
    screen.level(3)
    screen.move(83, 33)
    screen.text_center("L")
    screen.move(108, 48)
    screen.text_center("H")
    screen.fill() -- Prevents extra line
    
  elseif pages.index == 2 then
    
    -- Env
    env_graph:redraw()
    screen.level(3)
    screen.move(env_status.x, env_status.y)
    screen.text_right(env_status.text)
    
    -- Reverb
    screen.fill()
    draw_spring(82, 22, tabs.index == 2)
    reverb_slider:redraw()
    
  elseif pages.index == 3 then
    
    -- LFO
    lfo_graph:redraw()
    screen.level(3)
    screen.move(8, 62)
    screen.text(params:string("lfo_freq"))
    
    -- LFO Targets
    if tabs.index == 2 then screen.level(15) else screen.level(3) end
    lfo_destinations_list:redraw()
    lfo_amounts_list:redraw()
    
  elseif pages.index == 4 then
    
    -- Dice
    draw_dice()
    
    -- Drift
    screen.move(96, 23)
    screen.text_center("Drift")
    screen.fill()
    drift_dial:redraw()
    
  end
  
  screen.update()
end
