engine.name = 'TestSine'

local math = require 'math'

init = function()

   engine.amp(0.25)

   t = {}
   
   for i=1,10 do
      local m = metro[i]
      m.time = 0.01 * (i+1)
      m.callback = function(stage)
	 engine.hz((stage % 10)* 100 + 100)
      end      
      m:start()
      t[i] = true
   end

   function toggle(i) 
      if t[i] then
	 t[i] = false
	 metro[i]:stop()
      else
	 t[i] = true
	 local count = math.random(-1, 3)
	 print("new count: " .. count)
	 metro[i]:start(nil, count)
	 --metro[i]:start()
      end
   end

   for i = 11,20 do
      local m = metro[i]
      m.time = 0.125 * (i-9)      
      m.callback = function(stage)
	 print ("toggling " .. i-10)
	 toggle(i-10)
      end   
      m:start()	       
   end
   
end
