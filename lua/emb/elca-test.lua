-- elementary cellular automata
-- 
-- last column: change state
-- earlier columns: change rule
--
-- key 2 : stop
-- key 3 : start
-- enc 2 : rate
--
--- TODO: sounds...?

local elca = require 'emb.elca'

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
   local val
   for i=1, 16 do
   if i == 16 then val = 12 else val = 4 end
      local col = history[i]
      local z
      for j=1,8 do
         if col[j] > 0 then z = val else z = 0 end
	 --g:led(i, j, col[j])
	 g:led(i, j, z)
      end
   end
   g:refresh()
end

gridkey = function(x, y, z)
   if x < 2 then return end
   -- most recent row - set the state
   if x == 16 then
      if ca.state[y] > 0 then ca.state[y] = 0 else ca.state[y] = 1 end
   -- earlier rows - change the rule such that it would have produced a different value
   -- (and change the state too)
   else
      local col = history[x-1]
      local l
      if y == 1 then l = col[8] else l = col[y-1] end
      local r
      if y == 8 then r = col[1] else r = col[y+1] end
      local c = col[y]
      local val
      if history[x][y] > 0  then val = 0 else val = 1 end
      history[x][y] = val
      ca.state[y] = c
      ca:set_rule_by_state(history[x][y], l, c, r)
      gridredraw()
   end
end

key = function(n,z)
  if n == 2 and z == 1 then
    m:stop()
  elseif n == 3 and z == 1 then
    m:start()
  end
end

enc = function(n, d)
  if n == 2 then
    local t = m.time
    m.time = util.clamp(t + d/100, 0.01, 1)
  end
end


m.callback = function(stage)
   ca:update()
   local col = ca:window(8)
   table.insert(history, col)
   table.remove(history, 1)

   gridredraw()

   --[[
   local str = ""
   for i=1,8 do      
      if col[i] > 0 then str = str .. "0" else str = str .. "." end
   end
   print(str)
   --]]
   
end

m.time = 0.125


engine.name = 'TestSine'
init = function() 
   print("grid: ", g)
   m:start()
end
