-- softcut test
-- half sec loop 75% decay
--
-- ENC1 to toggle HOLD

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

  hold = 0
end

function redraw()
  screen.clear()
  screen.level(hold == 1 and 15 or 2)
  screen.move(10,50)
  screen.text("halfsecond")
  screen.update()
end

function key(n,z)
  if n==3 and z==1 then
    hold = 1 - hold
    engine.pre(1,hold==1 and 1 or 0.75)
    engine.rec(1,hold==1 and 0 or 1)
    redraw()
  end
end

