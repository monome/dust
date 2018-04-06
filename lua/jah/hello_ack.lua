-- @name hello ack
-- @version 0.1.0
-- @author jah
-- @txt ack test

ControlSpec = require 'jah/controlspec'
Param = require 'jah/param'
Scroll = require 'jah/scroll'
Helper = require 'helper'
Formatters = require 'jah/formatters'

engine = 'Ack'

local debug = false

local bool_spec = ControlSpec.new(0, 1, 'lin', 1, 0, "")

--[[
TODO: looping
local loop_start_spec = ControlSpec.unipolar_spec()
local loop_end_spec = ControlSpec.new(0, 1, 'lin', 0, 1, "")
]]
local speed_spec = ControlSpec.new(0, 5, 'lin', 0, 1, "")
-- local slew_spec = ControlSpec.new(0, 5, 'lin', 0, 0, "") -- TODO: enable slews
local volume_spec = ControlSpec.db_spec()
volume_spec.default = -10
local send_spec = ControlSpec.db_spec()
send_spec.default = -60
local volume_env_attack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
local volume_env_release_spec = ControlSpec.new(0, 3, 'lin', 0, 3, "secs")
local filter_env_attack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
local filter_env_release_spec = ControlSpec.new(0, 3, 'lin', 0, 0.25, "secs")
local filter_cutoff_spec = ControlSpec.freq_spec()
filter_cutoff_spec.default = 20000
local filter_res_spec = ControlSpec.unipolar_spec()
local filter_mode_spec = ControlSpec.new(0, 1, 'lin', 1, 0)
local filter_env_mod_spec = ControlSpec.unipolar_spec()

local delay_time_spec = ControlSpec.new(0.0001, 5, 'exp', 0, 0.1, "secs")
-- local delay_feedback_spec = ControlSpec.unipolar_spec() -- TODO feedback should be 0-1 displayed as %
local reverb_room_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
local reverb_damp_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")

local midi_in = Param.new("midi in", bool_spec, Formatters.unipolar_as_enabled_disabled)
midi_in:set(1) -- TODO: hack, better idea: encoder deltas configured per param or set_min_mapped_value()/set_max_mapped_value()

local midi_selects = Param.new("midi selects", bool_spec, Formatters.unipolar_as_true_false)
midi_selects:set(0.98) -- TODO: hack, better idea: encoder deltas configured per param or set_min_mapped_value()/set_max_mapped_value()

local trig_on_change = Param.new("trig on value change", bool_spec, Formatters.unipolar_as_true_false)
trig_on_change:set(0.98) -- TODO: hack, better idea: encoder deltas configured per param or set_min_mapped_value()/set_max_mapped_value()

local channel_params = {}
for i=0,7 do
  local p = {}
