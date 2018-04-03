-- @name rymd
-- @version 0.1.0
-- @author jah
-- @txt wip echo chamber thing

ControlSpec = require 'lua/jah/_controlspec'
Param = require 'lua/jah/_param'
Scroll = require 'lua/jah/_scroll'
Helper = require 'lua/jah/_helper'
R = require 'lua/jah/_r'

engine = 'R'

local percent_spec = ControlSpec.new(0, 1, 'lin', 0, 0, "")
local lofreq_spec = ControlSpec.new(0.1, 100, 'exp', 0, 6, "Hz")
local db_spec = ControlSpec.new(-60, 0, 'lin', 0, -60, "dB")
local delay_time_spec = ControlSpec.new(0.0001, 3, 'exp', 0, 0.3, "secs")

local delay_send = Param.new("delay send level", db_spec)

local delayl_delaytime = Param.new("delayl delaytime", delay_time_spec)
local delayr_delaytime = Param.new("delayr delaytime", delay_time_spec)

local filterl_freq = Param.new("filterl freq", percent_spec)
-- local filterl_res = Param.new("filterl res", percent_spec)
local filterl_lforate = Param.new("filterl lforate", lofreq_spec)
local filterl_lfodepth = Param.new("filterl lfodepth", percent_spec)

local filterr_freq = Param.new("filterr freq", percent_spec)
--local filterr_res = Param.new("filterr res", percent_spec)
local filterr_lforate = Param.new("filterr lforate", lofreq_spec)
local filterr_lfodepth = Param.new("filterr lfodepth", percent_spec)

local delay_feedback = Param.new("delay feedback", db_spec)

local output_level = Param.new("output level", db_spec)

local function update_delay_send()
  e.patch('inl', 'delayl', delay_send:mapped_value())
  e.patch('inr', 'delayr', delay_send:mapped_value())
end

local function update_delay_feedback()
  e.patch('filterl', 'delayr', delay_feedback:mapped_value())
  e.patch('filterr', 'delayl', delay_feedback:mapped_value())
end

local function update_output_level()
  e.patch('inl', 'outl', output_level:mapped_value())
  e.patch('inr', 'outr', output_level:mapped_value())
  e.patch('filterl', 'outl', output_level:mapped_value())
  e.patch('filterr', 'outr', output_level:mapped_value())
end

local function send_param_value(param)
  if param == delay_send then
    update_delay_send()
  elseif param == delay_feedback then
    update_delay_feedback()
  elseif param == output_level then
    update_output_level()
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

  delay_send:set_mapped_value(0)
  update_delay_send()

  delayl_delaytime:set_mapped_value(0.52)
  delayr_delaytime:set_mapped_value(0.44)
  R.send_r_param_values_to_engine({delayl_delaytime, delayr_delaytime})

  e.module('filterl', 'pole')
  e.module('filterr', 'pole')

  e.patch('delayl', 'filterl', 0)
  e.patch('delayr', 'filterr', 0)

  filterl_freq:set(0.36)
  -- filterl_res:set(0.1)
  filterr_freq:set(0.36)
  -- filterr_res:set(0.1)
  filterl_lforate:set_mapped_value(0.08)
  filterl_lfodepth:set(0.1)
  filterr_lforate:set_mapped_value(0.14)
  filterr_lfodepth:set(0.1)
  R.send_r_param_values_to_engine({filterl_freq, filterl_lforate, filterl_lfodepth, filterr_freq, filterr_lforate, filterr_lfodepth})

  delay_feedback:set_mapped_value(-5)
  update_delay_feedback()

  e.module('outl', 'output')
  e.module('outr', 'output')
  e.param('outr', 'config', 1) -- sets outr to output on right channel

  output_level:set_mapped_value(-20)
  update_output_level()

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
