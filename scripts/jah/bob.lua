-- bob.
-- moog lowpass filter
--

local Bob = require 'jah/bob'

engine.name = 'Bob'

function init()
  Bob.add_params()
  params:read("jah/bob.pset")
  screen.line_width(1.0)
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("bob")
  screen.move(0, 24)
  screen.text("cutoff: "..params:string("cutoff"))
  screen.move(0, 32)
  screen.text("resonance: "..params:string("resonance"))
  screen.update()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    params:delta("cutoff", delta)
    redraw()
  elseif n == 3 then
    params:delta("resonance", delta)
    redraw()
  end
end

function cleanup()
  params:write("jah/bob.pset")
end
