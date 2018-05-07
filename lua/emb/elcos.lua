-- elementary cellular automata
-- makes oscs, hears voice
-- 
-- last column: change state
-- first column: set pitch from input
-- other columns: change rule
--
-- key 2 : clear state
-- key 3 : [TODO]
-- enc 2 : offset
-- enc 3 : rate

local elca = require 'emb.elca'
local audio = require 'audio'

local ca = elca.new() -- CA state
local seq = metro.alloc() -- main timer

local n = 8 -- length of window
local m = 16 -- length of history

local hzin = 55.0 -- current input pitch
local phz -- hz poll

local num_sines = 64
local offset = 0
local offset_max = num_sines - 8
local rule = 126

local dt = 0.125

engine.name = 'Sines'

ca.state[1] = 1
ca.state[5] = 1
ca.state[8] = 1
ca.rule = rule

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

key = function(n, z)
   print(n, z)
   if n == 2 and z > 0 then      
      ca:clear()      
   end
end

enc = function(n, z)
   if n == 2 then
      local newoff  = offset + z
      if newoff < 0 then newoff = 0 end
      if newoff > offset_max then newoff = offset_max end
      for i=offset,offset+8 do
	 if i < newoff or i > (newoff + 8) then
	    engine.amp(i, 0)
	 end
      end
      offset = newoff
      ca.offset = offset
   elseif n == 3 then
      dt = dt + (z * 0.01)
      if dt < 0.01 then dt = 0.01 end
      seq.time = dt
      for i=1,num_sines do 
	 engine.amplag(i, 0.5 * dt)
      end
   end
end

function refresh_grid_ca()
   if g == nil then return end
   local val
   for i=2, 16 do
      if i == 16 then val = 12 else val = 4 end
      local col = history[i]
      local z
      for j=1,8 do
         if col[j] > 0 then
	    z = val
	 else
	    z = 0
	 end
	 g:led(i, j, z)
	 if i == 16 then
	    -- fixme very bad structre to to this here!
	    engine.amp(j, amp)
	 end
      end
   end
   g:refresh()
end

function refresh_amp()
   local i = 16
   local col = history[i]
   local amp
   for j=1,8 do
      if col[j] > 0 then
	 amp =  0.0625
      else
	 z = 0
	 amp = 0
      end
      if i == 16 then
	 engine.amp(j + offset, amp)
      end
   end
end


gridkey = function(x, y, z)
   -- most recent row - set the state
   if x == 16 then      
      if z == 0 then return end
      y = y + offset
      if ca.state[y] > 0 then ca.state[y] = 0 else ca.state[y] = 1 end
   elseif x > 1 then      
      if z == 0 then return end
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
      refresh_grid_ca()
      refresh_amp()
   else
      if z > 0 then
	 set_hz(y)
      end
      g:led(1, y, z)
      g:refresh()
   end
end

set_hz = function(i)
   engine.hz(i + offset, hzin)
end


seq.callback = function(stage)
   ca:update()
   local col = ca:window(8)

   -- fixme: this mem managment is not good
   table.insert(history, col)
   table.remove(history, 1)

   refresh_grid_ca()
   refresh_amp()

   -- check GC
   local kb = math.floor(collectgarbage("count"))
   local str = "used: " .. kb .. " kB"
   
end

init = function()
   
   -- wrapped harmonix
   for i=1,num_sines do
      local hz = 55 * (i+3)
      while hz > 1000 do hz = hz / 2 end
      print(hz)
      engine.hz(i, hz)
      -- without this sleep, some of the messages seem to get lost :/
      usleep(10000)
   end

   -- get the pitch input
   audio.pitch_on()
   phz = poll.set('pitch_in_l', function(f) hzin = f end)
   phz:start()
   
   seq.time = 0.125
   seq:start()
end

function copy_history(newcol)
   for x in 1,n do
   end
end
