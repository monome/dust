-- @name 3oscs
-- @version 0.1.0
-- @author jah
-- @txt test r

ControlSpec = require 'controlspec'
Param = require 'param'
Scroll = require 'jah/scroll'
Formatters = require 'formatters'
R = require 'jah/r'

engine = 'R'

local function to_hz(note)
  local exp = (note - 21) / 12
  return 27.5 * 2^exp
end

local index_spec = ControlSpec.new(0, 24, 'lin', 0, 3, "")

local filter_freq_spec = ControlSpec.unipolar()
filter_freq_spec.default = 0.5

local delay_time_spec = ControlSpec.delay()
delay_time_spec.maxval = 3

local osc1_freq = Param.new("osc1 freq", ControlSpec.widefreq(), Formatters.round(0.01))
local osc1_index = Param.new("osc1 index", index_spec, Formatters.round(0.01))
local osc1_filter_patch = Param.new("osc1 > filter", ControlSpec.db())
local osc1_osc1_patch = Param.new("osc1 > osc1", ControlSpec.db()) -- TODO: i dunno about feedback
local osc1_osc2_patch = Param.new("osc1 > osc2", ControlSpec.db())
local osc1_osc3_patch = Param.new("osc1 > osc3", ControlSpec.db())

osc1_freq:set_mapped_value(to_hz(69+12)) -- TODO: move to init() or bang in init() ?
osc1_index:set_mapped_value(3)
osc1_osc2_patch:set_mapped_value(-20)
osc1_osc3_patch:set_mapped_value(-20)

local osc2_freq = Param.new("osc2 freq", ControlSpec.widefreq(), Formatters.round(0.01))
local osc2_index = Param.new("osc2 index", index_spec, Formatters.round(0.01))
local osc2_filter_patch = Param.new("osc2 > filter", ControlSpec.db())
local osc2_osc1_patch = Param.new("osc2 > osc1", ControlSpec.db()) -- TODO: i dunno about feedback
local osc2_osc2_patch = Param.new("osc2 > osc2", ControlSpec.db()) -- TODO: i dunno about feedback
local osc2_osc3_patch = Param.new("osc2 > osc3", ControlSpec.db())

osc2_freq:set_mapped_value(to_hz(69-12)) -- TODO: move to init() or bang in init() ?
osc2_index:set_mapped_value(9)
osc2_filter_patch:set_mapped_value(-20)

local osc3_freq = Param.new("osc3 freq", ControlSpec.widefreq(), Formatters.round(0.01))
local osc3_index = Param.new("osc3 index", index_spec, Formatters.round(0.01))
local osc3_filter_patch = Param.new("osc3 > filter", ControlSpec.db())
local osc3_osc1_patch = Param.new("osc3 > osc1", ControlSpec.db()) -- TODO: i dunno about feedback
local osc3_osc2_patch = Param.new("osc3 > osc2", ControlSpec.db()) -- TODO: i dunno about feedback
local osc3_osc3_patch = Param.new("osc3 > osc3", ControlSpec.db()) -- TODO: i dunno about feedback

osc3_freq:set_mapped_value(to_hz(69)) -- TODO: move to init() or bang in init() ?
osc3_index:set_mapped_value(3)
osc3_filter_patch:set_mapped_value(-20)

local filter_freq = Param.new("filter freq", filter_freq_spec, Formatters.unipolar_as_multimode_filter_freq)
local filter_res = Param.new("filter res", ControlSpec.unipolar(), Formatters.unipolar_as_percentage)
local filter_lforate = Param.new("filter lforate", ControlSpec.lofreq(), Formatters.round(0.01))
local filter_lfodepth = Param.new("filter lfodepth", ControlSpec.unipolar(), Formatters.unipolar_as_percentage)

filter_freq:set(0.4) -- TODO: move to init() or bang in init() ?
filter_res:set(0.1)
filter_lforate:set_mapped_value(0.1)
filter_lfodepth:set(0.1)

local delayl_delaytime = Param.new("delayl delaytime", delay_time_spec, Formatters.secs_as_ms)
delayl_delaytime:set_mapped_value(0.23)
local delayr_delaytime = Param.new("delayr delaytime", delay_time_spec, Formatters.secs_as_ms)
delayr_delaytime:set_mapped_value(0.45)

local delay_send = Param.new("delay send level", ControlSpec.db())
delay_send:set_mapped_value(-30)
delay_send.on_change_mapped = function(value)
  e.patch('filter', 'delayl', value)
  e.patch('filter', 'delayr', value)
end

local delay_feedback = Param.new("delay feedback", ControlSpec.db())
delay_feedback:set_mapped_value(-20)
delay_feedback.on_change_mapped = function(value)
  e.patch('delayl', 'delayr', value)
  e.patch('delayr', 'delayl', value)
end

local output_level = Param.new("output level", ControlSpec.db())
output_level:set_mapped_value(-40)
output_level.on_change_mapped = function(value)
  e.patch('delayl', 'outl', value)
  e.patch('delayr', 'outr', value)
  e.patch('filter', 'outl', value)
  e.patch('filter', 'outr', value)
end

