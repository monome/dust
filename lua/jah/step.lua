-- sample based grid step
-- sequencer
-- 
-- transport:
-- key2 = stop sequencer
-- key3 = play sequencer
-- key3+grid to cut position
-- enc2 = tempo
-- enc3 = swing amount (TODO)
-- 
-- editing:
-- grid edit trigs
-- grid+enc2/enc3 lock params
-- grid+key2 clear locks

engine.name = 'Ack'

local ControlSpec = require 'controlspec'
local Control = require 'control'
local Formatters = require 'jah/formatters'
local FS = require 'fileselect'

local TRIG_LEVEL = 15
local PLAYPOS_LEVEL = 7
local CLEAR_LEVEL = 0

local tempo_spec = ControlSpec.new(20, 300, ControlSpec.WARP_LIN, 0, 120, "BPM")
local swing_amount_spec = ControlSpec.new(0, 100, ControlSpec.WARP_LIN, 0, 0, "%")

local maxwidth = 16
local height = 8
local playing = false
local playpos
local t

local trigs = {}

local set_trig = function(x, y, value)
  trigs[y*maxwidth+x] = value
end

local trig_is_set = function(x, y)
  return trigs[y*maxwidth+x]
end

local refresh_grid_button = function(x, y)
  if g then
    if trig_is_set(x, y) then
      g:led(x, y, TRIG_LEVEL)
    elseif x-1 == playpos then
      g:led(x, y, PLAYPOS_LEVEL)
    else
      g:led(x, y, CLEAR_LEVEL)
    end
    g:refresh()
  end
end

local refresh_grid_column = function(x)
  for y=1,height do
    refresh_grid_button(x, y)
  end
end

local tick = function()
  if restart_timer then
    restart_timer = false
    t:stop()
    t:start()
  end
  local previous_playpos = playpos
  if not playpos then
    playpos = 0
  elseif params:get("num steps") == 1 then
    playpos = (playpos + 1) % 8
  else
    playpos = (playpos + 1) % 16
  end
  for y=1,8 do
    if trig_is_set(playpos+1, y) then
      engine.trig(y-1)
    end
  end
  if previous_playpos then
    refresh_grid_column(previous_playpos+1)
  end
  if playpos then
    refresh_grid_column(playpos+1)
  end
  if g then
    g:refresh()
  end
  redraw()
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
  local delay_feedback_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
  local reverb_room_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
  local reverb_damp_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")

  for i=1,8 do
    params:add_file(i..": sample", "/home/pi/dust/audio/")
    params:set_file(i..": sample", function(value)
      engine.loadSample(i-1, value)
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

init = function()
  for x=1,maxwidth do
    for y=1,height do
      set_trig(x, y, false)
    end
  end

  if g then
    g:all(0)
    g:refresh()
  end

  t = metro[1]
  t.callback = tick
  playing = false

  params:add_control("tempo", tempo_spec)
  params:set_action("tempo", function(n) 
    t.time = 15/n
    restart_timer = true
  end)

  t.time = 15/params:get("tempo") 

  params:add_control("swing amount", swing_amount_spec)
  params:add_option("num steps", {"8", "16"}, 2)

  add_ack_params()
  params:bang()

  local sampleroot = "/home/pi/dust/audio/hello_ack/"
  engine.loadSample(0, sampleroot.."XR-20_003.wav")
  engine.loadSample(1, sampleroot.."XR-20_114.wav")
  engine.loadSample(2, sampleroot.."XR-20_285.wav")
  engine.loadSample(3, sampleroot.."XR-20_328.wav")
  engine.loadSample(4, sampleroot.."XR-20_121.wav")
  engine.loadSample(5, sampleroot.."XR-20_667.wav")
  engine.loadSample(6, sampleroot.."XR-20_128.wav")
  engine.loadSample(7, sampleroot.."XR-20_718.wav")
end

-- encoder function
enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
  elseif n == 2 then
    params:delta("tempo", delta)
  elseif n == 3 then
    params:delta("swing amount", delta)
  end
  redraw()
end

local function newfile(what)
  if what ~= "cancel" then
    engine.loadSample(fileselect_channel-1, what)
  end
end

key = function(n, z)
  if n == 2 and z == 1 then
    playing = false
    t:stop()
  elseif n == 3 and z == 1 then
    playing = true
    t:start()
  elseif n==1 and z==1 and fileselect_channel then
    FS.enter("/home/pi/dust/audio", newfile)
  end
  redraw()
end

redraw = function()
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
  screen.update()
end

gridkey = function(x, y, state)
  if state == 1 then
    if trig_is_set(x, y) then
      set_trig(x, y, false)
      refresh_grid_button(x, y)
    else
      set_trig(x, y, true)
      refresh_grid_button(x, y)
    end
    if g then
      g:refresh()
    end
    fileselect_channel = y -- TODO: register keydowns in a table
  else
    fileselect_channel = nil -- TODO: register keydowns in a table
  end
end

cleanup = function()
  if g then
    g:all(0)
    g:refresh()
  end
end
