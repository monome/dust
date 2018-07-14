-- patterning
-- norns study 2

engine.name = "PolyPerc"

function init()
  engine.release(3)
  notes = {}
  selected = {}
  
  --build a scale, clear selected notes
  for m = 1,5 do
    notes[m] = {}
    selected[m] = {}
    for n = 1,5 do
      notes[m][n] = 55 * 2^((m*12+n*2)/12)
      selected[m][n] = 0
    end
  end
  
  light = 0
  number = 3
  
end
  
  
function redraw()
  screen.clear()
  
  for m = 1,5 do
    for n = 1,5 do
      screen.rect(0.5+m*9, 0.5+n*9, 6, 6)
      l = 2
      if selected[m][n] == 1 then
        l = l + 3 + light
      end
      screen.level(l)
      screen.stroke()
    end
  end
  
  screen.move(10, 60)
  screen.text(number)
  screen.update()
end

function key(n, z)
  if n == 2 and z== 1 then
    -- clear selected
    for x = 1,5 do
      for y = 1,5 do
        selected[x][y] = 0
      end
    end
    
    -- choose new random notes
    for i = 1,number do
      selected[math.random(5)][math.random(5)] = 1
    end
    
  elseif n == 3 then
    -- find notes to play
    if z == 1 then
      for x = 1,5 do
        for y = 1,5 do
          if selected[x][y] == 1 then
            engine.hz(notes[x][y])
          end
        end
      end
      light = 7
    else
      light = 0
    end
  end
    
  redraw()
end

function enc(n, d)
  if n == 3 then
    -- clamp number of notes from 1 to 4
    number = math.min(4, (math.max(number + d, 1)))
  end
  redraw()
end