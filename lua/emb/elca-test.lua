-- elementary cellular automata
-- 
-- last column: change state
-- earlier columns: change rule
--
-- key 2 : stop
-- key 3 : start
-- enc 2 : rate
--

local elca = require 'emb.elca'

local ca = elca.new() -- CA state
local seq = metro.alloc() -- main timer

local n = 8 -- length of window
local m = 16 -- length of history


engine.name = 'Sines'

ca.state[1] = 1
ca.state[5] = 1
ca.state[8] = 1
ca.rule = 126

ca.bound_mode_l = elca.BOUND_WRAP
ca.bound_mode_r = elca.BOUND_LOW
ca.bound_l = 1
ca.bound_r = elca.NUM_STATES

local history = {}
for i=1,m do
   local col = {}
   for j=1,n do
      col[j] = 0
   end
   table.insert(history, col)
end

function refresh()
   if g == nil then return end
   local val
   for i=1, 16 do
      if i == 16 then val = 12 else val = 4 end
      local col = history[i]
      local z, amp
      for j=1,8 do
         if col[j] > 0 then
	    z = val
	    amp =  0.0625
	 else
	    z = 0
	    amp = 0
	 end
	 g:led(i, j, z)
	 if i == 16 then
	    -- fixme very bad structre to to this here
	    engine.amp(j, amp)
	 end
      end
   end
   g:refresh()
end

gridkey = function(x, y, z)
   if z == 0 then return end
   if x < 2 then return end
   -- most recent row - set the state
   if x == 16 then
      if ca.state[y] > 0 then ca.state[y] = 0 else ca.state[y] = 1 end
   else      
      -- earlier rows - change the rule such that it would have produced a different value
      -- (and change the state too)
      local col = history[x-1]
      local l, r
      if y == 1 then l = col[8] else l = col[y-1] end
      if y == 8 then r = col[1] else r = col[y+1] end
      local c = col[y]
      local val
      if history[x][y] > 0  then val = 0 else val = 1 end
      history[x][y] = val
      ca.state[y] = c
      ca:set_rule_by_state(history[x][y], l, c, r)
      print("rule by state: ", history[x][y], l, c, r)
      print("new rule: ", ca.rule)
      refresh()
   end
end


seq.callback = function(stage)
   ca:update()
   local col = ca:window(8)

   -- fixme: this mem managment is not good
   table.insert(history, col)
   table.remove(history, 1)

   refresh()

   -- check GC
   local kb = math.floor(collectgarbage("count"))
   local str = "used: " .. kb .. " kB"
   
   -- current menu/script redrawing means that actually doing this will break the menu
   --[[
   screen.clear()
   screen.move(10, 10)
   screen.text(str)
   screen.update()
   --]]

   
end

--engine.name = 'TestSine'

init = function()
   
   -- wrapped harmonix
   for i=1,8 do
      local hz = 55 * (i+3)
      while hz > 1000 do hz = hz / 2 end
      print(hz)
      engine.hz(i, hz)
      -- without this sleep, some of the messages seem to get lost
      usleep(10000)
   end
   
   seq.time = 0.125
   seq:start()
end

function copy_history(newcol)
   for x in 1,n do
   end
end
