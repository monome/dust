-- FILTER
--
-- Square wave oscillator with
-- pulse width modulation thru
-- modulatable lowpass filter
--

local ControlSpec = require 'controlspec'
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
  engine.new("LFO", "MultiLFO")
  engine.new("Osc", "PulseOsc")
  engine.new("Filter", "MMFilter")
  engine.new("SoundOut", "SoundOut")

  engine.connect("LFO/Sine", "Osc/PWM")
  engine.connect("LFO/Sine", "Filter/FM")

  engine.connect("Osc/Out", "Filter/In")

  engine.connect("Filter/Lowpass", "SoundOut/Left")
  engine.connect("Filter/Lowpass", "SoundOut/Right")

  scroll:push("Square wave oscillator with")
  scroll:push("pulse width modulation thru")
  scroll:push("modulatable lowpass filter")
  scroll:push("")

  add_rcontrol {
    id="lfo_frequency",
    name="LFO.Frequency",
    spec=R.specs.MultiLFO.Frequency,
    formatter=Formatters.round(0.001)
  }

  add_rcontrol {
    id="osc_range",
    name="Osc.Range",
    spec=R.specs.PulseOsc.Range
  }

  add_rcontrol {
    id="osc_tune",
    name="Osc.Tune",
    spec=R.specs.PulseOsc.Tune
  }

  add_rcontrol {
    id="osc_pulsewidth",
    name="Osc.PulseWidth",
    spec=R.specs.PulseOsc.PulseWidth,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="lfo_to_osc_pwm",
    name="LFO > Osc.PWM",
    ref="Osc.PWM",
    spec=R.specs.PulseOsc.PWM,
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
  params:set("lfo_to_osc_pwm", 0.6)
  params:set("filter_frequency", 2000)
  params:set("filter_resonance", 0.4)
  params:set("lfo_to_filter_fm", 0.4)

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
