-- 16sliders
--
-- step sequencing a mono sine
--
-- enc 2 = select step
-- enc 3 = tune step
-- key 2 = random walk
-- key 3 = mutate

local sliders = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local edit = 1
local accum = 1
local step = 0

engine.name = 'TestSine'

local k = metro[1]
k.count = -1
k.time = 0.1
k.callback = function(stage)
  step = (step + 1) % 16
  engine.hz(2^(sliders[step+1]/12) * 80)
  redraw()
end

function init()
  print("16sliders: loaded engine")
  engine.hz(100)
  engine.amp(0.1)
  k:start()
end

function enc(n, delta)
  if n == 2 then
    accum = (accum + delta) % 16
    edit = accum
  elseif n == 3 then
    sliders[edit+1] = sliders[edit+1] + delta
    if sliders[edit+1] > 32 then sliders[edit+1] = 32 end
    if sliders[edit+1] < 0 then sliders[edit+1] = 0 end
  end
  redraw()
end

function key(n, z)
  if n == 2 and z == 1 then
    sliders[1] = math.floor(math.random()*4)
    for i=2, 16 do
      sliders[i] = sliders[i-1]+math.floor(math.random()*9)-3
    end
    redraw()
  elseif n == 3 and z == 1 then
    for i=1, 16 do
      sliders[i] = sliders[i]+math.floor(math.random()*5)-2
    end
    redraw()
  end
end

function redraw()
  screen.aa(1)
  screen.line_width(1.0)
  screen.clear()

  for i=0, 15 do
    if i == edit then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.move(32+i*4, 48)
    screen.line(32+i*4, 46-sliders[i+1])
    screen.stroke()
  end

  screen.level(10)
  screen.move(32+step*4, 50)
  screen.line(32+step*4, 54)
  screen.stroke()

  screen.update()
end
