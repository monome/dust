-- @name param ack
-- @version 0.1.0
-- @author jah
-- @txt ack params test

ControlSpec = require 'controlspec'
Control = require 'control'
Scroll = require 'jah/scroll'
Formatters = require 'jah/formatters'

engine.name = 'Ack'

local debug = false

local bool_spec = ControlSpec.new(0, 1, 'lin', 1, 0, "")

--[[
TODO: looping
local loop_start_spec = ControlSpec.unipolar()
local loop_end_spec = ControlSpec.new(0, 1, 'lin', 0, 1, "")
]]
local speed_spec = ControlSpec.new(0, 5, 'lin', 0, 1, "")
-- local slew_spec = ControlSpec.new(0, 5, 'lin', 0, 0, "") -- TODO: enable slews
local volume_spec = ControlSpec.db()
volume_spec.default = -10
local send_spec = ControlSpec.db()
send_spec.default = -60
local volume_env_attack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
local volume_env_release_spec = ControlSpec.new(0, 3, 'lin', 0, 3, "secs")
local filter_env_attack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
local filter_env_release_spec = ControlSpec.new(0, 3, 'lin', 0, 0.25, "secs")
local filter_cutoff_spec = ControlSpec.freq()
filter_cutoff_spec.default = 20000
local filter_res_spec = ControlSpec.unipolar()
local filter_mode_spec = ControlSpec.new(0, 1, 'lin', 1, 0)
local filter_env_mod_spec = ControlSpec.unipolar()

local delay_time_spec = ControlSpec.new(0.0001, 5, 'exp', 0, 0.1, "secs")
-- local delay_feedback_spec = ControlSpec.unipolar() -- TODO feedback should be 0-1 displayed as %
local reverb_room_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
local reverb_damp_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")

local midi_in = Control.new("midi in", bool_spec, Formatters.unipolar_as_enabled_disabled)
midi_in:set(1) -- TODO: hack, better idea: encoder deltas configured per param or set_min_mapped_value()/set_max_mapped_value()

local midi_selects = Control.new("midi selects", bool_spec, Formatters.unipolar_as_true_false)
midi_selects:set(0.98) -- TODO: hack, better idea: encoder deltas configured per param or set_min_mapped_value()/set_max_mapped_value()

local trig_on_change = Control.new("trig on value change", bool_spec, Formatters.unipolar_as_true_false)
trig_on_change:set_raw(0.98) -- TODO: hack, better idea: encoder deltas configured per param or set_min_mapped_value()/set_max_mapped_value()

