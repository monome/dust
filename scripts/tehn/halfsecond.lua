-- softcut test
-- half sec loop 75% decay

engine.name = 'SoftCut'

function init()
  engine.loop_start(1,0)
  engine.loop_end(1,0.5)
  engine.loop_on(1,1)
  engine.pre(1,0.75)
  engine.amp(1,1)
  engine.rec_on(1,1)
  engine.rec(1,1)
  engine.adc_rec(1,1,1)
  engine.adc_rec(1,2,1)
  engine.play_dac(1,1,1)
  engine.play_dac(1,2,1)
  engine.rate(1,1)
  engine.reset(1)
  engine.start(1)

  rec = 1
end

function redraw()
  screen.clear()
  screen.level(rec == 1 and 15 or 2)
  screen.move(10,10)
  screen.text("softcut")
  screen.update()
end

function key(n,z)
  if n==3 and z==1 then
    rec = 1 - rec
    engine.rec_on(1,rec)
    redraw()
  end
end

