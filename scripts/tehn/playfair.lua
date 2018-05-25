-- euclidean drummer
--
-- enc2 = density
-- enc3 = length
-- key2 = reset phase
-- key3 = select
--
-- key1 = ALT
-- ----------
-- enc2 = select pattern
-- key2 = store pattern
-- key3 = load pattern

require 'er'

engine.name = 'Ack'

local ack = require 'jah/ack'

local reset = false
local alt = false
local track_edit = 1

local track = {}
for i=1,4 do
  track[i] = {}
  track[i].k = 0
  track[i].n = 9 - i
  track[i].pos = 1
  track[i].s = {}
end

local function reer(i)
  if track[i].k == 0 then
    for n=1,32 do track[i].s[n] = false end
  else
    track[i].s = er(track[i].k,track[i].n)
  end
end

local function trig()
  for i=1,4 do
    if track[i].s[track[i].pos] then
      engine.trig(i-1)
    end
  end
end

function init()
  for i=1,4 do reer(i) end

  screen.line_width(1)
  params:add_number("bpm",1,480,160)
  params:set_action("bpm",function(x) t.time = 15/x end)

  for channel=1,4 do
    ack.add_channel_params(channel)
  end

  t = metro.alloc()
  t.count = -1
  t.time = 15/params:get("bpm")
  t.callback = function()
    if reset then
      for i=1,4 do track[i].pos = 1 end
      reset = false
    else
      for i=1,4 do track[i].pos = (track[i].pos % track[i].n) + 1 end 
    end
    trig()
    redraw()
  end
  t:start()
  
  params:read("playfair.pset")
  params:bang()
end

function key(n,z)
  if n==1 then alt = z
  elseif n==2 and z==1 then reset = true
  elseif n==3 and z==1 then track_edit = (track_edit % 4) + 1 end
  redraw() 
end

function enc(n,d) 
  if n==1 then
    params:delta("bpm",d)
  elseif n == 2 then
    track[track_edit].k = util.clamp(track[track_edit].k+d,0,track[track_edit].n)
  elseif n==3 then 
    track[track_edit].n = util.clamp(track[track_edit].n+d,1,32)
    track[track_edit].k = util.clamp(track[track_edit].k,0,track[track_edit].n)
  end
  reer(track_edit)
  redraw()
end

function redraw()
  screen.aa(0)
  screen.clear()
  screen.move(0,10)
  screen.level(4)
  screen.text(params:get("bpm"))
  for i=1,4 do
    screen.level((i == track_edit) and 15 or 4)
    screen.move(5, i*10 + 10)
    screen.text_center(track[i].k)
    screen.move(20,i*10 + 10)
    screen.text_center(track[i].n)

    for x=1,track[i].n do
      screen.level(track[i].pos==x and 15 or 2)
      screen.move(x*3 + 30, i*10 + 10)
      if track[i].s[x] then
        screen.line_rel(0,-8)
      else
        screen.line_rel(0,-2)
      end 
      screen.stroke() 
    end
  end
  screen.update()
end