local channel_params = {}
for i=0,7 do
  local p = {}
  --[[
  TODO: looping
  p.loop_start = Control.new((i+1)..": loop start", loop_start_spec, Formatters.unipolar_as_percentage)
  p.loop_start.action = function(value) engine.loopStart(i, value) end
  p.loop_end = Control.new((i+1)..": loop end", loop_end_spec, Formatters.unipolar_as_percentage)
  p.loop_end.action = function(value) engine.loopEnd(i, value) end
  ]]
  p.speed = Control.new((i+1)..": speed", speed_spec, Formatters.unipolar_as_percentage)
  p.speed.action = function(value) engine.speed(i, value) end
  p.volume = Control.new((i+1)..": vol", volume_spec, Formatters.std)
  p.volume.action = function(value) engine.volume(i, value) end
  p.volume_env_attack = Control.new((i+1)..": vol env atk", volume_env_attack_spec, Formatters.secs_as_ms)
  p.volume_env_attack.action = function(value) engine.volumeEnvAttack(i, value) end
  p.volume_env_release = Control.new((i+1)..": vol env rel", volume_env_release_spec, Formatters.secs_as_ms)
  p.volume_env_release.action = function(value) engine.volumeEnvRelease(i, value) end
  p.pan = Control.new((i+1)..": pan", ControlSpec.pan(), Formatters.bipolar_as_pan_widget)
  p.pan.action = function(value) engine.pan(i, value) end
  p.filter_cutoff = Control.new((i+1)..": filter cutoff", filter_cutoff_spec, Formatters.round(0.001))
  p.filter_cutoff.action = function(value) engine.filterCutoff(i, value) end
  p.filter_res = Control.new((i+1)..": filter res", filter_res_spec, Formatters.unipolar_as_percentage)
  p.filter_res.action = function(value) engine.filterRes(i, value) end
  --[[
  p.filter_mode = Control.new((i+1)..": filter mode", filter_mode_spec, Formatters.std)
  p.filter_mode.action = function(value) engine.filterMode(i, value) end
  ]]
  p.filter_env_attack = Control.new((i+1)..": filter env atk", filter_env_attack_spec, Formatters.secs_as_ms)
  p.filter_env_attack.action = function(value) engine.filterEnvAttack(i, value) end
  p.filter_env_release = Control.new((i+1)..": filter env rel", filter_env_release_spec, Formatters.secs_as_ms)
  p.filter_env_release.action = function(value) engine.filterEnvRelease(i, value) end
  p.filter_env_mod = Control.new((i+1)..": filter env mod", filter_env_mod_spec, Formatters.unipolar_as_percentage)
  p.filter_env_mod.action = function(value) engine.filterEnvMod(i, value) end
  p.delay_send = Control.new((i+1)..": delay send", send_spec, Formatters.std)
  p.delay_send.action = function(value) engine.delaySend(i, value) end
  p.reverb_send = Control.new((i+1)..": reverb send", send_spec, Formatters.std)
  p.reverb_send.action = function(value) engine.reverbSend(i, value) end
  --[[
  TODO: enable slews
  p.speed_slew = Control.new((i+1)..": speed slew", slew_spec, Formatters.std)
  p.speed_slew.action = function(value) engine.speedSlew(i, value) end
  p.volume_slew = Control.new((i+1)..": vol slew", slew_spec, Formatters.std)
  p.volume_slew.action = function(value) engine.volumeSlew(i, value) end
  p.pan_slew = Control.new((i+1)..": pan slew", slew_spec, Formatters.std)
  p.pan_slew.action = function(value) engine.panSlew(i, value) end
  p.filter_cutoff_slew = Control.new((i+1)..": filter cutoff slew", slew_spec, Formatters.std)
  p.filter_cutoff_slew.action = function(value) engine.filterCutoffSlew(i, value) end
  p.filter_res_slew = Control.new((i+1)..": filter res slew", slew_spec, Formatters.std)
  p.filter_res_slew.action = function(value) engine.filterResSlew(i, value) end
  ]]
  channel_params[i] = p
end

local delay_time = Control.new("delay time", delay_time_spec, Formatters.secs_as_ms)
delay_time.action = function(value) engine.delayTimeL(value) end
-- local delay_time_r = Control.new("delay time r", delay_time_spec, Formatters.std) TODO
-- delay_time_r.action = function(value) engine.delayTimeR(value) end TODO
local delay_feedback = Control.new("delay feedback", delay_time_spec, Formatters.secs_as_ms)
delay_feedback:set(0.75)
delay_feedback.action = function(value) engine.delayFeedback(value) end
local reverb_room = Control.new("reverb room", reverb_room_spec, Formatters.unipolar_as_percentage)
reverb_room.action = function(value) engine.reverbRoom(value) end
local reverb_damp = Control.new("reverb damp", reverb_damp_spec, Formatters.unipolar_as_percentage)
reverb_damp.action = function(value) engine.reverbDamp(value) end

local function debug_print(str)
  if debug then print(str) end
end

local function get_channel_from_string(string) -- TODO
  -- TODO: ugly hack code- change so that this is not a for loop, as we're only interested in first match
  words = {}
  for word in string:gmatch("([0-9]+):") do -- TODO: why doesn't "^([0-9]+):" work here?
    table.insert(words, word)
  end
  return tonumber(words[1])
end

