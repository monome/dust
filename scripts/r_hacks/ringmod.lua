-- RINGMOD
--
-- Ring modulation example
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
    action=function(value) engine.set(args.ref or args.name, value) end
  }
end

function init()
  engine.new("Osc1FG", "FreqGate")
  engine.new("Osc1", "MultiOsc")
  engine.new("Osc2FG", "FreqGate")
  engine.new("Osc2", "MultiOsc")
  engine.new("RingMod", "RingMod")
  engine.new("SoundOut", "SoundOut")

  engine.set("Osc1.FM", 1)
  engine.set("Osc2.FM", 1)

  engine.connect("Osc1FG/Frequency", "Osc1/FM")
  engine.connect("Osc1/Sine", "RingMod/In")
  engine.connect("Osc2FG/Frequency", "Osc2/FM")
  engine.connect("Osc2/Sine", "RingMod/Carrier")

  engine.connect("RingMod/Out", "SoundOut/Left")
  engine.connect("RingMod/Out", "SoundOut/Right")

  scroll:push("Ring modulation example")
  scroll:push("")

  add_rcontrol {
    id="osc1_freq",
    name="Osc1 Freq",
    ref="Osc1FG.Frequency",
    spec=R.specs.FreqGate.Frequency,
    formatter=Formatters.round(0.001)
  }

  add_rcontrol {
    id="osc2_freq",
    name="Osc2 Freq",
    ref="Osc2FG.Frequency",
    spec=R.specs.FreqGate.Frequency,
    formatter=Formatters.round(0.001)
  }

  --[[
  add_rcontrol {
    id="osc1_range",
    name="Osc1.Range",
    spec=R.specs.MultiOsc.Range
  }

  add_rcontrol {
    id="osc1_tune",
    name="Osc1.Tune",
    spec=R.specs.MultiOsc.Tune
  }

  add_rcontrol {
    id="osc2_range",
    name="Osc2.Range",
    spec=R.specs.MultiOsc.Range
  }

  add_rcontrol {
    id="osc2_tune",
    name="Osc2.Tune",
    spec=R.specs.MultiOsc.Tune
  }
  ]]

  scroll:push("") -- TODO: Scroll bug

  params:set("osc1_freq", 42)
  params:set("osc2_freq", 704)

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
