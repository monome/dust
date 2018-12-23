-- roda
--
--  a microrhythmic sampler
--
-- inspired by the microrhythms
-- of Samba de Roda.
--
-- load samples via parameters
--
-- DISPLAY
-- -------------------------------------------
-- bpm:       | ratio to beat |
-- track 1          # divisions
-- track 2          # divisions
-- track 3          # divisions
-- track 4          # divisions
--                  pause/play
--
-- CONTROLS
-- --------------------------------------------
-- key1: mute selected track
-- key2: change track
-- key3: play | pause
--
-- enc1: select division
-- enc2: shift selected division
-- enc3: change # of divisions
--      in selected track [1-9]
--
-- PARAMETERS
-- --------------------------------------------
-- standard 'ack' parameters
--
-- RANDOM MODE
-- ---------------------------------------------
-- randomly change a handful
-- of parameters on each
-- sample triggered.
--
-- In the parameter menu...
-- 
-- mode 0: none/off
-- mode 1: total random
-- mode 2: step-based random
-- (like Drunk Obj. in Max/MSP)
--
-- each track can be muted from 
-- so as not to be altered by 
-- random mode.
--
-- 0 = affectable
-- 1 = unaffectable

engine.name = 'Ack'

local ack = require 'jah/ack'


------------
-- variables
------------



-- clocking variables
position = 0
q_position = 0
bpm = 60
counter = nil
running = false
ppq =  192 -- pulses per quarter

track = {{},{},{},{}, divs = {1,2,3,4}}
track_select = 0
div_select = 0

