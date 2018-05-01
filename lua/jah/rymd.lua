-- wip echo chamber thing

ControlSpec = require 'controlspec'
Control = require 'control'
Scroll = require 'jah/scroll'
Formatters = require 'jah/formatters'
R = require 'jah/r'

engine.name = 'R'

local filter_freq_spec = ControlSpec.UNIPOLAR:copy()
filter_freq_spec.default = 0.5

local delay_send_spec =  ControlSpec.DB:copy()
delay_send_spec.default = 0

local delay_time_spec = ControlSpec.DELAY:copy()
delay_time_spec.maxval = 3

local delay_feedback_spec = ControlSpec.DB:copy()
delay_feedback_spec.default = -5

local output_level_spec = ControlSpec.DB:copy()
output_level_spec.default = -20

local delay_send = Control.new("delay send level", delay_send_spec, Formatters.std)
delay_send.action = function(value)
  engine.patch('inl', 'delayl', value)
  engine.patch('inr', 'delayr', value)
end

local delayl_delaytime = Control.new("delayl delaytime", delay_time_spec, Formatters.secs_as_ms)
delayl_delaytime:set(0.52)
local delayr_delaytime = Control.new("delayr delaytime", delay_time_spec, Formatters.secs_as_ms)
delayr_delaytime:set(0.44)

local filterl_freq = Control.new("filterl freq", filter_freq_spec, Formatters.unipolar_as_multimode_filter_freq)
filterl_freq:set(0.36)
local filterl_lforate = Control.new("filterl lforate", ControlSpec.LOFREQ, Formatters.std)
filterl_lforate:set(0.08)
local filterl_lfodepth = Control.new("filterl lfodepth", ControlSpec.UNIPOLAR, Formatters.unipolar_as_percentage)
filterl_lfodepth:set(0.1)

local filterr_freq = Control.new("filterr freq", filter_freq_spec, Formatters.unipolar_as_multimode_filter_freq)
filterr_freq:set(0.36)
local filterr_lforate = Control.new("filterr lforate", ControlSpec.LOFREQ, Formatters.std)
filterr_lforate:set(0.14)
local filterr_lfodepth = Control.new("filterr lfodepth", ControlSpec.UNIPOLAR, Formatters.unipolar_as_percentage)
filterr_lfodepth:set(0.1)

local delay_feedback = Control.new("delay feedback", delay_feedback_spec, Formatters.std)
delay_feedback.action = function(value)
  engine.patch('filterl', 'delayr', value)
  engine.patch('filterr', 'delayl', value)
end

local output_level = Control.new("output level", output_level_spec, Formatters.std)
output_level.action = function(value)
  engine.patch('inl', 'outl', value)
  engine.patch('inr', 'outr', value)
  engine.patch('filterl', 'outl', value)
  engine.patch('filterr', 'outr', value)
end

init = function()
  screen.aa(1)
  screen.line_width(1.0) 

  engine.capacity(8)
  engine.module('inl', 'input')
  engine.module('inr', 'input')
  engine.param('inr', 'config', 1) -- sets inr to input right channel

  engine.module('delayl', 'delay')
  engine.module('delayr', 'delay')

  delay_send:bang()

  for key,param in pairs({delayl_delaytime, delayr_delaytime, filterl_freq, filterl_lforate, filterl_lfodepth, filterr_freq, filterr_lforate, filterr_lfodepth}) do
    param.action = function(value)
      R.send_r_param_value_to_engine(engine, param)
    end
    param:bang()
  end

  engine.module('filterl', 'pole')
  engine.module('filterr', 'pole')

  engine.patch('delayl', 'filterl', 0)
  engine.patch('delayr', 'filterr', 0)

  delay_feedback:bang()

  engine.module('outl', 'output')
  engine.module('outr', 'output')
  engine.param('outr', 'config', 1) -- sets outr to output on right channel

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
  scroll:push(filterr_freq)
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
  --redraw()
end

redraw = function()
  if scroll then
    scroll:redraw(screen)
  end
  screen.update()
end

enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
    return
  end

  --[[
  local d
  if key2_down then
    d = delta/2500
  else
    d = delta/100
  end
  ]]
  if n == 2 then
    scroll:navigate(delta)
    redraw()
  elseif n == 3 then
    if scroll.selected_param then
      local param = scroll.selected_param
      param:delta(delta)
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
        param:set_default()
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
