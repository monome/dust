-- sample based
-- grid controlled
-- step sequencer
-- 
-- key2 = stop sequencer
-- key3 = play sequencer
-- enc2 = tempo
-- enc3 = swing amount
-- 
-- grid = edit trigs
-- last grid row can be 
-- configured for cutting
--

--[[
-- grid+enc2/enc3 lock params
-- grid+key2 clear locks
]]
engine.name = 'Ack'

local ControlSpec = require 'controlspec'
local Control = require 'control'
local Formatters = require 'jah/formatters'
local Grid = require 'grid'

local TRIG_LEVEL = 15
local PLAYPOS_LEVEL = 7
local CLEAR_LEVEL = 0

local tempo_spec = ControlSpec.new(20, 300, ControlSpec.WARP_LIN, 0, 120, "BPM")
local swing_amount_spec = ControlSpec.new(0, 100, ControlSpec.WARP_LIN, 0, 0, "%")

local maxwidth = 16
local height = 8
local playing = false
local queued_playpos
local playpos = -1
local timer
local key3down

local ppqn = 24 
local ticks
local ticks_to_next
local odd_ppqn
local even_ppqn

local trigger_indicators = {}
local grid_available

-- TODO local gridbutton_indicator_level

local locks = {}

local set_lock = function(x, y, value)
  locks[y*maxwidth+x] = value
end

local trig_is_locked = function(x, y)
  return locks[y*maxwidth+x]
end

local get_lock = function(x, y)
  return locks[y*maxwidth+x]
end

local trigs = {}

local set_trig = function(x, y, value)
  trigs[y*maxwidth+x] = value
  if not value then
    set_lock(x, y, nil)
  end
end

local trig_is_set = function(x, y)
  return trigs[y*maxwidth+x]
end