local function note_on(note, velocity)
  debug_print("midi / note_on: "..note..", velocity: "..velocity) -- TODO: replace this with on-screen notification
  local channel = nil
  if note == 60 then
    channel = 0
  elseif note == 62 then
    channel = 1
  elseif note == 64 then
    channel = 2
  elseif note == 65 then
    channel = 3
  elseif note == 67 then
    channel = 4
  elseif note == 69 then
    channel = 5
  elseif note == 71 then
    channel = 6
  elseif note == 72 then
    channel = 7
  end
  if channel then
    debug_print("midi / channel: "..channel)
    engine.trig(channel)
    if midi_selects:get() == 1 then
      local selected_param = scroll.selected_param

      if selected_param == nil or get_channel_from_string(selected_param.name) ~= channel+1 then -- TODO: make this the proper way
        scroll:navigate_to_lineno(scroll:lookup_lineno(channel_params[channel].speed))
        redraw()
      end
    end
  end
end

local function note_off(note)
  debug_print("midi / note_off: "..note)
end

local function cc(control, value)
  debug_print("midi / control: "..control..", value: "..value)
end

init = function()
  screen.aa(1)
  screen.line_width(1.0)

  for channelnum=0,7 do
    for key, param in pairs(channel_params[channelnum]) do param:bang() end
  end

  params:add_option("midi in", {"disabled", "enabled"}, 2)
  params:add_option("midi selects", {"false", "true"})
  params:add_option("trig on value change", {"false", "true"})

  for i=0,7 do
  --[[
  TODO: looping
    params:add_control((i+1)..": start", start_spec, Formatters.unipolar_as_percentage)
    params:set_action((i+1)..": start", function(value) engine.start(i, value) end)
    params:add_control((i+1)..": end", end_spec, Formatters.unipolar_as_percentage)
    params:set_action((i+1)..": end", function(value) engine.end(i, value) end)
    params:add_control((i+1)..": loop point", loop_point_spec, Formatters.unipolar_as_percentage)
    params:set_action((i+1)..": loop point", function(value) engine.loopPoint(i, value) end)
    params:add_option((i+1)..": loop", {"off", "on"})
    params:set_action((i+1)..": loop", function(value) engine.loop(i, value) end)
  ]]
    params:add_control((i+1)..": speed", speed_spec, Formatters.unipolar_as_percentage)
    params:set_action((i+1)..": speed", function(value) engine.speed(i, value) end)
    params:add_control((i+1)..": vol", volume_spec, Formatters.std)
    params:set_action((i+1)..": vol", function(value) engine.volume(i, value) end)
    params:add_control((i+1)..": vol env atk", volume_env_attack_spec, Formatters.secs_as_ms)
    params:set_action((i+1)..": vol env atk", function(value) engine.volumeEnvAttack(i, value) end)
    params:add_control((i+1)..": vol env rel", volume_env_release_spec, Formatters.secs_as_ms)
    params:set_action((i+1)..": vol env rel", function(value) engine.volumeEnvRelease(i, value) end)
    params:add_control((i+1)..": pan", ControlSpec.pan(), Formatters.bipolar_as_pan_widget)
    params:set_action((i+1)..": pan", function(value) engine.pan(i, value) end)
    params:add_control((i+1)..": filter cutoff", filter_cutoff_spec, Formatters.round(0.001))
    params:set_action((i+1)..": filter cutoff", function(value) engine.filterCutoff(i, value) end)
    params:add_control((i+1)..": filter res", filter_res_spec, Formatters.unipolar_as_percentage)
    params:set_action((i+1)..": filter res", function(value) engine.filterRes(i, value) end)
    --[[
    params:add_control((i+1)..": filter mode", filter_mode_spec, Formatters.std)
    params:set_action(function(value) engine.filterMode(i, value) end)
    ]]
    params:add_control((i+1)..": filter env atk", filter_env_attack_spec, Formatters.secs_as_ms)
    params:set_action((i+1)..": filter env atk", function(value) engine.filterEnvAttack(i, value) end)
    params:add_control((i+1)..": filter env rel", filter_env_release_spec, Formatters.secs_as_ms)
    params:set_action((i+1)..": filter env rel", function(value) engine.filterEnvRelease(i, value) end)
    params:add_control((i+1)..": filter env mod", filter_env_mod_spec, Formatters.unipolar_as_percentage)
    params:set_action((i+1)..": filter env mod", function(value) engine.filterEnvMod(i, value) end)
    params:add_control((i+1)..": delay send", send_spec, Formatters.std)
    params:set_action((i+1)..": delay send", function(value) engine.delaySend(i, value) end)
    params:add_control((i+1)..": reverb send", send_spec, Formatters.std)
    params:set_action((i+1)..": reverb send", function(value) engine.reverbSend(i, value) end)
    --[[
    TODO: enable slews
    params:add_control((i+1)..": speed slew", slew_spec, Formatters.std)
    params:set_action((i+1)..": speed slew", function(value) engine.speedSlew(i, value) end)
    params:add_control((i+1)..": vol slew", slew_spec, Formatters.std)
    params:set_action((i+1)..": vol slew", function(value) engine.volumeSlew(i, value) end)
    params:add_control((i+1)..": pan slew", slew_spec, Formatters.std)
    params:set_action((i+1)..": pan slew", function(value) engine.panSlew(i, value) end)
    params:add_control((i+1)..": filter cutoff slew", slew_spec, Formatters.std)
    params:set_action((i+1)..": filter cutoff slew", function(value) engine.filterCutoffSlew(i, value) end)
    params:add_control((i+1)..": filter res slew", slew_spec, Formatters.std)
    params:set_action((i+1)..": filter res slew", function(value) engine.filterResSlew(i, value) end)
    ]]
  end

  params:add_control("delay time", delay_time_spec, Formatters.secs_as_ms)
  params:set_action("delay time", engine.delayTimeL)
  params:add_control("delay feedback", delay_time_spec, Formatters.secs_as_ms)
  params:set("delay feedback", 0.75)
  params:set_action("delay feedback", engine.delayTimeL)
  params:add_control("reverb room", reverb_room_spec, Formatters.unipolar_as_percentage)
  params:set_action("reverb room", engine.reverbRoom)
  params:add_control("reverb damp", reverb_damp_spec, Formatters.unipolar_as_percentage)
  params:set_action("reverb damp", engine.reverbRoom)
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

