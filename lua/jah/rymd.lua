-- @name rymd
-- @version 0.1.0
-- @author jah
-- @txt wip echo chamber thing

ControlSpec = require 'jah/controlspec'
Param = require 'jah/param'
Scroll = require 'jah/scroll'
Helper = require 'helper'
Formatters = require 'jah/formatters'
R = require 'jah/r'

engine = 'R'

local filter_freq_spec = ControlSpec.unipolar_spec()
filter_freq_spec.default = 0.5

local delay_send_spec =  ControlSpec.db_spec()
delay_send_spec.default = 0

local delay_time_spec = ControlSpec.delay_spec()
delay_time_spec.maxval = 3

local delay_feedback_spec = ControlSpec.db_spec()
delay_feedback_spec.default = -5

local output_level_spec = ControlSpec.db_spec()
output_level_spec.default = -20

local delay_send = Param.new("delay send level", delay_send_spec)
delay_send.on_change_mapped = function(value)
  e.patch('inl', 'delayl', value)
  e.patch('inr', 'delayr', value)
end

local delayl_delaytime = Param.new("delayl delaytime", delay_time_spec, Formatters.secs_as_ms)
delayl_delaytime:set_mapped_value(0.52)
local delayr_delaytime = Param.new("delayr delaytime", delay_time_spec, Formatters.secs_as_ms)
delayr_delaytime:set_mapped_value(0.44)

local filterl_freq = Param.new("filterl freq", filter_freq_spec, Formatters.unipolar_as_multimode_filter_freq)
filterl_freq:set(0.36)
-- local filterl_res = Param.new("filterl res", ControlSpec.unipolar_spec())
-- filterl_res:set(0.1)
local filterl_lforate = Param.new("filterl lforate", ControlSpec.lofreq_spec())
filterl_lforate:set_mapped_value(0.08)
local filterl_lfodepth = Param.new("filterl lfodepth", ControlSpec.unipolar_spec(), Formatters.unipolar_as_percentage)
filterl_lfodepth:set(0.1)

local filterr_freq = Param.new("filterr freq", filter_freq_spec, Formatters.unipolar_as_multimode_filter_freq)
filterr_freq:set(0.36)
--local filterr_res = Param.new("filterr res", ControlSpec.unipolar_spec())
-- filterr_res:set(0.1)
local filterr_lforate = Param.new("filterr lforate", ControlSpec.lofreq_spec())
filterr_lforate:set_mapped_value(0.14)
local filterr_lfodepth = Param.new("filterr lfodepth", ControlSpec.unipolar_spec(), Formatters.unipolar_as_percentage)
filterr_lfodepth:set(0.1)

local delay_feedback = Param.new("delay feedback", delay_feedback_spec)
delay_feedback.on_change_mapped = function(value)
  e.patch('filterl', 'delayr', value)
  e.patch('filterr', 'delayl', value)
end

local output_level = Param.new("output level", output_level_spec)
output_level.on_change_mapped = function(value)
  e.patch('inl', 'outl', value)
  e.patch('inr', 'outr', value)
  e.patch('filterl', 'outl', value)
  e.patch('filterr', 'outr', value)
end

local function send_param_value(param)
  if param == delay_send then
    -- TODO update_delay_send()
  elseif param == delay_feedback then
    -- TODO update_delay_feedback()
  elseif param == output_level then
    -- TODO update_output_level()
  else
    R.send_r_param_value_to_engine(param)
  end
end

init = function()
  s.aa(1)
  s.line_width(1.0) 

  e.capacity(8)
  e.module('inl', 'input')
  e.module('inr', 'input')
  e.param('inr', 'config', 1) -- sets inr to input right channel

  e.module('delayl', 'delay')
  e.module('delayr', 'delay')

  delay_send:bang()

  R.send_r_param_values_to_engine({delayl_delaytime, delayr_delaytime})

  e.module('filterl', 'pole')
  e.module('filterr', 'pole')

  e.patch('delayl', 'filterl', 0)
  e.patch('delayr', 'filterr', 0)

  R.send_r_param_values_to_engine({filterl_freq, filterl_lforate, filterl_lfodepth, filterr_freq, filterr_lforate, filterr_lfodepth})

  delay_feedback:bang()

  e.module('outl', 'output')
  e.module('outr', 'output')
  e.param('outr', 'config', 1) -- sets outr to output on right channel

  output_level:bang()

  scroll = Scroll.new()
  scroll:push("another test of r.")
  scroll:push("audio inputs are routed")
  scroll:push("to a stereo delay with")
  scroll:push("a modulating filter in")
  scroll:push("the feedback loop")
  scroll:push("")
  scroll:push("scroll ui with middle enc.")
  scroll:push("adjust values with rightmost")
  scroll:push("enc - hold middle key to")
  scroll:push("fine adjust. rightmost key")
  scroll:push("will revert value to default.")
  scroll:push("")
  scroll:push(delay_send)
  scroll:push("")
  scroll:push(delayl_delaytime)
  scroll:push(delayr_delaytime)
  scroll:push("")
  scroll:push(filterl_freq)
  -- scroll:push(filterl_res)
  scroll:push(filterr_freq)
  -- scroll:push(filterr_res)
  scroll:push("")
  scroll:push(filterl_lforate)
  scroll:push(filterl_lfodepth)
  scroll:push(filterr_lforate)
  scroll:push(filterr_lfodepth)
  scroll:push("")
  scroll:push(delay_feedback)
  scroll:push("")
  scroll:push(output_level)
  scroll:push("")
  scroll:push("fin1")
  scroll:push("fin2")
  scroll:push("fin3")
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
    Helper.adjust_audio_output_level(delta)
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
      send_param_value(param)
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
        send_param_value(param)
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
end
