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

-- state variables

local rate = 1
local rec_state = 1
local pre_rec = 0.75

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

  engine.rec_lag(1, 1/16)
  engine.pre_lag(1, 1/16)
  engine.rate_lag(1, 1/16)
  
  engine.fade(1, 0.5)
  
  -- poll the quantized phase (only fires when quantized phase changes)
  local p_phase = poll.set('phase_quant_1', update_phase)
  p_phase:start()

  -- poll the buffer duration
  local p_buf_dur = poll.set('buf_dur', function(dur) print("buffer duration: " .. dur) end)
  -- request an update immediately
  p_buf_dur:update() 
  
  if g ~= nil then g:all(0) end
  
  -- why doesn't this work here?
  screen_redraw()

end

enc = function(n, d)
   if n == 2 then
      rate = rate + (d / 16)
      if rate > 4 then rate = 4 end
      if rate < -4 then rate = -4 end
      engine.rate(1, rate)
      screen_redraw()
   end
   if n == 3 then
      pre_rec = pre_rec + (d / 16)
      if pre_rec < 0 then pre_rec = 0 end
      if pre_rec > 1 then pre_rec = 1 end
      engine.pre(1, pre_rec)
      screen_redraw()
   end
end

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
	 screen_redraw()
      end
   end
   if n == 3 then
      if z > 0 then
	 rate = 1
	 engine.rate(1, rate)
	 screen_redraw()
      end
   end
end

screen_redraw = function()
   screen.clear()
   screen.level(10)
   screen.move(40, 20)
   
   if rec_state > 0 then
      screen.text("rec: on")
      screen.move(1, 1)
      screen.rect(1, 1, 10, 10)
      screen.fill()
   else 
      screen.text("rec: off")
   end
   
   screen.move(40, 30)
   screen.text("pre: " .. pre_rec)
   screen.move(40, 40)
   screen.text("rate: " .. rate)

   screen.update()
end

-- phase argument is in samples - should fix this on SC side
local loop_start = 1
local gpos = 1
update_phase = function(phase)
   -- print(phase)
   if g ~= nil then
      g:led(gpos, 1, 0)
      gpos = (phase - loop_start) * 8 + 1
      if(gpos > 16) then gpos = 16 end
      g:led(gpos, 1, 12)
      g:refresh()
   end
   
end


-- why doesn't this work here either??
screen_redraw()
