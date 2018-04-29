-- simple softcut test
--
-- single head records and plays
-- grid shows current position
-- enc 2: speed
-- key 2: toggle recording
-- key 3: reset speed

local audio = require 'audio'
audio.monitor_off()

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
  engine.pre(1, 0.75)
  engine.amp(1, 1)

  -- loop points
  engine.loop_start(1, 1)
  engine.loop_end(1, 3.0)
  engine.pos(1, 1)
  engine.reset(1)
  
  -- kludge: small negative offset
  engine.offset(1, -10)

 -- start running
  engine.rec_on(1, 1)
  engine.start(1)

  engine.rec_lag(1, 0.125)
  engine.pre_lag(1, 0.125)

  -- poll the quantized phase (only fires when quantized phase changes)
  local p = poll.set('phase_quant_1', update_phase)
  p:start()
end

local rate = 1
enc = function(n, d)
   if n == 2 then
      rate = rate + (d * 0.0625)
      if rate > 4 then rate = 4 end
      if rate < -4 then rate = -4 end
      engine.rate(1, rate)
   end
end

local rec_state = 1
local pre_rec = 0.75
key = function(n, z)
   if n == 2 then
      if z > 0 then	 
	 rec_state = 1 - rec_state
	 if rec_state > 0 then 	    
	    engine.rec(1, 1)
	    engine.pre(1, pre_rec)
	 else
	    engine.rec(1, 0)
	    engine.pre(1, 1)
	 end
	 redraw_screen()
      end
   end
   if n == 3 then
      if z > 0 then
	 rate = 1
	 engine.rate(1, rate)
      end
   end
end

screen:level(4)
redraw_screen = function()
   screen.clear()
   screen.move(0, 0)
   if rec_state > 0 then
      screen.rect(0, 0, 128, 64)
      screen.fill()
   end
   screen.update()
end

-- phase argument is in samples - should fix this on SC side
local loop_start = 1
local gpos = 1
update_phase = function(phase)
   if g ~= nil then
      g:led(gpos, 1, 0)
      gpos = (phase / 48000 - loop_start) * 7.99       
      g:led(gpos, 1, 12)
      g:refresh()
   end
   
end
