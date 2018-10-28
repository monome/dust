-- TESTGEN
--
-- The most basic R example
--

local ControlSpec = require 'controlspec'

engine.name = 'R'

function init()
  engine.new("TestGen", "TestGen")
  engine.new("SoundOut", "SoundOut")
  engine.connect("TestGen/Out", "SoundOut/Left")
  engine.connect("TestGen/Out", "SoundOut/Right")

  params:add_option("wave", "TestGen.Wave", {"Sine", "Noise"})
  params:set_action("wave", function(value)
    if value == 1 then
      engine.set("TestGen.Wave", 0)
    else
      engine.set("TestGen.Wave", 1)
    end
  end)

  params:add_control("frequency", "TestGen.Frequency", ControlSpec.new(10, 20000, 'exp', 0, 440, "Hz"))
  params:set_action("frequency", function(value)
    engine.set("TestGen.Frequency", value)
  end)

  params:add_control("amplitude", "TestGen.Amplitude", ControlSpec.DB)
  params:set_action("amplitude", function(value)
    engine.set("TestGen.Amplitude", value)
  end)
  params:set("amplitude", -10)

  params:bang()
end

function redraw()
  screen.font_size(8)
  screen.clear()
  screen.level(15)
  screen.move(0, 8)
  screen.text("TestGen > SoundOut")

  screen.move(0, 24)
  screen.text("Wave: "..params:string("wave"))
  screen.move(0, 34)
  screen.text("Frequency: "..params:string("frequency"))
  screen.update()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    params:delta("wave", delta)
    redraw()
  elseif n == 3 then
    params:delta("frequency", delta)
    redraw()
  end
end
