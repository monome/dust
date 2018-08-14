engine.name = 'SoftCut'

-- dofile("loops-params.lua")

init = function()

   print("init")
   
   -- voice 1: a loop
   engine.rec(1, 1)

   engine.pre(1, 0.75)
   engine.amp(1, 1)
   
   engine.rec_on(1, 1)
   engine.loop_on(1, 1)
   
   engine.play_dac(1, 1, 1)
   engine.play_dac(1, 2, 1)
   engine.adc_rec(1, 1, 0.5)
   engine.adc_rec(2, 1, 0.5)

   engine.loop_start(1, 1)
   engine.loop_end(1, 5)
   engine.pos(1, 4)
   engine.reset(1)
   engine.start(1)

   engine.offset(1, -10)

   --- voice 2: resample voice 1
   engine.play_rec(1, 2, 1)   
   engine.play_dac(2, 1, 1)
   engine.play_dac(2, 2, 1)
   
   engine.rec(2, 1)
   engine.pre(2, 0.75)
   engine.amp(2, 1)
   engine.rec_on(2, 1)
   
   engine.loop_on(2, 1)
   engine.loop_start(2, 6)
   engine.loop_end(2, 6.4)
   
   engine.pos(2, 6)
   engine.reset(2)
   engine.start(2)

   engine.offset(2, -10)
   
   --- voice 3: resample voice 2
   engine.play_rec(2, 3, 1)   
   engine.play_dac(3, 1, 1)
   engine.play_dac(3, 2, 1)
   
   engine.rec(3, 1)
   engine.pre(3, 0.5)
   engine.amp(3, 1)
   engine.rec_on(3, 1)
   
   engine.loop_on(3, 1)
   engine.loop_start(3, 8)
   engine.loop_end(3, 8.25)
   
   engine.pos(3, 8.1)
   engine.reset(3)
   engine.start(3)

   
   engine.offset(3, -10)

   
   --- voice 3: resample voice 2
   engine.play_rec(2, 3, 1)   
   engine.play_dac(3, 1, 1)
   engine.play_dac(3, 2, 1)
   
   engine.rec(3, 1)
   engine.pre(3, 0.5)
   engine.amp(3, 1)
   engine.rec_on(3, 1)
   
   engine.loop_on(3, 1)
   engine.loop_start(3, 8)
   engine.loop_end(3, 8.25)
   
   engine.pos(3, 8.1)
   engine.reset(3)
   engine.start(3)


   --- voice 4: short loop recording over voice 1's region
   --- this should be the ducking source
   engine.adc_rec(1, 4, 1)
   engine.rec(4, 1)
   engine.pre(4, 0.75)
   engine.rec_on(4, 1)
   
   engine.loop_on(4, 1)
   engine.loop_start(4, 2)
   engine.loop_end(4, 3.2)
   
   engine.pos(4, 2)
   engine.reset(4)
   engine.start(4)
   
   engine.offset(4, -10)
   
end

local rate1_seq = metro.alloc()

local x = 0.7
local a = 3.77
local r = 1

rate1_seq.callback =function(stage)
   x = a*x*x*x + (1-a)*x
   -- r = math.pow(2, math.floor(x))
   if x ~= 0 then
      r = math.floor(x * 16) * 0.25
   end
   engine.rate(1, r)
end

key = function(n, z)
   if n == 2 then
      if z > 0 then 
	 rate1_seq:start()
      else
	 rate1_seq:stop()	 
	 engine.rate(1, 1)
      end
   end
end
