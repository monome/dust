-- just loops
--
-- key 2: rec/play, set current loop
-- press to record next loop,
-- release to play
-- if loop is already playing, overdub
--
-- e1: volume
-- e2: current loop start
-- e2: current loop end
--
-- key 3: modifier
-- + e2: rate
-- + e3: change current
-- + k2: stop current

--------------------
--- state variables

-- current loops
local current = 1
-- state of loops
local state = {}
-- table of phase polls
local phase_poll = {}

-- timer and flag for regular screen updates
local draw_timer = metro[1]
local dirty = false
-- number of loops
local n = 3
-- index of record head
local irec = 4
-- for convenience
local e = engine 

------------------
-- initialization
engine.name = 'SoftCut'

init = function()
   init_state()
   init_polls()
   init_draw()
end

function init_state() 
   for i=1,4 do
      state[i] = { loop_start=0, loop_end=2, playing=false, rate=1, pos = 0}
   end
end

function init_polls()
   for i=1,4 do
      local fn = function(pos)
	 state[i].pos = pos
	 dirty = true
      end
      phase_poll[i] = poll.set("phase_"..i, fn)
   end
end

function init_draw()
   draw_timer.time = 0.05
   draw_timer.callback = function()
      if dirty then screen_draw() dirty = false
   end
   draw_timer:start()
end

---------------------
-- state change

function select_next()
   current = current + 1
   if current > 4 then current = 1 end
end

-- start recording current selection
function start_record()
   local s = state[current]
   engine.sync(irec, current)
end

-- stop recording current selection
function stop_record()
   local s = state[current]
   if s.playing then
   else
      s.playing = true
      e.pos(current, s.start)
      e.reset(current)
   end
end

   
--------------------
--- screen drawing

function screen_draw()
end

function screen_draw_current()
end

function screen_draw_current()
end

---------------------
--- assign keys, encs

key = function(n, 1)
