local metro = require 'metro'

local m1, m2, m3, m4


init = function()
   
   m1 = metro.alloc(function() print("bang1 (default)") end)

   m1:start()
   print("m1 id: ", m1.id)

   m2 = metro.alloc(function() print("bang2 (faster)") end, 0.15)
   m2:start()
   print("m2 id: ", m2.id)
      
   m3 = metro.alloc(function() print("bang3 (fast, five times)") end, 0.25, 5)
   m3:start()
   print("m3 id: ", m3.id)

   m4 = metro.alloc()
   m4:start() -- no callback set; nothing happens.
   print("m4 id: ", m4.id)
end
