-- euclidean sample instrument 
-- with trigger conditions.
-- ----------
-- based on playfair
-- ----------
-- 
-- samples can be loaded 
-- via the parameter menu.
--
-- ----------
-- home
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
-- track edit screen. release to 
-- return home.
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
-- global edit screen. release to 
-- return home.
-- -----------
-- global edit
--
-- enc1 = set the mix volume
-- enc3 = set bpm
-- key2 = reset the phase of 
--         all tracks.

require 'er'

engine.name = 'Ack'

local ack = require 'jah/ack'
local BeatClock = require 'beatclock'

local clk = BeatClock.new()

local reset = false
local view = 0     -- 0 == home, 1 == track edit, 2 == global edit 
local page = 0
local track_edit = 1
local stopped = 1 -- change this to 0 if you would like to start running

local track = {}
for i=1, 8 do
  track[i] = {
    k = 0,
    n = 16,
    pos = 1,
    s = {},
    prob = 100,
    trig_logic = 0,
    logic_target = track_edit
  }
end

local function reer(i)
  if track[i].k == 0 then
    for n=1,32 do track[i].s[n] = false end
  else
    track[i].s = er(track[i].k,track[i].n)
  end
end

local function trig()
  for i, t in ipairs(track) do
    if t.trig_logic==0 and t.s[t.pos] then
      if math.random(100) <= t.prob then
        engine.trig(i-1)
      end
    elseif t.trig_logic == 1 then  -- and
      if t.s[t.pos] and track[t.logic_target].s[track[t.logic_target].pos] then
        if math.random(100) <= t.prob then
          engine.trig(i-1)
        end  
      end
    elseif t.trig_logic == 2 then  -- or
      if t.s[t.pos] or track[t.logic_target].s[track[t.logic_target].pos] then
        if math.random(100) <= t.prob then
          engine.trig(i-1)
        end
      end
    elseif t.trig_logic == 3 then  -- nand
      if t.s[t.pos] and track[t.logic_target].s[track[t.logic_target].pos] then
      elseif t.s[t.pos] then
        if math.random(100) <= t.prob then
          engine.trig(i-1)
        end
      end  
    elseif t.trig_logic == 4 then  -- nor
      if not t.s[t.pos] and not track[t.logic_target].s[track[t.logic_target].pos] then
        engine.trig(i-1)
      end 
    elseif t.trig_logic == 5 then  -- xor
      if not t.s[t.pos] and not track[t.logic_target].s[track[t.logic_target].pos] then
      elseif t.s[t.pos] and track[t.logic_target].s[track[t.logic_target].pos] then
      else engine.trig(i-1) end
    end
  end
end  
      
function init()
  for i=1, 8 do reer(i) end

  screen.line_width(1)
  
  clk.on_step = step
  clk.on_select_internal = function() clk:start() end
  clk.on_select_external = reset_pattern

  clk:add_clock_params()

  for channel=1,8 do
    ack.add_channel_params(channel)
  end
  
  ack.add_effects_params()
  params:read("justmat/foulplay.pset")
  params:bang()
  
  if stopped==1 then
    clk:stop()
  else
    clk:start()
  end  
end

function reset_pattern()
  reset = true
  clk:reset()
end

function step()
  if reset then
    for i=1,8 do track[i].pos = 1 end
    reset = false
  else
    for i=1,8 do track[i].pos = (track[i].pos % track[i].n) + 1 end 
  end
  trig()
  redraw()
end

function key(n,z)
  if n==1 then view = z end                                                   -- views all day
  if n==3 and z==1 and view==1 then
    page = (page + 1) % 4
  elseif n==3 and z==1 and view==0 then
    view = 2
  elseif n==3 and view==2 then
    view = 0
  end
  
  if view==2 then                                                             -- GLOBAL EDIT
    if n==2 and z==1 then                                                     -- phase reset
      reset_pattern()
      if stopped == 1 then                                                    -- set tracks back to step 1
          step()
      end
    end
  end 
  
  if view==1 then                                                             -- TRACK EDIT
    if n==2 and z==1 then                                                     -- track selection in edit mode
      track_edit = (track_edit % 8) + 1
    end  
  end 
  
  if view==0 then                                                             -- HOME
    if n==2 and z==1 then                                                     -- stop/start
      if stopped==0 then
        clk:stop()
        stopped = 1
      elseif stopped==1 then
        clk:start()
        stopped = 0
      end
    end
  end
  redraw()
end

