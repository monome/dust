-- hello ack.
-- sample player
-- controlled by midi or grid
--
-- enc2: select sample
-- enc3: change pitch*
-- key2: trig selected sample(s)
-- key3: all modifier
--
-- * more parameters in
-- menu > parameters
--
-- midi notes/grid:
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
local Ack = require 'jah/ack'
local midi = require 'midi'
local grid = require 'grid'
local Metro = require 'metro'

engine.name = 'Ack'

local midi_device = midi.connect(1)

local grid_device = grid.connect(1)

local indicate_midi_event
local indicate_gridkey_event

local midi_cc_spec = ControlSpec.new(0, 127, 'lin', 1, 0, '')
local default_channel_midi_notes = { 60, 62, 64, 65, 67, 69, 71, 72 }
local selected_channels = {1}
local all_modifier_is_held = false
local note_downs = {}

local function contains(table, value)
  for i=1,#table do
    if value == table[i] then
      return true
    end
  end
  return false
end

local function update_channel_indicators()
  screen.move(0,16)
  screen.font_size(8)
  for channel=1,8 do
    if note_downs[channel] then
      screen.level(15)
    elseif contains(selected_channels, channel) or all_modifier_is_held then
      screen.level(6)
    else
      screen.level(2)
    end
    screen.text(channel)
  end
  if all_modifier_is_held then
    screen.level(6)
  else
    screen.level(0)
  end
  screen.text(" all")
  screen.update()
end

local function update_device_indicators()
  screen.move(0,60)
  screen.font_size(8)
  if midi_device.attached then
    if indicate_midi_event then
      screen.level(8)
    else
      screen.level(15)
    end
    screen.text("midi")
  end
  screen.level(15)
  if midi_device.attached and grid_device.attached then
    screen.text("+")
  end
  if grid_device.attached then
    if indicate_gridkey_event then
      screen.level(8)
    else
      screen.level(15)
    end
    screen.text("grid")
  end
  if midi_device.attached == false and grid_device.attached == false then
    screen.level(3)
    screen.text("no midi / grid")
  end
end

local function channels_from_midinote(midinote)
  channels = {}
  for channel=1,8 do
    if params:get(channel.."_midi_note") == midinote then
      table.insert(channels, channel)
    end
  end
  return channels
end

local function trig_channel(channel)
  engine.trig(channel-1)
  if not note_downs[channel] then
    note_downs[channel] = true
  end
end

local function trig_channels(channels)
  local arr = {}
  for channel=1,8 do
    if contains(channels, channel) then
      arr[channel] = 1
      if not note_downs[channel] then
        note_downs[channel] = true
      end
    else
      arr[channel] = 0
    end
  end
  engine.multiTrig(arr[1], arr[2], arr[3], arr[4], arr[5], arr[6], arr[7], arr[8])
end

local function reset_channel(channel)
  if note_downs[channel] then
    note_downs[channel] = false
  end
end

local function note_on(note, velocity)
  local channels = channels_from_midinote(note)
  if #channels > 0 then
    if params:get("midi_selects_channel") == 2 then
      selected_channels = {}
    end
    for _, channel in pairs(channels) do
      if not note_downs[channel] then
        if params:get("midi_selects_channel") == 2 then
          table.insert(selected_channels, channel)
        end
      end
    end
    trig_channels(channels)
    redraw()
  end
end

local function note_off(note)
  local channels = channels_from_midinote(note)
  if #channels > 0 then
    for _, channel in pairs(channels) do
      note_downs[channel] = false
    end
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
  local param_name
  local spec
  if ctl == params:get("filter_cutoff_cc") then
    param_name = "filter_cutoff"
    spec = Ack.specs.filter_cutoff
    abs = params:get("filter_cutoff_cc_type") == 1
  elseif ctl == params:get("filter_res_cc") then
    param_name = "filter_res"
    spec = Ack.specs.filter_res
    abs = params:get("filter_res_cc_type") == 1
  elseif ctl == params:get("delay_send_cc") then
    param_name = "delay_send"
    spec = Ack.specs.send
    abs = params:get("delay_send_cc_type") == 1
  elseif ctl == params:get("reverb_send_cc") then
    param_name = "reverb_send"
    spec = Ack.specs.send
    abs = params:get("reverb_send_cc_type") == 1
  end
  if param_name then
    if abs then
      if all_modifier_is_held then
        for channel=1,8 do
          cc_set_control(channel.."_"..param_name, spec, value)
        end
      else
        for _, channel in pairs(selected_channels) do
          cc_set_control(channel.."_"..param_name, spec, value)
        end
      end
    else
      if all_modifier_is_held then
        for channel=1,8 do
          cc_delta_control(channel.."_"..param_name, spec, value)
        end
      else
        for _, channel in pairs(selected_channels) do
          cc_delta_control(channel.."_"..param_name, spec, value)
        end
      end
    end
  end
