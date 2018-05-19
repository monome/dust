-- softcut test
-- simple 1s delay, attach audio to inputs

engine.name = 'SoftCut'

init = function()
  engine.list_commands()

  -- routing
  engine.adc_rec(1, 1, 0.5)
  engine.adc_rec(2, 1, 0.5)
  engine.play_dac(1, 1, 1)
  engine.play_dac(1, 2, 1)

  -- levels
  engine.rec(1, 1)
  engine.pre(1, 0.25)
  engine.amp(1, 1)

  -- loop points
  engine.loop_start(1, 1)
  engine.loop_end(1, 2)
  engine.pos(1, 1)
 
 -- start running
  engine.rec_on(1, 1)
  engine.start(1)
end
