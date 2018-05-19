engine.name = 'TestSine'

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
   end


   toggle = function(i) 
      if t[i] then
	 t[i] = false
	 metro[i]:stop()
      else
	 t[i] = true
	 metro[i]:start()
	 
      end
   end
end

for i = 11,20 do
            local m = metro[i]
      m.time = 0.01 * (i+1)
      m.callback = function(stage)
	 engine.hz((stage % 10)* 100 + 100)
      end
      
      m:start()	 

end