end

local function midi_event(data)
  indicate_midi_event = true
  local status = data[1]
  local data1 = data[2]
  local data2 = data[3]
  if params:get("midi_in") == 2 then
    if status == 144 then
      if data2 ~= 0 then
        note_on(data1, data2)
      else
        note_off(data1)
      end
      redraw()
    elseif status == 128 then
      note_off(data1)
    elseif status == 176 then
      cc(data1, data2)
    end
  end
end

midi_device.event = midi_event

local function grid_refresh()
  for channel=1,8 do
    local brightness
    if contains(selected_channels, channel) or all_modifier_is_held then
      brightness = 15
    else
      brightness = 5
    end

    grid_device.led(channel, 8, brightness)
  end
  grid_device.refresh()
end

local function gridkey_event(x, y, s)
  indicate_gridkey_event = true
  if y == 8 and x < 9 then
    if s == 1 then
      trig_channel(x)
      if params:get("grid_selects_channel") == 2 then
        selected_channels = {x}
        redraw()
      end
    else
      reset_channel(x)
      redraw()
    end
  end
end

grid_device.event = gridkey_event

function init()
  screen.aa(1)
  screen.line_width(1.0)

  local bool = {"false", "true"}
  params:add_option("grid_selects_channel", "grid_selects_channel", bool, 2)
  params:add_separator()
  params:add_option("midi_in", "midi in", {"disabled", "enabled"}, 2)
  params:add_option("midi_selects_channel", "midi selects channel", bool, 2)

  local midi_cc_note_list = {}
  for i=0,127 do
    midi_cc_note_list[i] = i
  end
  local cc_type = {"abs", "rel"}
  params:add_option("filter_cutoff_cc", "filter cutoff cc", midi_cc_note_list, 1)
  params:add_option("filter_cutoff_cc_type", "filter cutoff cc type", cc_type)
  params:add_option("filter_res_cc", "filter res cc", midi_cc_note_list, 2)
  params:add_option("filter_res_cc_type", "filter res cc type", cc_type)
  params:add_option("delay_send_cc", "delay send cc", midi_cc_note_list, 3)
  params:add_option("delay_send_cc_type", "delay send cc type", cc_type)
  params:add_option("reverb_send_cc", "reverb send cc", midi_cc_note_list, 4)
  params:add_option("reverb_send_cc_type", "reverb send cc type", cc_type)

  params:add_separator()

  for channel=1,8 do
    params:add_option(channel.."_midi_note", channel..": midi note", midi_cc_note_list, default_channel_midi_notes[channel])
    Ack.add_channel_params(channel)
  end

  params:add_separator()
  Ack.add_effects_params()

  refresh_metro = Metro.alloc(
    function(stage)
      grid_refresh()
    end,
    1 / 40
  )
  refresh_metro:start()

  refresh_screen_metro = Metro.alloc(
    function(stage)
      redraw()
      if indicate_midi_event then
        indicate_midi_event = false
      end
      if indicate_gridkey_event then
        indicate_gridkey_event = false
      end
    end,
    1 / 20
  )
  refresh_screen_metro:start()

  params:read("jah/hello_ack.pset")
  params:bang()
end

function cleanup()
  params:write("jah/hello_ack.pset")
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("hello ack")
  update_channel_indicators()
  update_device_indicators()
  screen.update()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
    return
  elseif n == 2 then
    local min_selected_channel = selected_channels[1]
    for i=2,#selected_channels do
      if min_selected_channel > selected_channels[i] then
        min_selected_channel = selected_channels[i]
      end
    end
    local new_selection

    if delta < 0 then
      if min_selected_channel ~= 1 then
        new_selection = { min_selected_channel - 1 }
      end
    else
      if min_selected_channel ~= 8 then
        new_selection = { min_selected_channel + 1 }
      end
    end
    if new_selection then
      for _, channel in pairs(selected_channels) do
        reset_channel(channel)
      end
      selected_channels = new_selection
      redraw()
    end
  else
    if all_modifier_is_held then
      for channel=1,8 do
        params:delta(channel..": speed", delta)
      end
    else
      for _, channel in pairs(selected_channels) do
        params:delta(channel..": speed", delta)
      end
    end
  end
end

function key(n, z)
  if n == 2 then
    if z == 1 then
      if all_modifier_is_held then
        trig_channels({1,2,3,4,5,6,7,8})
      else
        trig_channels(selected_channels)
      end
      update_channel_indicators()
    else
      if all_modifier_is_held then
        for channel=1,8 do reset_channel(channel) end
      else
        for _, channel in pairs(selected_channels) do
          reset_channel(channel)
        end
      end
      update_channel_indicators()
    end
  elseif n == 3 then
    all_modifier_is_held = z == 1
    redraw()
  end
end

