-- shifty.
-- pitch / freq shifts
-- audio inputs
--
-- menu > parameters
--

local ControlSpec = require 'controlspec'
local Shift = require 'jah/shift'

engine.name = 'Shift'

function init()
  Shift.add_params()
  screen.line_width(1.0)
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("shifty")
  screen.update()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    params:delta("pitch_ratio", delta)
  elseif n == 3 then
    params:delta("freqshift_freq", delta)
  end
end

function key(n, z)
  if n == 2 and z == 1 then
  elseif n == 2 and z == 0 then
  end
end
