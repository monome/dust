-- SHIFTY
--
-- Pitch and frequency shifter
--

engine.name = 'R'

local R = require 'jah/r'
local Control = require 'params/control'
local Formatters = require 'jah/formatters'
local Scroll = require 'jah/scroll'
local scroll = Scroll.new()

local function add_rcontrol(args)
  local control = Control.new(args.ref or args.name, args.name, args.spec, args.formatter)
  scroll:push(control)
  params:add {
    param=control,
    action=args.action or function(value) engine.set(args.ref or args.name, value) end
  }
end


function init()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("PitchShift", "PShift")
  engine.new("FreqShift", "FShift")
  engine.new("SoundOut", "SoundOut")

  engine.connect("LFO/Sine", "FreqShift/FM")
  engine.connect("LFO/Sine", "PitchShift/PitchRatioModulation")

  engine.connect("SoundIn/Left", "PitchShift/Left")
  engine.connect("SoundIn/Right", "PitchShift/Right")
  engine.connect("PitchShift/Left", "FreqShift/Left")
  engine.connect("PitchShift/Right", "FreqShift/Right")
  engine.connect("FreqShift/Left", "SoundOut/Left")
  engine.connect("FreqShift/Right", "SoundOut/Right")

  scroll:push("SHIFTY")
  scroll:push("")

  add_rcontrol {
    name="Freq Shift",
    ref="FreqShift.Frequency",
    spec=R.specs.FShift.Frequency
  }

  add_rcontrol {
    name="Pitch Ratio",
    ref="PitchShift.PitchRatio",
    formatter=Formatters.percentage,
    spec=R.specs.PShift.PitchRatio
  }

  add_rcontrol {
    name="Pitch Dispersion",
    ref="PitchShift.PitchDispersion",
    formatter=Formatters.percentage,
    spec=R.specs.PShift.PitchDispersion
  }

  add_rcontrol {
    name="Time Dispersion",
    ref="PitchShift.TimeDispersion",
    formatter=Formatters.percentage,
    spec=R.specs.PShift.TimeDispersion
  }

  add_rcontrol {
    name="LFO Rate",
    ref="LFO.Frequency",
    formatter=Formatters.round(0.001),
    spec=R.specs.MultiLFO.Frequency
  }

  add_rcontrol {
    name="LFO > Freq Shift",
    ref="FreqShift.FM",
    formatter=Formatters.percentage,
    spec=R.specs.FShift.FM
  }

  add_rcontrol {
    name="LFO > Pitch Ratio",
    ref="PitchShift.PitchRatioModulation",
    formatter=Formatters.percentage,
    spec=R.specs.PShift.PitchRatioModulation
  }

  scroll:push("") -- TODO

  params:read("jah/shifty.pset")

  params:bang()
end

function cleanup()
  params:write("jah/shifty.pset")
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
