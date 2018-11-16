-- FM
--
-- FM example
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
  engine.new("CarrierFG", "FreqGate")
  engine.new("Carrier", "MultiOsc")
  engine.new("OperatorFG", "FreqGate")
  engine.new("Operator", "MultiOsc")
  engine.new("SoundOut", "SoundOut")

  engine.set("Carrier.FM", 1)

  engine.connect("CarrierFG/Frequency", "Carrier/FM")
  engine.connect("Carrier/Sine", "Operator/FM")
  engine.connect("OperatorFG/Frequency", "Operator/FM")
  engine.connect("Operator/Sine", "SoundOut/Left")
  engine.connect("Operator/Sine", "SoundOut/Right")

  scroll:push("FM example")
  scroll:push("")

  add_rcontrol {
    id="carrier_freq",
    name="Carrier Freq",
    ref="CarrierFG.Frequency",
    spec=R.specs.FreqGate.Frequency,
    formatter=Formatters.round(0.001)
  }

  add_rcontrol {
    id="fm_amount",
    name="FM Amount",
    ref="Operator.FM",
    spec=R.specs.MultiOsc.FM
  }

  add_rcontrol {
    id="operator_freq",
    name="Operator Freq",
    ref="OperatorFG.Frequency",
    spec=R.specs.FreqGate.Frequency,
    formatter=Formatters.round(0.001)
  }

  scroll:push("")
  scroll:push("TODO:")
  scroll:push("Separate Linear FM input")

  params:set("fm_amount", 0.5)

  scroll:push("") -- TODO: Scroll bug

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
