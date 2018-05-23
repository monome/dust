-- hello ack.
-- sample player
-- controlled by midi
--
-- enc2: select sample
-- enc3: change pitch*
-- key2: trig sample
-- key3: all modifier
--
-- * more parameters in
-- menu > parameters
--
-- midi notes:
-- trigger samples
--
-- midi cc:
-- tweak cutoff, resonance,
-- reverb, delay of selected
-- sample(s)
--
-- midi notes and ccs are 
-- configurable in
-- menu > parameters
--

local ControlSpec = require 'controlspec'
local Formatters = require 'jah/formatters'
local Ack = require 'jah/ack'

engine.name = 'Ack'

local midi_note_spec = ControlSpec.new(0, 127, 'lin', 1, 0, "")
local default_channel_midi_notes = { 60, 62, 64, 65, 67, 69, 71, 72 }

local midi_cc_spec = ControlSpec.new(0, 127, 'lin', 1, 0, "")

local selected_channel = 1
local all_selected = false
local note_downs = {}

local function screen_update_channels()
  screen.move(0,16)
  screen.font_size(8)
  for channel=1,8 do
    if note_downs[channel] then
      screen.level(15)
    elseif selected_channel == channel or all_selected then
      screen.level(6)
    else
      screen.level(2)
    end
    screen.text(channel)
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
  screen.move(0,60)
  screen.font_size(8)
  if midi_available then
    screen.level(15)
    screen.text("midi")
  else
    screen.level(3)
    screen.text("no midi")
  end
end

local function channel_from_midinote(midinote)
  for channel=1,8 do
    if params:get(channel..": midi note") == midinote then
      return channel
    end
  end
  return nil
end

local function note_on(note, velocity)
  local channel = channel_from_midinote(note)
  if channel then
    if not note_downs[channel] then
      note_downs[channel] = true
      engine.trig(channel-1)
      if params:get("midi selects channel") == 2 then
        selected_channel = channel
      end
      redraw()
    end
  end
end

local function note_off(note)
  local channel = channel_from_midinote(note)
  if channel then
    note_downs[channel] = false
    redraw()
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
    spec = Ack.specs.filter_cutoff
    abs = params:get("filter cutoff cc type") == 1
  elseif ctl == params:get("filter res cc") then
    param = "filter res"
    spec = Ack.specs.filter_res
    abs = params:get("filter res cc type") == 1
  elseif ctl == params:get("delay send cc") then
    param = "delay send"
    spec = Ack.specs.send
    abs = params:get("delay send cc type") == 1
  elseif ctl == params:get("reverb send cc") then
    param = "reverb send"
    spec = Ack.specs.send
    abs = params:get("reverb send cc type") == 1
  end
  if param then
    if abs then
      if all_selected then
        for channel=1,8 do
          cc_set_control(channel..": "..param, spec, value)
        end
      else
        cc_set_control((selected_channel)..": "..param, spec, value)
      end
    else
      if all_selected then
        for channel=1,8 do
          cc_delta_control(channel..": "..param, spec, value)
        end
      else
        cc_delta_control((selected_channel)..": "..param, spec, value)
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

  params:add_separator()

  local midi_cc_note_list = {}
  for i=0,127 do
    midi_cc_note_list[i] = i
  end
  cc_type = {"abs", "rel"}
  params:add_option("filter cutoff cc", midi_cc_note_list, 1)
  params:add_option("filter cutoff cc type", cc_type)
  params:add_option("filter res cc", midi_cc_note_list, 2)
  params:add_option("filter res cc type", cc_type)
  params:add_option("delay send cc", midi_cc_note_list, 3)
  params:add_option("delay send cc type", cc_type)
  params:add_option("reverb send cc", midi_cc_note_list, 4)
  params:add_option("reverb send cc type", cc_type)

  params:add_separator()

  for channel=1,8 do
    params:add_option(channel..": midi note", midi_cc_note_list, default_channel_midi_notes[channel])
    Ack.add_channel_params(channel)
  end

  params:add_separator()
  Ack.add_effects_params()

  params:read("hello_ack.pset")
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
    mix:delta("output", delta)
    return
  elseif n == 2 then
    local new_selection
    if delta < 0 then
      if selected_channel ~= 1 then
        new_selection = selected_channel - 1
      end
    else
      if selected_channel ~= 8 then
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
      for channel=1,8 do
        params:delta(channel..": speed", delta)
      end
    else
      params:delta((selected_channel)..": speed", delta)
    end
  end
end

local function trig_channel(channel)
  engine.trig(channel-1)
  if not note_downs[channel] then
    note_downs[channel] = true
  end
end

local function reset_channel(channel)
  if note_downs[channel] then
    note_downs[channel] = false
  end
end

key = function(n, z)
  if n == 2 then
    if z == 1 then
      if all_selected then
        for channel=1,8 do trig_channel(channel) end
      else
        trig_channel(selected_channel)
      end
      screen_update_channels()
    else
      if all_selected then
        for channel=1,8 do reset_channel(channel) end
      else
        reset_channel(selected_channel)
      end
      screen_update_channels()
    end
  elseif n == 3 then
    all_selected = z == 1
    redraw()
  end
end

cleanup = function()
  norns.midi.event = nil
  params:write("hello_ack.pset")
end

norns.midi.add = function(id, name, dev)
  midi_available = true
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
      note_on(data1, data2)
      redraw()
    elseif status == 128 then
      note_off(data1)
    elseif status == 176 then
      cc(data1, data2)
    end
  end
end
