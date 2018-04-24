-- glut
--
-- granular thing
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
engine.name = 'Glut'

positions = {-1, -1, -1, -1, -1, -1, -1}
focus = 1

-- init function
init = function()
  engine.list_commands()
  -- set engine params
  engine.read(1, "glut/1.wav")
  engine.read(2, "glut/2.wav")
  engine.read(3, "glut/3.aif")
  engine.read(4, "glut/4.aif")
  -- start timer
  c:start()
  gridredraw()
end

-- set up a metro
c = metro[1]
-- count forever
c.count = -1
-- count interval to 1 second
c.time = 1
-- callback function on each count
c.callback = function(stage)
  redraw()
end

-- grid key function
gridkey = function(x, y, state)
  if state > 0 then
    -- set voice pos
    if y > 1 then
      local voice = y - 1
      positions[voice] = x
      engine.pos(voice, (x - 1)/ 16.0)
      engine.gate(voice, 1)
    else
      local voice = x
      positions[voice] = -1
      engine.gate(voice, 0)
    end
    gridredraw()
  end
end

enc = function(n, d)
  if n == 1 then print(1, d)
  elseif n == 2 then print(2, d)
  elseif n == 3 then print(3, d)
  end
  redraw()
end

gridredraw = function()
  if g == nil then
    return
  end

  g:all(0)
  for i=1, 16 do
    g:led(i, focus + 1, 3)
  end
  for i=1, 7 do
    if positions[i] > 0 then
      g:led(i, 1, 7)
      g:led(positions[i], i + 1, 15)
    end
  end
  g:refresh()
end

-- called on script quit, release memory
cleanup = function()
  positions = nil
end

