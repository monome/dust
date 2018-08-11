-- hello r

local ControlSpec = require 'controlspec'

engine.name = 'R'

function init()
  engine.new("TestGen", "TestGen")
  engine.new("Amplifier", "Amplifier")
  engine.new("SoundOut", "SoundOut")
  engine.connect("TestGen/Out", "Amplifier/In")
  engine.connect("Amplifier/Out", "SoundOut/Left")
  engine.connect("Amplifier/Out", "SoundOut/Right")

  params:add_control("TestGen.Frequency", ControlSpec.WIDEFREQ)
  params:set_action("TestGen.Frequency", function(value)
    engine.set("TestGen.Frequency", value)
  end)

  params:add_option("TestGen.Wave", {"sine", "noise"})
  params:set_action("TestGen.Wave", function(value)
    if value == 1 then
      engine.set("TestGen.Wave", 0)
    else
      engine.set("TestGen.Wave", 1)
    end
  end)

  engine.set("Amplifier.Level", 0.1)
end
