-- SQUARE
--
-- Square wave oscillator
-- 
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
  engine.new("Osc", "PulseOsc")
  engine.new("SoundOut", "SoundOut")

  engine.connect("Osc/Out", "SoundOut/Left")
  engine.connect("Osc/Out", "SoundOut/Right")

  scroll:push("Square wave oscillator")
  scroll:push("")

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

  scroll:push("") -- TODO: scroll bug

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
