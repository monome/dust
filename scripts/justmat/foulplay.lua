-- euclidean instrument with
-- probability.
-- ----------
-- based on playfair
-- ----------
-- 
-- enc1 = cycle through 
--         the tracks.
-- enc2 = set the number
--         of trigs.
-- enc3 = set the number 
--         of steps.
-- key2 = start and stop the
--         clock.  
--
-- ----------
-- holding key1 will bring up the 
-- track edit screen.
-- ----------
-- track edit 
--
-- encoders 1-3 map to 
-- parameters 1-3. 
-- 
-- key2 = advance to the 
--         next track.
-- key3 = advance to the
--         next page.
--
-- ----------
-- holding key3 will bring up the
-- global edit screen.
-- -----------
-- global edit
--
-- enc1 = set the mix volume
-- enc3 = set bpm
-- key2 = reset the phase of 
--         all tracks.
--

require 'er'

engine.name = 'Ack'

local ack = require 'jah/ack'

local reset = false
local mode = 0                                                                -- 0 == regular, 1 == track edit, 2 == global edit 
local page = 0
local track_edit = 1
local stopped = 0

local midi_clock_ticks = 0                                                   
local midi_device

local track = {}

for i=1, 8 do
  track[i] = {}
  track[i].k = 0
  track[i].n = 16
  track[i].pos = 1
  track[i].s = {}
  track[i].prob = 100                                                         
end

local function reer(i)
  if track[i].k == 0 then
    for n=1,32 do track[i].s[n] = false end
  else
    track[i].s = er(track[i].k,track[i].n)
  end
end

local function trig()
  for i=1,8 do
    if track[i].s[track[i].pos] then
      if math.random(100) <= track[i].prob then                               -- for per track probability
        engine.trig(i-1)
      end
    end
  end
end

function init()
  for i=1, 8 do reer(i) end

  screen.line_width(1)
  params:add_option("midi_sync",{"off","on"})
  params:add_number("bpm",1,480,160)
  params:set_action("bpm",function(x) t.time = 60/24/x end)

  ack.add_params()
  
  midi_clock_ticks = 0
  
  t = metro.alloc()
  t.count = -1
  t.time = 60/24/params:get("bpm")
  t.callback = function()
    if midi_device and params:get("midi_sync")==2 then midi.send(midi_device, {248}) end
    
    if midi_clock_ticks==0 then
      if reset then
        for i=1, 8 do track[i].pos = 1 end
        reset = false
      else
        for i=1, 8 do track[i].pos = (track[i].pos % track[i].n) + 1 end 
      end
    trig()
    redraw()
    end
    
    if midi_clock_ticks==5 then
      midi_clock_ticks = 0
    else
      midi_clock_ticks = midi_clock_ticks + 1
    end
  end  
  t:start()
params:read("justmat/foulplay.pset")
params:bang()
end

function key(n,z)
  if n==1 then mode = z end                                                   -- modes all day
  if n==3 and z==1 and mode==1 then
    page = (page + 1) % 3
  elseif n==3 and z==1 and mode==0 then
    mode = 2
  elseif n==3 and mode==2 then
    mode = 0
  end
  
  if mode==2 then                                                             -- GLOBAL EDIT
    if n==2 and z==1 then                                                     -- phase reset
      reset = true
    end
  end 
  
  if mode==1 then                                                             -- TRACK EDIT
    if n==2 and z==1 then                                                     -- track selection in edit mode
      track_edit = (track_edit % 8) + 1
    end  
  end 
  
  if mode==0 then                                                             -- REGULAR
    if n==2 and z==1 then                                                     -- stop/start
      if stopped==0 then
        t:stop()
        stopped = 1
      elseif stopped==1 then
        t:start()
        stopped = 0
      end
    end
  end
  redraw()
end

