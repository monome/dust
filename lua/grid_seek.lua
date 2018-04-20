-- test grid sequencer
--
-- knob 1 = tempo
-- knob 2 = filter
-- knob 3 = decay
-- key 2 = random sequence
-- key 3 = random pulsewidth

engine.name = 'PolyPerc'

init = function()
  print("grid/seek")
  engine.cutoff(50*2^(cutoff/12))
  engine.release(0.1*2^(release/12))
  engine.amp(0.5)

  params:add_number("tempo",40,300,80)
  params:set_action("tempo", function(n) 
    t.time = 15/n
  end)

  t = metro[1]
  t.time = 15/params:get("tempo") 

  t.callback = function(stage)
    pos = pos + 1
    if pos == 17 then pos = 1 end
    if steps[pos] > 0 then engine.hz(freqs[9-steps[pos]]) end
    if g ~= nil then
      gridredraw()
    end
    redraw()
  end

  t:start()
end

gridkey = function(x, y, state)
  if state > 0 then
    if steps[x] == y then
      steps[x] = 0
    else
      steps[x] = y
    end
  end
  g:refresh()
end

pos = 1

steps = {}
notes = {0, 2, 3, 5, 7, 9, 10, 12}
freqs = {}

for i=1, 8 do freqs[i] = 100*2^(notes[i]/12) end
for i=1, 16 do steps[i] = math.floor(math.random()*8) end

gridredraw = function()
  g:all(0)
  for x = 1, 16 do
    if steps[x] > 0 then g:led(x, steps[x], 5) end
  end
  if steps[pos] > 0 then
    g:led(pos, steps[pos], 15)
  else
    g:led(pos, 1, 3)
  end
  g:refresh();
end

cutoff = 30
release = 20

enc = function(n, delta)
  if n == 1 then
    params:delta("tempo",delta)
  elseif n == 2 then
    cutoff = math.min(100, math.max(0, cutoff+delta))
    engine.cutoff(50*2^(cutoff/12))
  elseif n == 3 then
    release = math.min(60, math.max(0, release+delta))
    engine.release(0.1*2^(release/12))
  end

  redraw()
end

key = function(n,z)
  if n == 2 and z == 1 then
    for i=1, 16 do steps[i] = math.floor(math.random()*8) end
  elseif n == 3 and z == 1 then
    engine.pw(math.random()*1)
  end
end

redraw = function()
  screen.clear()
  screen.line_width(1)
  screen.level(15)
  screen.move(0,40)
  screen.line(params:get("tempo")-38,40)
  screen.stroke()
  screen.move(0,38)
  screen.text(params:get("tempo"))
  screen.move(0, 10)
  screen.text("cutoff > "..string.format('%.1f', (50*2^(cutoff/12))))
  screen.move(0, 20)
  screen.text("release > "..string.format('%.3f', 0.1*2^(release/12)))
  screen.move(0, 60)
  screen.text("step > "..pos)
  screen.update()
end
