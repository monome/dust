-- curve
--
-- draw curves with
-- encoders and keys
--
-- key1: random curve
-- key2/key3: next/prev node
-- enc2/enc3: inc/dec x/y

engine.name = "PolyPerc"

xx = {0, 0, 0, 0}
yy = {0, 0, 0, 0}
nn = 1

function init()
  randomize()
end

function randomize()
  for i=1,4 do
    xx[i] = math.floor(math.random(128))
    yy[i] = math.floor(math.random(64))
  end
end

function redraw()
  screen.clear()
  for i=1,4 do
    screen.level((nn == i) and 5 or 2)
    screen.move(0, i*8)
    screen.text(xx[i] .. " ".. yy[i])
    screen.stroke()
    screen.circle(xx[i], yy[i], (nn == i) and 2 or 1)
    screen.stroke()
  end
  screen.level(15)
  screen.line_width(1)
  screen.move(xx[1],yy[1])
  screen.curve(xx[2], yy[2], xx[3], yy[3], xx[4], yy[4])
  screen.stroke()
  screen.update()
end

function enc(n,d)
  if n == 2 then
    xx[nn] = xx[nn] + d
  end
  if n == 3 then
    yy[nn] = yy[nn] + d
  end
  redraw()
end

function key(n,z)
  if z == 1 then
    if n == 1 then
      randomize()
    end
    if n == 2 then
      nn = nn - 1
      if nn < 1 then
        nn = 4
      end
    end
    if n == 3 then
      nn = nn + 1
      if nn > 4 then
        nn = 1
      end
    end
    redraw()
  end
end
