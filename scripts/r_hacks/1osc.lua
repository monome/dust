-- 1OSC
--

local ControlSpec = require 'controlspec'
local Option = require 'params/option'
local Control = require 'params/control'
local Formatters = require 'jah/formatters'
local Scroll = require 'jah/scroll'
local R = require 'jah/r'
local scroll = Scroll.new()

engine.name = 'R'

local function add_rcontrol(args)
  local control = Control.new(args.id, args.name, args.spec, args.formatter)
  scroll:push(control)
  params:add {
    param=control,
    action=args.action or function(value) engine.set(args.ref or args.name, value) end
  }
end

function init()
  engine.new("LFO", "MultiLFO2")
  engine.new("Osc", "MultiOsc")
  engine.new("Filter", "MMFilter")
  engine.new("SoundOut", "SoundOut")

  engine.connect("Filter/Lowpass", "SoundOut/Left")
  engine.connect("Filter/Lowpass", "SoundOut/Right")

  scroll:push("Square wave oscillator with")
  scroll:push("pulse width modulation thru")
  scroll:push("modulatable lowpass filter")
  scroll:push("")

  local current_lfo_wave
  local lfo_wave_option = Option.new(
    "lfo_wave",
    "LFO/Wave",
    {"InvSaw", "Saw", "Sine", "Triangle", "Square"}
  )
  scroll:push(lfo_wave_option)
  params:add {
    param=lfo_wave_option,
    action=function(value)
      if current_lfo_wave then
        engine.disconnect("LFO/"..current_lfo_wave, "Osc/PWM")
        engine.disconnect("LFO/"..current_lfo_wave, "Filter/FM")
      end
      if not current_lfo_wave then
        current_lfo_wave = "InvSaw" -- default
      end
      current_lfo_wave = lfo_wave_option.options[value]
      engine.connect("LFO/"..current_lfo_wave, "Osc/PWM")
      engine.connect("LFO/"..current_lfo_wave, "Filter/FM")
    end
  }

  add_rcontrol {
    id="lfo_frequency",
    name="LFO.Frequency",
    spec=R.specs.MultiLFO2.Frequency,
    formatter=Formatters.round(0.001)
  }

  -- TODO: add support to Scroll
  --[[
  params:add {
    type = "trigger",
    id = "lfo_reset",
    name = "LFO.Reset",
    action = function()
      engine.set("LFO.Reset", 1)
      engine.set("LFO.Reset", 0)
    end
  }
  ]]
    
  local current_osc_wave
  local osc_wave_option = Option.new(
    "osc_wave",
    "Osc/Wave",
    {"Sine", "Triangle", "Saw", "Square"}
  )
  scroll:push(osc_wave_option)
  params:add {
    param=osc_wave_option,
    action=function(value)
      if current_osc_wave then
        engine.disconnect("Osc/"..current_osc_wave, "Filter/In")
      end
      if not current_osc_wave then
        current_osc_wave = "Square" -- default
      end
      current_osc_wave = osc_wave_option.options[value]
      engine.connect("Osc/"..current_osc_wave, "Filter/In")
    end
  }

  add_rcontrol {
    id="osc_range",
    name="Osc.Range",
    spec=R.specs.MultiOsc.Range
  }

  add_rcontrol {
    id="osc_tune",
    name="Osc.Tune",
    spec=R.specs.MultiOsc.Tune
  }

  add_rcontrol {
    id="osc_pulsewidth",
    name="Osc.PulseWidth",
    spec=R.specs.MultiOsc.PulseWidth,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="lfo_to_osc_pwm",
    name="LFO > Osc.PWM",
    ref="Osc.PWM",
    spec=R.specs.MultiOsc.PWM,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="filter_frequency",
    name="Filter.Frequency",
    spec=R.specs.MMFilter.Frequency
  }

  add_rcontrol {
    id="filter_resonance",
    name="Filter.Resonance",
    spec=R.specs.MMFilter.Resonance,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="lfo_to_filter_fm",
    name="LFO > Filter.FM",
    ref="Filter.FM",
    spec=R.specs.MMFilter.FM,
    formatter=Formatters.percentage
  }

  scroll:push("") -- TODO

  params:set("lfo_frequency", 0.2)
  params:set("lfo_to_osc_pwm", 0.2)
  params:set("filter_frequency", 2000)
  params:set("filter_resonance", 0.4)
  params:set("lfo_to_filter_fm", 0.1)

  params:bang()
end

function redraw()
  screen.clear()
  scroll:draw(screen)
  screen.update()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    scroll:navigate(util.clamp(delta, -1, 1)) -- TODO: hack
    redraw()
  elseif n == 3 then
    if scroll.selected_param then
      local param = scroll.selected_param
      param:delta(delta)
      redraw()
    end
  end
end