--[[
local held = {}

local get_all_held = function()
  result = {}
  for i, h in ipairs(held) do
    if h then
      result[#result+1] = i
    end
  end
  return result
end

local set_held = function(x, y, value)
  held[y*maxwidth+x] = value
  -- all_held = get_all_held()
  print(#held.." held:")
  for i,h in ipairs(held) do
    local x = i%maxwidth
    local y = i/maxwidth
    print(x, y)
  end
end

local trig_is_held = function(x, y)
  return trigs[y*maxwidth+x]
end

local any_held = function()
  for _, h in ipairs(held) do
    if h then
      return true
    end
  end
  return false
end
]]

local refresh_grid_button = function(x, y, refresh)
  if g then
    if params:get("last row cuts") == 2 and y == 8 then
      if x-1 == playpos then
        g:led(x, y, PLAYPOS_LEVEL)
      else
        g:led(x, y, CLEAR_LEVEL)
      end
    else
      if trig_is_set(x, y) then
        g:led(x, y, TRIG_LEVEL)
      elseif x-1 == playpos then
        g:led(x, y, PLAYPOS_LEVEL)
      else
        g:led(x, y, CLEAR_LEVEL)
      end
    end
    if refresh then
      g:refresh()
    end
  end
end

local refresh_grid_column = function(x, refresh)
  for y=1,height do
    refresh_grid_button(x, y, false)
  end
  if refresh then
    g:refresh()
  end
end

local refresh_grid = function()
  for x=1,maxwidth do
    refresh_grid_column(x, false)
  end
  if g then g:refresh() end
end

local function is_even(number)
  return number % 2 == 0
end

local prev_locks

local function tick()
  ticks = (ticks or -1) + 1

  if (not ticks_to_next) or ticks_to_next == 0 then
    local previous_playpos = playpos
    if queued_playpos then
      playpos = queued_playpos
      queued_playpos = nil
    elseif params:get("grid width") == 1 then
      playpos = (playpos + 1) % 8
    else
      playpos = (playpos + 1) % 16
    end
    local new_prev_locks = {}
    local ts = {}
    for y=1,8 do
      if trig_is_set(playpos+1, y) and not (params:get("last row cuts") == 2 and y == 8) then
        ts[y] = 1
      else
        ts[y] = 0
      end
      if trig_is_locked(playpos+1, y) and not (params:get("last row cuts") == 2 and y == 8) then
        engine.speed(speed_spec:map(get_lock(playpos+1, y)))
        new_prev_locks[y] = true
      else
        if prev_locks and prev_locks[y] then
          engine.speed(params:get(y.."speed"))
        end
      end
    end
    prev_locks = new_prev_locks
    engine.multiTrig(ts[1], ts[2], ts[3], ts[4], ts[5], ts[6], ts[7], ts[8])

    if previous_playpos ~= -1 then
      refresh_grid_column(previous_playpos+1)
    end
    if playpos ~= -1 then
      refresh_grid_column(playpos+1)
    end
    if g then
      g:refresh()
    end
    if is_even(playpos) then
      ticks_to_next = even_ppqn
    else
      ticks_to_next = odd_ppqn
    end
    redraw()
  else
    ticks_to_next = ticks_to_next - 1
  end
end

local function add_ack_params()
  --[[
  TODO: looping
  local loop_start_spec = ControlSpec.UNIPOLAR
  local end_spec = ControlSpec.new(0, 1, 'lin', 0, 1, "")
  local loop_point_spec = ControlSpec.UNIPOLAR
  ]]
  local speed_spec = ControlSpec.new(0.05, 5, 'lin', 0, 1, "")
  -- local slew_spec = ControlSpec.new(0, 5, 'lin', 0, 0, "") -- TODO: enable slews
  local volume_spec = ControlSpec.DB:copy()
  volume_spec.default = -10
  local send_spec = ControlSpec.DB:copy()
  send_spec.default = -60
  local volume_env_attack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
  local volume_env_release_spec = ControlSpec.new(0, 3, 'lin', 0, 3, "secs")
  local filter_env_attack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
  local filter_env_release_spec = ControlSpec.new(0, 3, 'lin', 0, 0.25, "secs")
  local filter_cutoff_spec = ControlSpec.FREQ:copy()
  filter_cutoff_spec.default = 20000
  local filter_res_spec = ControlSpec.UNIPOLAR
  local filter_mode_spec = ControlSpec.new(0, 1, 'lin', 1, 0)
  local filter_env_mod_spec = ControlSpec.UNIPOLAR

  local delay_time_spec = ControlSpec.new(0.0001, 5, 'exp', 0, 0.1, "secs")
  local delay_feedback_spec = ControlSpec.new(0, 1.25, 'lin', 0, 0.5, "")
  local reverb_room_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
  local reverb_damp_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")

  for i=1,8 do
    params:add_file(i..": sample")
    params:set_action(i..": sample", function(value)
      if value ~= "-" then
        engine.loadSample(i-1, value)
      end
    end)
  --[[
  TODO: looping
    params:add_control(i..": start", start_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": start", function(value) engine.start(i-1, value) end)
    params:add_control(i..": end", end_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": end", function(value) engine.end(i-1, value) end)
    params:add_control(i..": loop point", loop_point_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": loop point", function(value) engine.loopPoint(i-1, value) end)
    params:add_option(i..": loop", {"off", "on"})
    params:set_action(i..": loop", function(value) engine.loop(i-1, value) end)
  ]]
    params:add_control(i..": speed", speed_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": speed", function(value) engine.speed(i-1, value) end)
    params:add_control(i..": vol", volume_spec, Formatters.std)
    params:set_action(i..": vol", function(value) engine.volume(i-1, value) end)
    params:add_control(i..": vol env atk", volume_env_attack_spec, Formatters.secs_as_ms)
    params:set_action(i..": vol env atk", function(value) engine.volumeEnvAttack(i-1, value) end)
    params:add_control(i..": vol env rel", volume_env_release_spec, Formatters.secs_as_ms)
    params:set_action(i..": vol env rel", function(value) engine.volumeEnvRelease(i-1, value) end)
    params:add_control(i..": pan", ControlSpec.PAN, Formatters.bipolar_as_pan_widget)
    params:set_action(i..": pan", function(value) engine.pan(i-1, value) end)
    params:add_control(i..": filter cutoff", filter_cutoff_spec, Formatters.round(0.001))
    params:set_action(i..": filter cutoff", function(value) engine.filterCutoff(i-1, value) end)
    params:add_control(i..": filter res", filter_res_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": filter res", function(value) engine.filterRes(i-1, value) end)
    --[[
    params:add_control(i..": filter mode", filter_mode_spec, Formatters.std)
    params:set_action(function(value) engine.filterMode(i-1, value) end)
    ]]
    params:add_control(i..": filter env atk", filter_env_attack_spec, Formatters.secs_as_ms)
    params:set_action(i..": filter env atk", function(value) engine.filterEnvAttack(i-1, value) end)
    params:add_control(i..": filter env rel", filter_env_release_spec, Formatters.secs_as_ms)
    params:set_action(i..": filter env rel", function(value) engine.filterEnvRelease(i-1, value) end)
    params:add_control(i..": filter env mod", filter_env_mod_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": filter env mod", function(value) engine.filterEnvMod(i-1, value) end)
    params:add_control(i..": delay send", send_spec, Formatters.std)
    params:set_action(i..": delay send", function(value) engine.delaySend(i-1, value) end)
    params:add_control(i..": reverb send", send_spec, Formatters.std)
    params:set_action(i..": reverb send", function(value) engine.reverbSend(i-1, value) end)
    --[[
    TODO: enable slews
    params:add_control(i..": speed slew", slew_spec, Formatters.std)
    params:set_action(i..": speed slew", function(value) engine.speedSlew(i-1, value) end)
    params:add_control(i..": vol slew", slew_spec, Formatters.std)
    params:set_action(i..": vol slew", function(value) engine.volumeSlew(i-1, value) end)
    params:add_control(i..": pan slew", slew_spec, Formatters.std)
    params:set_action(i..": pan slew", function(value) engine.panSlew(i-1, value) end)
    params:add_control(i..": filter cutoff slew", slew_spec, Formatters.std)
    params:set_action(i..": filter cutoff slew", function(value) engine.filterCutoffSlew(i-1, value) end)
    params:add_control(i..": filter res slew", slew_spec, Formatters.std)
    params:set_action(i..": filter res slew", function(value) engine.filterResSlew(i-1, value) end)
    ]]
  end

  params:add_control("delay time", delay_time_spec, Formatters.secs_as_ms)
  params:set_action("delay time", engine.delayTime)
  params:add_control("delay feedback", delay_feedback_spec, Formatters.unipolar_as_percentage)
  params:set_action("delay feedback", engine.delayFeedback)
  params:add_control("reverb room", reverb_room_spec, Formatters.unipolar_as_percentage)
  params:set_action("reverb room", engine.reverbRoom)
  params:add_control("reverb damp", reverb_damp_spec, Formatters.unipolar_as_percentage)
  params:set_action("reverb damp", engine.reverbRoom)
end

--[[
local function screen_update_voice_indicators()
  screen.move(0,16)
  screen.font_size(8)
  for channelnum=1,8 do
    if trigger_indicators[channelnum] then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.text(channelnum)
  end
end

local function screen_update_grid_indicator()
  screen.move(0,60)
  screen.font_size(8)
  if grid_available then
    screen.level(15)
    screen.text("grid:")
    screen.text(" ")
    screen.level(gridbutton_indicator_level or 0)
    screen.text(grid_available)
  else
    screen.level(3)
    screen.text("no grid")
  end
end
]]

local function update_metro_time()
  timer.time = 60/params:get("tempo")/ppqn/params:get("beats per pattern")
end

local function update_swing(swing_amount)
  local swing_ppqn = ppqn*swing_amount/100*0.75
  even_ppqn = util.round(ppqn+swing_ppqn)
  odd_ppqn = util.round(ppqn-swing_ppqn)
end

init = function()
  for x=1,maxwidth do
    for y=1,height do
      set_trig(x, y, false)
    end
  end

  timer = metro[1]
  timer.callback = tick

  -- TODO params:add_option("grid brightness", {"mono", "vari"}, 2)
  params:add_option("grid width", {"8", "16"}, 2) -- TODO
  params:set_action("grid width", function(value) update_metro_time() end)
  params:add_option("last row cuts", {"no", "yes"}, 1)
  params:set_action("last row cuts", function(value)
    last_row_cuts = (value == 2)
    refresh_grid()
  end)
  params:add_number("beats per pattern", 1, 8, 4)
  params:set_action("beats per pattern", function(value) update_metro_time() end)
  params:add_control("tempo", tempo_spec)
  params:set_action("tempo", function(bpm) update_metro_time() end)

  update_metro_time()

  params:add_control("swing amount", swing_amount_spec)
  params:set_action("swing amount", update_swing)

  add_ack_params()
  params:bang()

  --[[
  if g then
    g:all(0)
    g:refresh()
  end
  ]]

  playing = true
  timer:start()
end

-- encoder function
enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
  elseif n == 2 then
    params:delta("tempo", delta)
  elseif n == 3 then
    --[[
    if any_held() then
      held = get_all_held()
      for i,h in ipairs(held) do
        local x = i%maxwidth
        local y = i/maxwidth
        print(x, y)
      end
    else
      params:delta("swing amount", delta)
    end
    ]]
    params:delta("swing amount", delta)
  end
  redraw()
end

key = function(n, z)
  if n == 2 and z == 1 then
    if playing == false then
      playpos = -1
      queued_playpos = 0
      redraw()
      refresh_grid()
    else
      playing = false
      timer:stop()
    end
  elseif n == 3 and z == 1 then
    if z == 1 then
      playing = true
      timer:start()
      key3down = true
    else
      key3down = false
    end
  end
  redraw()
end

redraw = function()
  --[[
  screen.clear()
  screen.level(15)
  screen.move(0,8)
  screen.text("step")
  screen.move(0, 24)
  screen.text("tempo: "..params:string("tempo"))
  screen.move(0, 32)
  screen.text("swing: "..params:string("swing amount"))
  screen.move(0, 48)
  if playing then
    screen.text("playing")
    if playpos then
      screen.text(" "..playpos+1)
    end
  else
    screen.text("stopped")
  end
  ]]
  screen.clear()
  screen.level(15)
  screen.move(10,30)
  if playing then
    screen.level(3)
    screen.text("stop")
  else
    screen.level(15)
    screen.text("stopped")
  end
  screen.level(3)
  screen.move(50,30)
  if playing then
    screen.text(" < ")
  else
    screen.text(" > ")
  end
  screen.move(70,30)
  if playing then
    screen.level(15)
    screen.text("playing")
    screen.text(" "..playpos+1)
  else
    screen.level(3)
    screen.text("play")
  end
  screen.level(15)
  screen.move(10,50)
  screen.text(params:string("tempo"))
  screen.move(70,50)
  screen.text(params:string("swing amount"))
  screen.level(3)
  screen.move(10,60)
  screen.text("tempo")
  screen.move(70,60)
  screen.text("swing")

  -- screen_update_voice_indicators()
  -- screen_update_grid_indicator()
  --
  screen.update()
end

gridkey = function(x, y, state)
  -- TODO gridbutton_indicator_level = math.random(15)
  if state == 1 then
    if params:get("last row cuts") == 2 and y == 8 then
      queued_playpos = x-1
    else
      if trig_is_set(x, y) then
        set_trig(x, y, false)
        refresh_grid_button(x, y, true)
      else
        set_trig(x, y, true)
        refresh_grid_button(x, y, true)
      end
    end
    if g then
      g:refresh()
    end
    -- TODO set_held(x, y, true)
  else
    -- TODO set_held(x, y, false)
  end
  redraw()
end

--[[
function Grid.add(grid)
  print("grid added")
  refresh_grid()
  grid_available = grid.serial
  gridbutton_indicator_level = 3
  redraw()
end

function Grid.remove()
  print("grid removed")
  grid_available = nil
  redraw()
end
]]

cleanup = function()
  if g then
    g:all(0)
    g:refresh()
  end
end
