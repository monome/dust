local elca = require 'emb.elca'
--local grid = require 'grid'

local ca = elca.new()
local m = metro[1]

ca.state[1] = 1
ca.state[5] = 1
ca.state[8] = 1
ca.rule = 110

ca.bound_mode_l = elca.BOUND_WRAP
ca.bound_mode_r = elca.BOUND_WRAP
ca.bound_l = 1
ca.bound_r = 8


local history = {}
for i=1, 16 do
   local col = {}
   for j=1,8 do
      col[j] = 0
   end
   table.insert(history, col)
end

function gridredraw()
   if g == nil then return end
   for i=1, 16 do
      local col = history[i]
      for j=1,8 do
	 g:led(i, j, col[j])
      end
   end
end

m.callback = function(stage)
   ca:update()
   local col = ca:window(8)
   history[17] = col
   table.remove(history, 1)

   gridredraw()
   
   local str = ""
   for i=1,8 do      
      if col[i] > 0 then str = str .. "0" else str = str .. "." end
   end
   print(str)end

m.time = 0.125


engine.name = 'TestSine'
init = function()
   
   print("grid: ", g)
   m:start()
end
