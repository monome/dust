-- @name param ack
-- @version 0.1.0
-- @author jah
-- @txt ack params test

local ControlSpec = require 'controlspec'
local Control = require 'control'
local Formatters = require 'jah/formatters'
local FS = require 'fileselect'

engine.name = 'Ack'

local midi_cc_spec = ControlSpec.new(0, 127, 'lin', 1, 0, "")

--[[
TODO: looping
local start_spec = ControlSpec.unipolar()
local end_spec = ControlSpec.new(0, 1, 'lin', 0, 1, "")
local loop_point_spec = ControlSpec.unipolar()
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

local delay_feedback = Control.new("delay feedback", delay_time_spec, Formatters.secs_as_ms)
delay_feedback:set(0.75)
delay_feedback.action = function(value) engine.delayFeedback(value) end
local reverb_room = Control.new("reverb room", reverb_room_spec, Formatters.unipolar_as_percentage)
reverb_room.action = function(value) engine.reverbRoom(value) end
local reverb_damp = Control.new("reverb damp", reverb_damp_spec, Formatters.unipolar_as_percentage)
reverb_damp.action = function(value) engine.reverbDamp(value) end

local selected_channel = 0
local all_selected = false
local midinote_indicator_level
local midicc_indicator_level
local note_downs = {}

local function screen_update_channels()
  screen.move(0,16)
  screen.font_size(8)
  for channel=0,7 do
    if note_downs[channel] then
      screen.level(15)
    elseif selected_channel == channel or all_selected then
      screen.level(6)
    else
      screen.level(2)
    end
    screen.text(channel+1)
  end
  if all_selected then
    screen.level(6)
  else
    screen.level(0)
  end
  screen.text(" all")
  screen.update()
end

local function screen_update_midi_indicators()
  --screen.move(125, 20)
  screen.move(0,60)
  screen.font_size(8)
  if midi_available then
    screen.level(15)
    screen.text("midi:")
    screen.text(" ")
    screen.level(midinote_indicator_level)
    screen.text("note ")
    screen.level(midicc_indicator_level)
    screen.text("cc")
  else
    screen.level(3)
    screen.text("no midi")
  end
end

local function channel_from_midinote(midinote)
  local channel = nil
  if midinote == 60 then
    channel = 0
  elseif midinote == 62 then
    channel = 1
  elseif midinote == 64 then
    channel = 2
  elseif midinote == 65 then
    channel = 3
  elseif midinote == 67 then
    channel = 4
  elseif midinote == 69 then
    channel = 5
  elseif midinote == 71 then
    channel = 6
  elseif midinote == 72 then
    channel = 7
  end
  return channel
end

local function note_on(note, velocity)
  local channel = channel_from_midinote(note)
  if channel then
    if not note_downs[channel] then
      note_downs[channel] = true
      engine.trig(channel)
      if params:get("midi selects channel") == 2 then
        selected_channel = channel
      end
      screen_update_channels()
    end
  end
end

local function note_off(note)
  local channel = channel_from_midinote(note)
  if channel then
    note_downs[channel] = false
    screen_update_channels()
  end
end

local function cc_set_control(name, controlspec, value)
  params:set(name, controlspec:map(midi_cc_spec:unmap(value)))
end

local function cc_delta_control(name, controlspec, value)
  local delta
  if value > 0 and value < 64 then
    delta = value
  else
    delta = value - 128
  end
  local value = params:get(name)
  local value_unmapped = controlspec:unmap(value)
  local new_unmapped_value = value_unmapped + delta/100
  params:set(name, controlspec:map(new_unmapped_value))
end

local function cc(ctl, value)
  local param
  local spec
  if ctl == params:get("filter cutoff cc") then
    param = "filter cutoff"
    spec = filter_cutoff_spec
    abs = params:get("filter cutoff cc type") == 1
  elseif ctl == params:get("filter res cc") then
    param = "filter res"
    spec = filter_res_spec
    abs = params:get("filter res cc type") == 1
  elseif ctl == params:get("delay send cc") then
    param = "delay send"
    spec = send_spec
    abs = params:get("delay send cc type") == 1
  elseif ctl == params:get("reverb send cc") then
    param = "reverb send"
    spec = send_spec
    abs = params:get("reverb send cc type") == 1
  end
  if param then
    if abs then
      if all_selected then
        for i=0,7 do
          cc_set_control((i+1)..": "..param, spec, value)
        end
      else
        cc_set_control((selected_channel+1)..": "..param, spec, value)
      end
    else
      if all_selected then
        for i=0,7 do
          cc_delta_control((i+1)..": "..param, spec, value)
        end
      else
        cc_delta_control((selected_channel+1)..": "..param, spec, value)
      end
    end
  end
end

init = function()
  screen.aa(1)
  screen.line_width(1.0)

  local bool = {"false", "true"}
  params:add_option("midi in", {"disabled", "enabled"}, 2)
  params:add_option("midi selects channel", bool, 2)

  local cc_list = {}
  for i=0,127 do
    cc_list[i] = i
  end
  cc_type = {"abs", "rel"}
  params:add_option("filter cutoff cc", cc_list, 1)
  params:add_option("filter cutoff cc type", cc_type)
  params:add_option("filter res cc", cc_list, 2)
  params:add_option("filter res cc type", cc_type)
  params:add_option("delay send cc", cc_list, 3)
  params:add_option("delay send cc type", cc_type)
  params:add_option("reverb send cc", cc_list, 4)
  params:add_option("reverb send cc type", cc_type)
  -- TODO params:add_option("trig on param change", bool)

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
  params:set_action("delay time", engine.delayTime)
  params:add_control("delay feedback", delay_time_spec, Formatters.secs_as_ms)
  params:set("delay feedback", 0.75)
  params:set_action("delay feedback", engine.delayFeedback)
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
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("ack")
  screen_update_channels()
  screen_update_midi_indicators()
  screen.update()
end

enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
    return
  elseif n == 2 then
    local new_selection
    if delta < 0 then
      if selected_channel ~= 0 then
        new_selection = selected_channel - 1
      end
    else
      if selected_channel ~= 7 then
        new_selection = selected_channel + 1
      end
    end
    if new_selection then
      if note_downs[selected_channel] then
        note_downs[selected_channel] = false
      end
      selected_channel = new_selection
      redraw()
    end
  else
    if all_selected then
      for i=0,7 do
        params:delta((i+1)..": speed", delta)
      end
    else
      params:delta((selected_channel+1)..": speed", delta)
    end
  end
end

local function trig_channel(channel)
  engine.trig(channel)
  if not note_downs[channel] then
    note_downs[channel] = true
  end
end

local function reset_channel(channel)
  if note_downs[channel] then
    note_downs[channel] = false
  end
end

local function newfile(what)
  if what ~= "cancel" then
    engine.loadSample(selected_channel, what)
  end
end

key = function(n, z)
  if n == 2 then
    if z == 1 then
      if all_selected then
        for i=0,7 do trig_channel(i) end
      else
        trig_channel(selected_channel)
      end
      screen_update_channels()
    else
      if all_selected then
        for i=0,7 do reset_channel(i) end
      else
        reset_channel(selected_channel)
      end
      screen_update_channels()
    end
  elseif n == 3 then
    all_selected = z == 1
    redraw()
  elseif n==1 and z==1 then
    FS.enter("/home/pi/dust/audio", newfile)
  end
end

cleanup = function()
  norns.midi.event = nil
end

norns.midi.add = function(id, name, dev)
  midi_available = true
  midinote_indicator_level = 3
  midicc_indicator_level = 3
  redraw()
end

norns.midi.remove = function(id)
  midi_available = false
  redraw()
end

norns.midi.event = function(id, data)
  status = data[1]
  data1 = data[2]
  data2 = data[3]
  if params:get("midi in") == 2 then
    if status == 144 then
      midinote_indicator_level = math.random(15)
      --[[
      if data1 == 0 then
        return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
      end
      ]]
      note_on(data1, data2)
      redraw()
    elseif status == 128 then
      --[[
      if data1 == 0 then
        return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
      end
      ]]
      note_off(data1)
    elseif status == 176 then
      midicc_indicator_level = math.random(15)
      cc(data1, data2)
      redraw()
    elseif status == 224 then
      bend(data1, data2)
    end
  end
end