local function init_delay()
  for key,param in pairs({delayl_delaytime, delayr_delaytime}) do
    param.on_change_mapped = function(value)
      R.send_r_param_value_to_engine(param)
    end
    param:bang()
  end
end

local function init_output()
end

local function note_on(note, velocity)
  -- print("note_on: "..note..", velocity: "..velocity) -- TODO: replace this with on-screen notification
  osc1_ratio = osc1_freq:mapped_value() / osc3_freq:mapped_value()
  osc2_ratio = osc2_freq:mapped_value() / osc3_freq:mapped_value()
  local freq = to_hz(note)
  osc1_freq:set_mapped_value(freq*osc1_ratio)
  osc2_freq:set_mapped_value(freq*osc2_ratio)
  osc3_freq:set_mapped_value(freq)
  redraw()
end

local function note_off(note)
  -- print("note_off: "..note)
end

local function cc(control, value)
  -- print("control: "..control..", value: "..value) -- TODO: replace this with on-screen notification
  if control == 1 then
    osc3_index:set(value/127)
    redraw()
  elseif control == 2 then
    osc2_index:set(value/127)
    redraw()
  elseif control == 3 then
    filter_freq:set(value/127)
    redraw()
  elseif control == 4 then
    filter_res:set(value/127)
    redraw()
  end
end

init = function()
  s.aa(1)
  s.line_width(1.0)

  e.capacity(8)
  e.module('osc1', 'oscil')
  e.module('osc2', 'oscil')
  e.module('osc3', 'oscil')
  e.module('filter', 'pole')
  e.module('delayl', 'delay')
  e.module('delayr', 'delay')
  e.module('outl', 'output')
  e.module('outr', 'output')

  for key,param in pairs({osc1_freq, osc1_index, osc1_filter_patch, osc1_osc1_patch, osc1_osc2_patch, osc1_osc3_patch, osc2_freq, osc2_index, osc2_filter_patch, osc2_osc1_patch, osc2_osc2_patch, osc2_osc3_patch, osc3_freq, osc3_index, osc3_filter_patch, osc3_osc1_patch, osc3_osc2_patch, osc3_osc3_patch, filter_freq, filter_res, filter_lforate, filter_lfodepth, delayl_delaytime, delayr_delaytime}) do
    param.on_change_mapped = function(value)
      R.send_r_param_value_to_engine(param)
    end
    param:bang()
  end

  delay_send:bang()
  delay_feedback:bang()

  e.param('outr', 'config', 1) -- sets outr to output on right channel
  output_level:bang()

  scroll = Scroll.new()
  scroll:push("this is a test of r.")
  scroll:push("three oscillators")
  scroll:push("a modulating filter")
  scroll:push("and a stereo delay")
  scroll:push("")
  scroll:push("scroll ui with middle enc.")
  scroll:push("adjust values with rightmost")
  scroll:push("enc - hold middle key to")
  scroll:push("fine adjust. rightmost key")
  scroll:push("will revert value to default.")
  scroll:push("")
  scroll:push(osc1_freq)
  scroll:push(osc1_index)
  scroll:push(osc1_filter_patch)
  scroll:push(osc1_osc1_patch)
  scroll:push(osc1_osc2_patch)
  scroll:push(osc1_osc3_patch)
  scroll:push("")
  scroll:push(osc2_freq)
  scroll:push(osc2_index)
  scroll:push(osc2_filter_patch)
  scroll:push(osc2_osc1_patch)
  scroll:push(osc2_osc2_patch)
  scroll:push(osc2_osc3_patch)
  scroll:push("")
  scroll:push(osc3_freq)
  scroll:push(osc3_index)
  scroll:push(osc3_filter_patch)
  scroll:push(osc3_osc1_patch)
  scroll:push(osc3_osc2_patch)
  scroll:push(osc3_osc3_patch)
  scroll:push("")
  scroll:push(filter_freq)
  scroll:push(filter_res)
  scroll:push(filter_lforate)
  scroll:push(filter_lfodepth)
  scroll:push("")
  scroll:push(delay_send)
  scroll:push(delayl_delaytime)
  scroll:push(delayr_delaytime)
  scroll:push(delay_feedback)
  scroll:push("")
  scroll:push(output_level)
  scroll:push("")
  scroll:push("midi support:")
  scroll:push("note ons will change")
  scroll:push("osc3 freq, and osc1")
  scroll:push("and osc2 freqs relative")
  scroll:push("to osc1.")
  scroll:push("")
  scroll:push("op-1 (midi ctrl mode):")
  scroll:push("knobs will change osc3 index,")
  scroll:push("osc2 index, filter freq,")
  scroll:push("filter res")
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

enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
    return
  end

  local d
  if key2_down then
    d = delta/2500
  else
    d = delta/100
  end
  if n == 2 then
    scroll:navigate(delta)
    redraw()
  elseif n == 3 then
    if scroll.selected_param then
      local param = scroll.selected_param
      param:adjust(d)
      redraw()
    end
  end
end

key = function(n, z)
  if z == 1 then
    if n == 2 then
      key2_down = true
    elseif n == 3 then
      if scroll.selected_param then
        local param = scroll.selected_param
        param:revert_to_default()
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
  -- print(id, status, data1, data2)
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
