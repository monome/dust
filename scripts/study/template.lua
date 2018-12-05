-- TEMPLATE 1.0.0
-- http://monome.org
-- 
-- a code example showing the
-- basic functions and how to
-- use them.
--
-- see additional documentation
-- at...
--
-- ////////
-- ////
-- //////
-- /////////////
-- //
-- ///////
-- ///
-- /

-- specify dsp engine to load:
engine.name = 'TestFilter'

-- make a variable
local t = 0
-- make an array for storing
local numbers = {0, 0, 0, 0, 0, 0, 0}
-- make a var, led brightness for grid
local level = 5

-- set up a metro
local c = metro[1]
-- count forever
c.count = -1
-- count interval to 1 second
c.time = 1
-- callback function on each count
c.callback = function(stage)
  t = t + 1
  norns.log.post("tick "..t)
  redraw()
end

-- init function
function init()
  -- print to command line
  print("template!")
  -- add log message
  norns.log.post("hello!")
  -- show engine commands available
  engine.list_commands()
  -- set engine params
  engine.hz(700)
  -- start timer
  c:start()
end

-- encoder function
function enc(n, delta)
  numbers[n] = numbers[n] + delta
  -- redraw screen
  redraw()
end

-- key function
function key(n, z)
  numbers[n+3] = z
  -- redraw screen
  redraw()
end

-- screen redraw function
function redraw()
  -- screen: turn on anti-alias
  screen.aa(1)
  screen.line_width(1.0)
  -- clear screen
  screen.clear()
  -- set pixel brightness (0-15)
  screen.level(15)

  for i=1, 6 do
    -- move cursor
    screen.move(0, i*8-1)
    -- draw text
    screen.text("> "..numbers[i])
  end

  -- show timer
  screen.move(0, 63)
  screen.text("> "..t)

  -- refresh screen
  screen.update()
end

-- grid key function
function gridkey(x, y, state)
  if state > 0 then
    -- turn on led
    g:led(x, y, level)
  else
    -- turn off led
    g:led(x, y, 0)
  end
  -- refresh grid leds
  g:refresh()
end

-- called on script quit, release memory
function cleanup ()
  numbers = nil
end
