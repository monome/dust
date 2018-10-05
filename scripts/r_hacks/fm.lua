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
  engine.new("Osc1", "MultiOsc")
  engine.new("Osc2", "MultiOsc")
  engine.new("Osc3", "MultiOsc")
  engine.new("SoundOut", "SoundOut")

  engine.connect("Osc1/Sine", "Osc2/FM")
  engine.connect("Osc2/Sine", "SoundOut/Left")
  engine.connect("Osc2/Sine", "SoundOut/Right")

  scroll:push("FM example")
  scroll:push("")

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
    id="osc2_fm",
    name="Osc2.FM",
    spec=R.specs.MultiOsc.FM
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
