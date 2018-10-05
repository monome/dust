-- VOICE
--
-- A monophonic synth voice
--
-- KEY3 - voice trigger
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
  engine.new("LFO", "MultiLFO2")
  engine.new("Env", "ADSREnv")
  engine.new("FilterMod", "Mixer")
  engine.new("Osc", "SquareOsc")
  engine.new("Filter", "MMFilter")
  engine.new("Amp", "Amp2")
  engine.new("SoundOut", "SoundOut")

  engine.connect("LFO/Sine", "Osc/PWM")
  engine.connect("LFO/Sine", "FilterMod/In1")
  engine.connect("Env/Out", "FilterMod/In2")
  engine.connect("Env/Out", "Amp/Lin")
  engine.connect("FilterMod/Out", "Filter/FM")

  engine.connect("Osc/Out", "Filter/In")
  engine.connect("Filter/Lowpass", "Amp/In")
  engine.connect("Amp/Out", "SoundOut/Left")
  engine.connect("Amp/Out", "SoundOut/Right")

  scroll:push("A monophonic synth voice")
  scroll:push("")

  add_rcontrol {
    id="env_gate",
    name="Env.Gate",
    spec=ControlSpec.new(0, 1, 'lin', 1, 0),
    formatter=Formatters.round(1)
  }

  add_rcontrol {
    id="lfo_frequency",
    name="LFO.Frequency",
    spec=R.specs.MultiLFO2.Frequency,
    formatter=Formatters.round(0.001)
  }

  add_rcontrol {
    id="osc_range",
    name="Osc.Range",
    spec=R.specs.SquareOsc.Range
  }

  add_rcontrol {
    id="osc_tune",
    name="Osc.Tune",
    spec=R.specs.SquareOsc.Tune
  }

  add_rcontrol {
    id="osc_pulsewidth",
    name="Osc.PulseWidth",
    spec=R.specs.SquareOsc.PulseWidth,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="lfo_to_osc_pwm",
    name="LFO > Osc.PWM",
    ref="Osc.PWM",
    spec=R.specs.SquareOsc.PWM,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="env_attack",
    name="Env.Attack",
    spec=R.specs.ADSREnv.Attack
  }

  add_rcontrol {
    id="env_decay",
    name="Env.Decay",
    spec=R.specs.ADSREnv.Decay
  }

  add_rcontrol {
    id="env_sustain",
    name="Env.Sustain",
    spec=R.specs.ADSREnv.Sustain
  }

  add_rcontrol {
    id="env_release",
    name="Env.Release",
    spec=R.specs.ADSREnv.Release
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
    ref="FilterMod.In1",
    spec=R.specs.Mixer.In1,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="env_to_filter_fm",
    name="Env > Filter.FM",
    ref="FilterMod.In2",
    spec=R.specs.Mixer.In2,
    formatter=Formatters.percentage
  }

  scroll:push("") -- TODO

  engine.set("FilterMod.Out", 1)
  engine.set("Filter.FM", 1)

  params:set("lfo_frequency", 0.2)
  params:set("lfo_to_osc_pwm", 0.6)
  params:set("env_attack", 1)
  params:set("env_decay", 800)
  params:set("env_release", 1250)
  params:set("filter_frequency", 500)
  params:set("filter_resonance", 0.4)
  params:set("lfo_to_filter_fm", 0.4)
  params:set("env_to_filter_fm", 0.3)

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

function key(n, z)
  if n == 3 then
    if z == 1 then
      params:set("env_gate", 1)
    else
      params:set("env_gate", 0)
    end
    redraw()
  end
end

