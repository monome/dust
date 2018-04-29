-- hello ack
--
-- ack test script
--
-- midi controllable
--

local ControlSpec = require 'controlspec'
local Formatters = require 'jah/formatters'
local Ack = require 'jah/ack'
local FS = require 'fileselect'

engine.name = 'Ack'

local midi_cc_spec = ControlSpec.new(0, 127, 'lin', 1, 0, "")

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
    spec = Ack.FILTER_CUTOFF_SPEC
    abs = params:get("filter cutoff cc type") == 1
  elseif ctl == params:get("filter res cc") then
    param = "filter res"
    spec = Ack.FILTER_RES_SPEC
    abs = params:get("filter res cc type") == 1
  elseif ctl == params:get("delay send cc") then
    param = "delay send"
    spec = Ack.SEND_SPEC
    abs = params:get("delay send cc type") == 1
  elseif ctl == params:get("reverb send cc") then
    param = "reverb send"
    spec = Ack.SEND_SPEC
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

  Ack.add_params()

  -- params:read("param_ack.pset")
  params:bang()
end

redraw = function()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("hello ack")
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
  if what ~= "-" then
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
    FS.enter("/home/pi/dust", newfile)
  end
end

cleanup = function()
  norns.midi.event = nil
  -- params:write("param_ack.pset")
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