function enc(n,d) 
  if mode==1  and page==0 then                                                -- TRACK EDIT 
    if n==1 then                                                              -- track volume
      params:delta(track_edit .. ": vol", d)
    elseif n==2 then                                                          -- volume envelope release time
      params:delta(track_edit .. ": vol env rel", d)        
    elseif n==3 then                                                          -- trig prob 
      track[track_edit].prob = util.clamp(d + track[track_edit].prob, 1, 100)
    end
  
  elseif mode==1 and page==1 then
    if n==1 then                                                              -- sample playback speed
      params:delta(track_edit .. ": speed", d)
    elseif n==2 then                                                          -- sample start position
      params:delta(track_edit .. ": start pos", d)             
    elseif n==3 then                                                          -- sample end position
      params:delta(track_edit .. ": end pos", d)
    end 
  
  elseif mode==1 and page==2 then
    if n==1 then                                                              -- filter cutoff
      params:delta(track_edit .. ": filter cutoff", d)
    elseif n==2 then                                                          -- delay send
      params:delta(track_edit .. ": delay send", d)
    elseif n==3 then                                                          -- reverb send
      params:delta(track_edit .. ": reverb send", d)
    end  
    
  elseif mode==2 then                                                         -- GLOBAL EDIT 
    if n==1 then                                                              -- mix volume
      mix:delta("output", d)
    elseif n==3 then                                                          -- bpm control
      params:delta("bpm", d)                
    end
                                                                              -- REGULAR MODE
    
  elseif n==1 and d==1 then                                                   -- choose focused track 
    track_edit = (track_edit % 8) + d 
  elseif n==1 and d==-1 then
    track_edit = (track_edit + 6) % 8 + 1
    
  elseif n == 2 then                                                          -- track fill
    track[track_edit].k = util.clamp(track[track_edit].k+d,0,track[track_edit].n)
  
  elseif n==3 then                                                            -- track length
    track[track_edit].n = util.clamp(track[track_edit].n+d,1,32)
    track[track_edit].k = util.clamp(track[track_edit].k,0,track[track_edit].n)
  end
  reer(track_edit)
  redraw()
end

function redraw()
  screen.aa(0)
  screen.clear()
  
  if mode==0 then
    for i=1, 8 do
      screen.level((i == track_edit) and 15 or 4)
      screen.move(5, i*7.70)
      screen.text_center(track[i].k)
      screen.move(20,i*7.70)
      screen.text_center(track[i].n)
      for x=1,track[i].n do
        screen.level(track[i].pos==x and 15 or 2)
        screen.move(x*3 + 30, i*7.70)
        if track[i].s[x] then
          screen.line_rel(0,-6)
        else
          screen.line_rel(0,-2)
        end 
        screen.stroke()
      end
    end
    
  elseif mode==1 and page==0 then
    screen.move(5, 10)
    screen.text("track : " .. track_edit)
    screen.move(120, 10)
    screen.text_right("page " .. page + 1)
    screen.move(5, 15)
    screen.level(15)
    screen.line(121, 15)
    screen.move(64, 25)
    screen.level(4)
    screen.text_center("1. vol : " .. params:get(track_edit .. ": vol"))
    screen.move(64, 35)
    screen.text_center("2. vol envelope release : " .. params:get(track_edit .. ": vol env rel"))
    screen.move(64, 45)
    screen.text_center("3. trig probability : " .. track[track_edit].prob .. "%")
    
  elseif mode==1 and page==1 then
    screen.move(5, 10)
    screen.text("track : " .. track_edit)
    screen.move(120, 10)
    screen.text_right("page " .. page + 1)
    screen.move(5, 15)
    screen.level(15)
    screen.line(121, 15)
    screen.move(64, 25)
    screen.level(4)
    screen.text_center("1. speed : " .. params:get(track_edit .. ": speed"))
    screen.move(64, 35)
    screen.text_center("2. start pos : " .. params:get(track_edit .. ": start pos"))
    screen.move(64, 45)
    screen.text_center("3. end pos : " .. params:get(track_edit .. ": end pos"))
  
  elseif mode==1 and page==2 then
    screen.move(5, 10)
    screen.text("track : " .. track_edit)
    screen.move(120, 10)
    screen.text_right("page " .. page + 1)
    screen.move(5, 15)
    screen.level(15)
    screen.line(121, 15)
    screen.level(4)
    screen.move(64, 25)
    screen.text_center("1. filter cutoff : " .. math.floor(params:get(track_edit .. ": filter cutoff") + 0.5))
    screen.move(64, 35)
    screen.text_center("2. delay send : " .. params:get(track_edit .. ": delay send"))
    screen.move(64, 45)
    screen.text_center("3. reverb send : " .. params:get(track_edit .. ": reverb send"))
    
  elseif mode==2 then
    screen.move(64, 10)
    screen.text_center("global")
    screen.move(5, 15)
    screen.level(15)
    screen.line(121, 15)
    screen.move(64, 25)
    screen.level(4)
    screen.text_center("1. mix volume : " .. mix:get("output"))
    screen.move(64, 35)
    screen.text_center("3. bpm : " .. params:get("bpm"))
    
  end
  screen.stroke() 
  screen.update()
end

midi.add = function(dev)
  print("foulplay: midi device added", dev.id, dev.name)
  midi_device = dev
end

midi.remove = function(dev)
  print("foulplay: midi device removed", dev.id, dev.name)
  midi_device = nil
end

function cleanup()
  midi.add = nil
  midi.remove = nil
  params:write("justmat/foulplay.pset")
end