--[[
TODO: looping
  p.loop_start = Param.new((i+1)..": loop start", loop_start_spec, Formatters.unipolar_as_percentage)
  p.loop_start.on_change_mapped = function(value) e.loopStart(i, value) end
  p.loop_end = Param.new((i+1)..": loop end", loop_end_spec, Formatters.unipolar_as_percentage)
  p.loop_end.on_change_mapped = function(value) e.loopEnd(i, value) end
]]
  p.speed = Param.new((i+1)..": speed", speed_spec, Formatters.unipolar_as_percentage)
  p.speed.on_change_mapped = function(value) e.speed(i, value) end
  p.volume = Param.new((i+1)..": vol", volume_spec)
  p.volume.on_change_mapped = function(value) e.volume(i, value) end
  p.volume_env_attack = Param.new((i+1)..": vol env atk", volume_env_attack_spec, Formatters.secs_as_ms)
  p.volume_env_attack.on_change_mapped = function(value) e.volumeEnvAttack(i, value) end
  p.volume_env_release = Param.new((i+1)..": vol env rel", volume_env_release_spec, Formatters.secs_as_ms)
  p.volume_env_release.on_change_mapped = function(value) e.volumeEnvRelease(i, value) end
  p.pan = Param.new((i+1)..": pan", ControlSpec.pan_spec(), Formatters.bipolar_as_pan_widget)
  p.pan.on_change_mapped = function(value) e.pan(i, value) end
  p.filter_cutoff = Param.new((i+1)..": filter cutoff", filter_cutoff_spec, Formatters.round(0.001))
  p.filter_cutoff.on_change_mapped = function(value) e.filterCutoff(i, value) end
  p.filter_res = Param.new((i+1)..": filter res", filter_res_spec, Formatters.unipolar_as_percentage)
  p.filter_res.on_change_mapped = function(value) e.filterRes(i, value) end
  p.filter_mode = Param.new((i+1)..": filter mode", filter_mode_spec)
  p.filter_mode.on_change_mapped = function(value) e.filterMode(i, value) end
  p.filter_env_attack = Param.new((i+1)..": filter env atk", filter_env_attack_spec, Formatters.secs_as_ms)
  p.filter_env_attack.on_change_mapped = function(value) e.filterEnvAttack(i, value) end
  p.filter_env_release = Param.new((i+1)..": filter env rel", filter_env_release_spec, Formatters.secs_as_ms)
  p.filter_env_release.on_change_mapped = function(value) e.filterEnvRelease(i, value) end
  p.filter_env_mod = Param.new((i+1)..": filter env mod", filter_env_mod_spec, Formatters.unipolar_as_percentage)
  p.filter_env_mod.on_change_mapped = function(value) e.filterEnvMod(i, value) end
  p.delay_send = Param.new((i+1)..": delay send", send_spec)
  p.delay_send.on_change_mapped = function(value) e.delaySend(i, value) end
  p.reverb_send = Param.new((i+1)..": reverb send", send_spec)
  p.reverb_send.on_change_mapped = function(value) e.reverbSend(i, value) end
  --[[
  TODO: enable slews
  p.speed_slew = Param.new((i+1)..": speed slew", slew_spec)
  p.speed_slew.on_change_mapped = function(value) e.speedSlew(i, value) end
  p.volume_slew = Param.new((i+1)..": vol slew", slew_spec)
  p.volume_slew.on_change_mapped = function(value) e.volumeSlew(i, value) end
  p.pan_slew = Param.new((i+1)..": pan slew", slew_spec)
  p.pan_slew.on_change_mapped = function(value) e.panSlew(i, value) end
  p.filter_cutoff_slew = Param.new((i+1)..": filter cutoff slew", slew_spec)
  p.filter_cutoff_slew.on_change_mapped = function(value) e.filterCutoffSlew(i, value) end
  p.filter_res_slew = Param.new((i+1)..": filter res slew", slew_spec)
  p.filter_res_slew.on_change_mapped = function(value) e.filterResSlew(i, value) end
  ]]
  channel_params[i] = p
end