-- init tracks
for i = 1, #track do
  for j = 1, track.divs[i] do
    table.insert(track[i], j, (ppq//track.divs[i])*j)
  end
end



----------------
-- initilization
----------------



-- FIX ME! set_action with key press?

function init()

  -- parameters
  params:add_number("bpm", "bpm", 15, 400, 60)
  params:add_number("random_mode", "random mode:", 0, 2, 0)
  params:add_number("drunk_step", "mode 2 step size:", 1, 10, 1)
  params:add_number("1_mute", "mute track 1:", 0, 1, 0)
  params:add_number("2_mute", "mute track 2:", 0, 1, 0)
  params:add_number("3_mute", "mute track 3:", 0, 1, 0)
  params:add_number("4_mute", "mute track 4:", 0, 1, 0)
  params:set_action("1_mute", function(x) mute_groups(1,x) end )
  params:set_action("2_mute", function(x) mute_groups(2,x) end )
  params:set_action("3_mute", function(x) mute_groups(3,x) end )
  params:set_action("4_mute", function(x) mute_groups(4,x) end )
  params:add_separator()
  params:add_number("preset", "preset:", 1, 128, 1)
  params:add_option("file", "save-load", {"save","load"}, 1)
  params:set_action("file", function(x) if x == 1 then save() else load() end end)
  params:add_separator()
  ack.add_effects_params()
  params:add_separator()
  
  for channel=1,4 do
    ack.add_channel_params(channel)
    params:add_separator()
  end

  params:read("tyler/roda.pset")

  -- metronome setup
  counter = metro.alloc()
  counter.time = 60 / (params:get("bpm") * ppq)
  counter.count = -1
  counter.callback = count
  -- counter:start()

  random_mute_groups("1-4",0)
  redraw()
end

mute = {0,0,0,0}
random_mute = {}
function random_mute_groups(track,x)
  if x == 1 then
    print("track "..track.." muted")
  else
    print("track "..track.." unmuted")
  end
  for i=1,4 do
    if params:get(i.."_mute") == 1 then
      random_mute[i] = 1
    else
      random_mute[i] = 0
    end
  end
  tab.print(random_mute)
end



---------------------------
-- norns control functions
---------------------------



function enc(n,d)
  if n == 1 then
    div_select = (div_select + d) % track.divs[track_select+1]
  end
  
  if n == 2 then
    track[track_select+1][div_select+1] = util.clamp(track[track_select+1][div_select+1] + d, 1, ppq - 1)
    print(track[track_select+1][div_select+1])
  end
  
  if n == 3 then
    refresh_track(
      track_select+1,
      util.clamp(track.divs[track_select+1] + d, 1, 9)
      )
  end
    
redraw()
end

function key(n,z)
  
  if z == 1 then
    if n == 1 then
      mute[track_select+1] = (mute[track_select+1] + 1) % 2
    end
    
    if n == 2 then
      track_select = (track_select + 1) % #track
      div_select = 0
      print(track_select)
    end
    
    if n == 3 then
      if running then
        counter:stop()
        running = false
      else
        counter:start()
        running = true
      end
    end
  end

redraw()
end



------------------
-- active functions
-------------------



function refresh_track(i, divs)
  track[i] = {}
  track.divs[i] = divs
  for j = 1, track.divs[i] do
    table.insert(track[i], j, (ppq//track.divs[i]) * j)
  end
end

function simplify(n,d)
  while n ~= 1 do
    if n/2 == n//2 then
      n = n//2
      d = d//2 -- don't need to check d, typically a power of 2.
    elseif n/3 == 1 then
      n = n//3
      d = d//3
      return({n,d})
    else
      return({n,d})
    end
  end
  return({n,d})
end

function count(c)
  position = (position + 1) % (ppq + 1)
  if position == 0 then position = 1 end
  counter.time = 60 / (params:get("bpm") * ppq)
  
  for i = 1, #track do
    for j = 1, #track[i] do
      if position / track[i][j] == 1 then
        if mute[i] == 0 then
          engine.trig(i-1) 
          print(track[i][j])
        end                                                               -- random modes affect after trigger
        if params:get("random_mode") == 1 then                            -- mode 1:total random
          if params:get(i.."_mute") == 0 then   
            params:set(i.."_start_pos", math.random())
            --params:set(i.."_speed", math.random())
            params:set(i.."_pan", math.random(-1,1)*math.random())        -- -1 or 1 * random float, to fit -1 through 1 panning range
            params:set(i.."_filter_cutoff", math.random(20,20000))
            params:set(i.."_filter_res", math.random())
            params:set(i.."_filter_env_atk", math.random())
            params:set(i.."_filter_env_rel", math.random())
            params:set(i.."_filter_env_mod", math.random())
            params:set(i.."_dist", math.random())
          end
        elseif params:get("random_mode") == 2 then                        -- mode 2: step-based (like drunk from Max) random
          if params:get(i.."_mute") == 0 then   
            size = params:get("drunk_step")
            params:delta(i.."_start_pos", (math.random(-10,10)/100)*size)
            --params:delta(i.."_speed", (math.random(-10,10)/100)*size)
            params:delta(i.."_pan", (math.random(-10,10)/100)*size)       -- -1 or 1 * random float, to fit -1 through 1 panning range
            params:delta(i.."_filter_cutoff", math.random(-100*size,100*size))
            params:delta(i.."_filter_res", (math.random(-10,10)/100)*size)
            params:delta(i.."_filter_env_atk", (math.random(-10,10)/100)*size)
            params:delta(i.."_filter_env_rel", (math.random(-10,10)/100)*size)
            params:delta(i.."_filter_env_mod", (math.random(-10,10)/100)*size)
            params:delta(i.."_dist", (math.random(-10,10)/100)*size)
          end
        end
      end
    end
  end
end



---------------------------
-- refresh/redraw functions
---------------------------


function redraw()
  screen.clear()
  screen.aa(0)
  
  screen.level(15)
  
    -- track_select cursor
    screen.rect(0, track_select*10 + 15, 1, 3)
    screen.fill()
    
    -- divisions
    screen.aa(1)
    for i = 1, #track do
      for j = 1, track.divs[i] do
        if track[i][j] ~= ppq then
          screen.move(track[i][j]/1.6, i*10 + 5)
        else
          screen.move(3, i*10 + 5)
        end
        screen.line_rel(0,3)
        
        if j == div_select+1 and i == track_select+1 then
          screen.line_rel(0,-6)
        end
        screen.stroke()
        
        -- division length display
        screen.move(123, i*10 + 9)
        screen.text(track.divs[i])
      end
    end
    screen.aa(0)  

    -- param display
    screen.move(1,5)
    screen.text("bpm:"..params:get("bpm"))

    -- pause/play icon
    if not running then
      screen.rect(123,57,2,6)
      screen.rect(126,57,2,6)
      screen.fill()
    else
      screen.move(123,57)
      screen.line_rel(6,3)
      screen.line_rel(-6,3)
      screen.fill()
    end
    
    -- track mute toggle
    for i = 1, #track do
      screen.move(4 + (i-1)*20, 60)
      screen.text_right(i)
      screen.rect(8 + (i-1)*20, 54, 8, 8)
      screen.move(9 + (i-1)*20, 60)
      if mute[i] == 0 then screen.level(1) end
      screen.text("M")
      screen.level(15)
      screen.stroke()
    end

  screen.level(12)
  
    -- tracks
    for i = 1, 4 do
      screen.rect(2, i*10+5, 118,4)
      screen.stroke()
    end
    
  screen.level(1)
  
    -- ratio display
    screen.move(128,5)
    screen.text_right(
      simplify(track[track_select+1][div_select+1],ppq)[1]
      .."/"..
      simplify(track[track_select+1][div_select+1],ppq)[2]
      )
    screen.stroke()
    
screen.update()
end

function save()
  tab.save(track, data_dir .. 'tyler/roda-'.. params:get("preset") ..'.data')
  print("SAVE COMPLETE", params:get("preset"))
end

function load()
  track = tab.load(data_dir .. 'tyler/roda-'.. params:get("preset") ..'.data')
  print("LOAD COMPLETE", params:get("preset"))
  redraw()
end
