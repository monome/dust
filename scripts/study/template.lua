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
engine.name = 'TestSine'

-- init function
init = function()
  -- print to command line
  print("template!")
  -- add log message
  norns.log.post("hello!")
  -- show engine commands available
    engine.list_commands()
  -- set engine params
  engine.hz(100)
  engine.amp(0.125)
  -- start timer
  c:start()
  -- clear grid, if it exists
  if g then
    g:all(0)
    g:refresh()
  end
  -- screen: turn on anti-alias
  screen.aa(1)
  screen.line_width(1.0)
end

-- make a variable
t = 0
-- make an array for storing
numbers = {0, 0, 0, 0, 0, 0, 0}
-- make a var, led brightness for grid
level = 5

-- encoder function
enc = function(n, delta)
  numbers[n] = numbers[n] + delta
  -- redraw screen
  redraw()
end

-- key function
key = function(n, z)
  numbers[n+3] = z
  -- redraw screen
  redraw()
end

-- screen redraw function
redraw = function()
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



-- set up a metro
c = metro[1]
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

-- grid key function
gridkey = function(x, y, state)
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
cleanup = function()
  numbers = nil
end
