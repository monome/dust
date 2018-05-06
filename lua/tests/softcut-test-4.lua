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

local loop_start = {}
local loop_end = {}
local gpos = {1, 1, 1, 1}
  
local p_phase = {}

init = function()
  engine.list_commands()

  for i=1,4 do
     print(i)
     -- routing
     engine.adc_rec(1, i, 1.0)
     engine.adc_rec(2, i, 1.0)
     
     engine.play_dac(i, 1, 0.25)
     engine.play_dac(i, 2, 0.25)

     -- levels     
     engine.rec(i, 1)
     engine.pre(i, 0.75)
     engine.amp(i, 1)

     -- loop points
     loop_start[i] = i * 4
     loop_end[i] = loop_start[i] + 3.0 + (i*0.25)
     engine.loop_start(i, loop_start[i])
     engine.loop_end(i, loop_end[i])
     engine.pos(i, 1)
     engine.reset(i)
     
     -- kludge: small negative offset
     engine.offset(i, -10)

     -- start running
     engine.rec_on(i, 1)
     engine.start(i)

     engine.rec_lag(i, 1/16)
     engine.pre_lag(i, 1/16)
     engine.rate_lag(i, 1/16)
     
     engine.fade(i, 0.5)
       
     engine.quant(i, 0.25)
     p_phase[i] = poll.set('phase_quant_'..i, function(phase)
			      update_phase(i, phase)
     end)
     p_phase[i]:start()

  end

  -- poll the buffer duration
  local p_buf_dur = poll.set('buf_dur', function(dur) print("buffer duration: " .. dur) end)
  -- request an update immediately
  p_buf_dur:update() 
  
  if g ~= nil then g:all(0) end
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

update_phase = function(i, phase)
   -- print(phase)
   if g ~= nil then
      g:led(gpos[i], i, 0)
      gpos[i] = (phase - loop_start[i]) * 4 + 1
      if(gpos[i] > 16) then gpos[i] = 16 end
      g:led(gpos[i], i, 12)
      g:refresh()
   end
   
end

-- called by menu
redraw = function() screen_redraw() end
