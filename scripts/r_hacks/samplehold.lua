-- SAMPLEHOLD
--
-- Sample and hold example
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
  engine.new("Noise", "Noise")
  engine.new("LFO", "MultiLFO")
  engine.new("SampleHold", "SampHold")
  engine.new("Osc", "SineOsc")
  engine.new("SoundOut", "SoundOut")

  engine.connect("Noise/Out", "SampleHold/In")
  engine.connect("LFO/Pulse", "SampleHold/Trig")
  engine.connect("SampleHold/Out", "Osc/FM")

  engine.connect("Osc/Out", "SoundOut/Left")
  engine.connect("Osc/Out", "SoundOut/Right")

  engine.set("LFO.Frequency", 8)
  engine.set("Osc.FM", 0.2)

  scroll:push("Sample and hold example")
  scroll:push("")

  add_rcontrol {
    id="osc_fm",
    name="Osc.FM",
    spec=R.specs.SineOsc.FM
  }

  scroll:push("") -- TODO: Scroll bug

  params:set("osc_fm", 0.3)
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
