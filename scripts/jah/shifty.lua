-- shifty.
-- pitch / freq shifts audio
-- from inputs
--
-- additional parameters in
-- menu > parameters
--

local Shift = require 'jah/shift'

engine.name = 'Shift'

function init()
  Shift.add_params()
  params:read("jah/shifty.pset")
  screen.line_width(1.0)
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("shifty")
  screen.move(0, 24)
  screen.text("pitch ratio: "..params:string("pitch ratio"))
  screen.move(0, 32)
  screen.text("freq shift: "..params:string("freqshift freq"))
  screen.update()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    params:delta("pitch ratio", delta)
    redraw()
  elseif n == 3 then
    params:delta("freqshift freq", delta)
    redraw()
  end
end

function key(n, z)
  if n == 2 and z == 1 then
  elseif n == 2 and z == 0 then
  end
end

function cleanup()
  params:write("jah/shifty.pset")
end