redraw = function()
  --[[
  if scroll then
    scroll:redraw(screen)
  end
  screen.update()
  ]]

  screen.clear()
  screen.level(15)
  screen.aa(0)
  screen.move(0,7*8-1)
  screen.font_size(20)
  screen.text("ack")
  screen.update()
end

local function trig_if_channel_param(param)
  if param then
    local channel = get_channel_from_string(param.name)
    if channel then
      print("debugs"..channel)
      engine.trig(channel-1)
    end
  end
end

enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
    return
  end

  if n == 2 then
    scroll:navigate(delta)
    redraw()
  elseif n == 3 then
    if scroll.selected_param then
      --[[
      local d
      if key2_down then
        d = delta/500
      else
        d = delta/50
      end
      ]]
      local param = scroll.selected_param
      local prev = param:get()
      param:delta(delta)
      if param:get() ~= prev and trig_on_change:get() == 1 then
        trig_if_channel_param(param)
      end
      redraw()
    end
  end
end

key = function(n, z)
  if z == 1 then
    if n == 2 then
      key2_down = true
      trig_if_channel_param(scroll.selected_param)
    elseif n == 3 then
      if scroll.selected_param then
        local param = scroll.selected_param
        local prev = param:get()
        param:set_default()
        if param:get() ~= prev and trig_on_change:get() == 1 then
          trig_if_channel_param(param)
        end
        redraw()
      end
    end
  end
  if z == 0 then
    if n == 2 then
      key2_down = false
    elseif n == 3 then
    end
  end
end

cleanup = function()
  norns.midi.event = nil
end

norns.midi.event = function(id, status, data1, data2)
  if midi_in:get() == 1 then
    -- TODO print(id, status, data1, data2)
    if status == 144 then
      --[[
      if data1 == 0 then
        return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
      end
      ]]
      note_on(data1, data2)
    elseif status == 128 then
      --[[
      if data1 == 0 then
        return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
      end
      ]]
      note_off(data1)
    elseif status == 176 then
      cc(data1, data2)
    elseif status == 224 then
      bend(data1, data2)
    end
  end
end