function enc(n,d) 
  if view==1  and page==0 then                                                -- TRACK EDIT 
    if n==1 then                                                              -- track volume
      params:delta(track_edit .. ": vol", d)
    elseif n==2 then                                                          -- volume envelope release time
      params:delta(track_edit .. ": vol env atk", d)        
    elseif n==3 then
      params:delta(track_edit .. ": vol env rel", d)
    end
  
  elseif view==1 and page==1 then
    if n==1 then
      track[track_edit].trig_logic = util.clamp(d + track[track_edit].trig_logic, 0, 5)
    elseif n==2 then
      track[track_edit].logic_target = util.clamp(d+ track[track_edit].logic_target, 1, 8)
    elseif n==3 then
      track[track_edit].prob = util.clamp(d + track[track_edit].prob, 1, 100)
    end  
      
  elseif view==1 and page==2 then
    if n==1 then                                                              -- sample playback speed
      params:delta(track_edit .. ": speed", d)
    elseif n==2 then                                                          -- sample start position
      params:delta(track_edit .. ": start pos", d)             
    elseif n==3 then                                                          -- sample end position
      params:delta(track_edit .. ": end pos", d)
    end 
  
  elseif veiw==1 and page==3 then
    if n==1 then                                                              -- filter cutoff
      params:delta(track_edit .. ": filter cutoff", d)
    elseif n==2 then                                                          -- delay send
      params:delta(track_edit .. ": delay send", d)
    elseif n==3 then                                                          -- reverb send
      params:delta(track_edit .. ": reverb send", d)
    end
    
  elseif view==2 then                                                         -- GLOBAL EDIT 
    if n==1 then                                                              -- mix volume
      mix:delta("output", d)
    elseif n==3 then                                                          -- bpm control
      params:delta("bpm", d)                
    end
                                                                              -- HOME
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
  if view==0 then
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
    
  elseif view==1 and page==0 then
    screen.move(5, 10)
    screen.level(15)
    screen.text("track : " .. track_edit)
    screen.move(120, 10)
    screen.text_right("page " .. page + 1)
    screen.move(5, 15)
    screen.line(121, 15)
    screen.move(64, 25)
    screen.level(4)
    screen.text_center("1. vol : " .. math.floor(params:get(track_edit .. ": vol") + .5))
    screen.move(64, 35)
    screen.text_center("2. envelope attack : " .. params:get(track_edit .. ": vol env atk"))
    screen.move(64, 45)
    screen.text_center("3. envelope release : " .. params:get(track_edit .. ": vol env rel"))
    
  elseif view==1 and page==1 then
    screen.move(5, 10)
    screen.level(15)
    screen.text("track : " .. track_edit)
    screen.move(120, 10)
    screen.text_right("page " .. page + 1)
    screen.move(5, 15)
    screen.line(121, 15)
    screen.move(64, 25)
    screen.level(4)
    if track[track_edit].trig_logic == 0 then
      screen.text_center("1. trig logic : -")
      screen.move(64, 35)
      screen.level(1)
      screen.text_center("2. logic target : -")
      screen.level(4)
    elseif track[track_edit].trig_logic == 1 then
      screen.text_center("1. trig logic : and")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. track[track_edit].logic_target)
    elseif track[track_edit].trig_logic == 2 then
      screen.text_center("1. trig logic : or")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. track[track_edit].logic_target)
    elseif track[track_edit].trig_logic == 3 then
      screen.text_center("1. trig logic : nand")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. track[track_edit].logic_target)
    elseif track[track_edit].trig_logic == 4 then
      screen.text_center("1. trig logic : nor")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. track[track_edit].logic_target)
    elseif track[track_edit].trig_logic == 5 then
      screen.text_center("1. trig logic : xor")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. track[track_edit].logic_target)  
    end
    screen.move(64, 45)
    screen.text_center("3. trig probability : " .. track[track_edit].prob .. "%")
    
  elseif view==1 and page==2 then
    screen.move(5, 10)
    screen.level(15)
    screen.text("track : " .. track_edit)
    screen.move(120, 10)
    screen.text_right("page " .. page + 1)
    screen.move(5, 15)
    screen.line(121, 15)
    screen.move(64, 25)
    screen.level(4)
    screen.text_center("1. speed : " .. params:get(track_edit .. ": speed"))
    screen.move(64, 35)
    screen.text_center("2. start pos : " .. params:get(track_edit .. ": start pos"))
    screen.move(64, 45)
    screen.text_center("3. end pos : " .. params:get(track_edit .. ": end pos"))
  
  elseif view==1 and page==3 then
    screen.move(5, 10)
    screen.level(15)
    screen.text("track : " .. track_edit)
    screen.move(120, 10)
    screen.text_right("page " .. page + 1)
    screen.move(5, 15)
    screen.line(121, 15)
    screen.level(4)
    screen.move(64, 25)
    screen.text_center("1. filter cutoff : " .. math.floor(params:get(track_edit .. ": filter cutoff") + 0.5))
    screen.move(64, 35)
    screen.text_center("2. delay send : " .. params:get(track_edit .. ": delay send"))
    screen.move(64, 45)
    screen.text_center("3. reverb send : " .. params:get(track_edit .. ": reverb send"))
    
  elseif view==2 then
    screen.move(64, 10)
    screen.level(15)
    screen.text_center("global")
    screen.move(5, 15)
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
  dev.event = clk.process_midi
  print("foulplay: midi device added", dev.id, dev.name)
end