local delay_time = Param.new("delay time", delay_time_spec, Formatters.secs_as_ms)
delay_time.on_change_mapped = function(value) e.delayTimeL(value) end
-- local delay_time_r = Param.new("delay time r", delay_time_spec) TODO
-- delay_time_r.on_change_mapped = function(value) e.delayTimeR(value) end TODO
local delay_feedback = Param.new("delay feedback", delay_time_spec, Formatters.secs_as_ms)
delay_feedback:set_mapped_value(0.75)
delay_feedback.on_change_mapped = function(value) e.delayFeedback(value) end
local reverb_room = Param.new("reverb room", reverb_room_spec, Formatters.unipolar_as_percentage)
reverb_room.on_change_mapped = function(value) e.reverbRoom(value) end
local reverb_damp = Param.new("reverb damp", reverb_damp_spec, Formatters.unipolar_as_percentage)
reverb_damp.on_change_mapped = function(value) e.reverbDamp(value) end

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
    e.trig(channel)
    if midi_selects:mapped_value() == 1 then
      local selected_param = scroll.selected_param

      if selected_param == nil or get_channel_from_string(selected_param.title) ~= channel+1 then -- TODO: make this the proper way
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
  s.aa(1)
  s.line_width(1.0)

  for channelnum=0,7 do
    for key, param in pairs(channel_params[channelnum]) do param:bang() end
  end
  delay_time:bang()
  delay_feedback:bang()
  reverb_room:bang()
  reverb_damp:bang()

  local sampleroot = "/home/pi/dust/audio/hello_ack/"
	e.loadSample(0, sampleroot.."XR-20_003.wav")
	e.loadSample(1, sampleroot.."XR-20_114.wav")
	e.loadSample(2, sampleroot.."XR-20_285.wav")
	e.loadSample(3, sampleroot.."XR-20_328.wav")
	e.loadSample(4, sampleroot.."XR-20_121.wav")
	e.loadSample(5, sampleroot.."XR-20_667.wav")
	e.loadSample(6, sampleroot.."XR-20_128.wav")
	e.loadSample(7, sampleroot.."XR-20_718.wav")

  scroll = Scroll.new()
  scroll:push("ack test script")
  scroll:push("")
  scroll:push("# ui")
  scroll:push("")
  scroll:push("enc2: scroll ui")
  scroll:push("enc3: change param value")
  scroll:push("key2: preview sound")
  scroll:push("key2+enc3: fine adjust")
  scroll:push("key3: set value to default")
  scroll:push("")
  scroll:push("# global settings")
  scroll:push("")
  scroll:push(midi_in)
  scroll:push("(when enabled midi notes ")
  scroll:push("c4...c5 from external midi")
  scroll:push("device will trigger sounds)")
  scroll:push("")
  scroll:push(midi_selects)
  scroll:push("(when true and midi is")
  scroll:push("enabled incoming midi notes")
  scroll:push("will select channels)")
  scroll:push("")
  scroll:push(trig_on_change)
  scroll:push("(when true sounds will be")
  scroll:push("triggered upon change of")
  scroll:push("channel params)")
  scroll:push("")
  scroll:push("# ack")
  scroll:push("")
  for i=0,7 do
    -- TODO scroll:push(channel_params[i].loop_start)
    -- TODO scroll:push(channel_params[i].loop_end)
    scroll:push(channel_params[i].speed)
    scroll:push(channel_params[i].volume)
    scroll:push(channel_params[i].volume_env_attack)
    scroll:push(channel_params[i].volume_env_release)
    scroll:push(channel_params[i].pan)
    -- TODO scroll:push(channel_params[i].filter_mode)
    scroll:push(channel_params[i].filter_cutoff)
    scroll:push(channel_params[i].filter_res)
    scroll:push(channel_params[i].filter_env_attack)
    scroll:push(channel_params[i].filter_env_release)
    scroll:push(channel_params[i].filter_env_mod)
    scroll:push(channel_params[i].delay_send)
    scroll:push(channel_params[i].reverb_send)
    --[[
    TODO: why aren't slews working?
    scroll:push(channel_params[i].speed_slew)
    scroll:push(channel_params[i].volume_slew)
    scroll:push(channel_params[i].pan_slew)
    -- TODO scroll:push(channel_params[i].filter_cutoff_slew)
    scroll:push(channel_params[i].filter_res_slew)
    ]]
    scroll:push("")

  end
  scroll:push(delay_time)
  -- scroll:push(delay_time_r) TODO
  scroll:push(delay_feedback)
  scroll:push("")
  scroll:push(reverb_room)
  scroll:push(reverb_damp)
  scroll:push("")
  scroll:push("...fin")
  redraw()
end

redraw = function()
  if scroll then
    scroll:redraw()
  end
  s.update()
end

local function trig_if_channel_param(param)
  if param then
    local channel = get_channel_from_string(param.title)
    if channel then
      e.trig(channel-1)
    end
  end
end

enc = function(n, delta)
  if n == 1 then
    Helper.adjust_audio_output_level(delta)
    return
  end

  if n == 2 then
    scroll:navigate(delta)
    redraw()
  elseif n == 3 then
    if scroll.selected_param then
    local d
    if key2_down then
      d = delta/500
    else
      d = delta/50
    end
      local param = scroll.selected_param
      local prev = param.value
      param:adjust(d)
      if param.value ~= prev and trig_on_change:mapped_value() == 1 then
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
        local prev = param.value
        param:revert_to_default()
        if param.value ~= prev and trig_on_change:mapped_value() == 1 then
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
  if midi_in:mapped_value() == 1 then
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
