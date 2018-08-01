-- etch
--
-- make line drawings
-- with encoders and keys
--
-- enc2/enc3: move pen
-- key2: pen down/add line
-- key3: pen up

engine.name = "PolySub"

zz = {}
p = {63, 31}
pen = false

function redraw()
  screen.clear()
  screen.level(10)
  for i=1,#zz do
    c = zz[i]
    if c == false then
      screen.stroke()
    else
      ((i == 1) and screen.move or screen.line)(c[1], c[2])
    end
  end
  if pen and #zz > 0 then
    screen.line(p[1], p[2])
  end
  screen.stroke()
  screen.level(pen and 15 or 5)
  screen.circle(p[1], p[2], 1)
  screen.stroke()
  screen.update()
end

function enc(n, d)
  if n == 2 then
    p[1] = p[1] + d/4
  end
  if n == 3 then
    p[2] = p[2] + d/4
  end
  redraw()
end

function key(n, z)
  if n == 2 and z == 1 then
    zz[#zz+1] = {p[1], p[2]}
    pen = true
  end
  if n == 3 and z == 1 then
    if pen then
      zz[#zz+1] = false
    end
    pen = false
  end
  redraw()
end