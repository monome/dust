-- euclidean sample instrument 
-- with probability.
-- ----------
-- based on playfair 
-- and now based on foulplay 
-- 
-- this version adds grid support - mjw
--
-- ----------
-- 
-- samples can be loaded 
-- via the parameter menu.
--
-- enc1 = cycle through 
--         the tracks.
--
--  grid column 1 switches the track edit directly 
--  grid column 2 provides a mute toggle for each track 
-- this is global separate from memory cells
-- not accessible via buttons and encoders 
--  (it's a performance feature doesn't make sense to hide it behind key presses)
--
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
-- 
-- grid buttons 4-8 on bottom row also 
-- bring these pages up 
--
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
-- ---------------
-- memory cells
-- 
-- press in grid 5x5 dim lit area for different 
-- memory cells 
-- memory switches instantly when you release grid button 
-- 
-- copy cells by pressing copy (8,8)
-- press 'source' cell (will start flashing)
-- press one or more target cells to copy source to them 
-- end copy mode by releasing copy button
-- 
-- ---------------

require 'er'

engine.name = 'Ack'

local ack = require 'jah/ack'
local BeatClock = require 'beatclock'

local clk = BeatClock.new()

local reset = false
local mode = 0                                                                -- 0 == regular, 1 == track edit, 2 == global edit 
local page = 0
local track_edit = 1
local stopped = 1
local currentmemcell = 1
local currentmemcell_x = 4
local currentmemcell_y = 1
local copymode = false
local blink = false
local copysource_x = -1
local copysource_y = -1

-- mutes are global 
-- grid column 2 and tracks 1-8
local mutes = {} 
for i=1,8 do
  mutes[i] = false
end

-- grid area 4,1 - 8,5 are separate 
-- memory cells for entire collections
-- of 8 tracks
-- mjw

local memorycell = {}
for j = 1,25 do 
  memorycell[j] = {}
  for i=1, 8 do
    memorycell[j][i] = {}
    memorycell[j][i].k = 0
    memorycell[j][i].n = 16
    memorycell[j][i].pos = 1
    memorycell[j][i].s = {}
    memorycell[j][i].prob = 100                                                         
  end
end

function gettracK( cell , tracknum ) 
  return memorycell[cell][tracknum]
end

function cellfromgrid( x , y )
  return (((y - 1) * 5) + (x -4)) + 1
end

-- depracate this in a bit
-- local track = {}
-- for i=1, 8 do
--  track[i] = {}
--  track[i].k = 0
--  track[i].n = 16
--  track[i].pos = 1
--  track[i].s = {}
--  track[i].prob = 100                                                         
-- end

local function reer(i)
  
  if gettracK(currentmemcell,i).k == 0 then
    for n=1,32 do gettracK(currentmemcell,i).s[n] = false end
  else
    gettracK(currentmemcell,i).s = er(gettracK(currentmemcell,i).k,gettracK(currentmemcell,i).n)
  end
end

local function trig()
  for i=1,8 do
    if gettracK(currentmemcell,i).s[gettracK(currentmemcell,i).pos] then
      if math.random(100) <= gettracK(currentmemcell,i).prob and mutes[i] == false then                               -- for per track probability
        engine.trig(i-1)
      end
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
  -- set up grid
  print("grid")
  -- grid refresh timer, 40 fps
  -- this caught me out first time 
  -- the template just updates the grid from keys 
  -- but it seems better to treat the grid like the screen
  -- also g: isn't set yet during init 
  metro_grid_redraw = metro.alloc(function(stage) grid_redraw() end, 1 / 40)
  metro_grid_redraw:start()
  -- blink for copy mode 
  metro_blink = metro.alloc(function(stage) blink = not blink end, 1 / 4)
  metro_blink:start()
  
  
end



function reset_pattern()
  reset = true
  clk:reset()
end

function step()
  if reset then
    for i=1,8 do gettracK(currentmemcell,i).pos = 1 end
    reset = false
  else
    for i=1,8 do gettracK(currentmemcell,i).pos = (gettracK(currentmemcell,i).pos % gettracK(currentmemcell,i).n) + 1 end 
  end
  trig()
  redraw()
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
      reset_pattern()
      if stopped == 1 then                                                    -- set tracks back to step 1
          step()
      end
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
  if mode==1  and page==0 then                                                -- TRACK EDIT 
    if n==1 then                                                              -- track volume
      params:delta(track_edit .. ": vol", d)
    elseif n==2 then                                                          -- volume envelope release time
      params:delta(track_edit .. ": vol env rel", d)        
    elseif n==3 then                                                          -- trig prob 
      gettracK(currentmemcell,track_edit).prob = util.clamp(d + gettracK(currentmemcell,track_edit).prob, 1, 100)
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
    gettracK(currentmemcell,track_edit).k = util.clamp(gettracK(currentmemcell,track_edit).k+d,0,gettracK(currentmemcell,track_edit).n)
  
  elseif n==3 then                                                            -- track length
    gettracK(currentmemcell,track_edit).n = util.clamp(gettracK(currentmemcell,track_edit).n+d,1,32)
    gettracK(currentmemcell,track_edit).k = util.clamp(gettracK(currentmemcell,track_edit).k,0,gettracK(currentmemcell,track_edit).n)
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
      screen.text_center(gettracK(currentmemcell,i).k)
      screen.move(20,i*7.70)
      screen.text_center(gettracK(currentmemcell,i).n)
      for x=1,gettracK(currentmemcell,i).n do
        screen.level(gettracK(currentmemcell,i).pos==x and 15 or 2)
        screen.move(x*3 + 30, i*7.70)
        if gettracK(currentmemcell,i).s[x] then
          screen.line_rel(0,-6)
        else
          screen.line_rel(0,-2)
        end 
        screen.stroke()
      end
    end
    
  elseif mode==1 and page==0 then
    screen.move(5, 10)
    screen.level(15)
    screen.text("track : " .. track_edit)
    screen.move(120, 10)
    screen.text_right("page " .. page + 1)
    screen.move(5, 15)
    screen.line(121, 15)
    screen.move(64, 25)
    screen.level(4)
    screen.text_center("1. vol : " .. params:get(track_edit .. ": vol"))
    screen.move(64, 35)
    screen.text_center("2. vol envelope release : " .. params:get(track_edit .. ": vol env rel"))
    screen.move(64, 45)
    screen.text_center("3. trig probability : " .. gettracK(currentmemcell,track_edit).prob .. "%")
    
  elseif mode==1 and page==1 then
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
  
  elseif mode==1 and page==2 then
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
    
  elseif mode==2 then
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
  print("fairplay: midi device added", dev.id, dev.name)
end

-- grid stuff - mjw

-- grid key function
function gridkey(x, y, state)
  -- print("x:",x," y:",y," state:",state)
  -- use first column to switch track edit
  if x == 1 then
    track_edit = y
    reer(track_edit)
  end
  -- second column provides mutes 
  -- key presses just toggle
  -- switches on grid up - so you can hold down
  -- and lift to get timing right 
  if x == 2 and state == 1 then
    mutes[y] = not mutes[y]
  end
  -- 4-6,8 are used to open track parameters pages
  if y == 8 and x >= 4 and x <= 6 and state == 1 then
    mode = 1
    page = x - 4
  else 
    mode = 0
  end
  -- copy button 
  if x == 8 and y==8 and state == 1 then 
    copymode = true
    copysource_x = -1
    copysource_y = -1
  elseif x == 8 and y==8 and state == 0 then
    copymode = false
    copysource_x = -1
    copysource_y = -1
  end  
  -- memory cells 
  -- if we aren't in copymode 
  -- press to switch memory 
  -- switches on grid up not grid down
  if not copymode then
    if y >= 1 and y <= 5 and x >= 4 and x <= 8 and state == 1 then 
      currentmemcell = cellfromgrid(x,y)
      currentmemcell_x = x
      currentmemcell_y = y
    end
  else
    if y >= 1 and y <= 5 and x >= 4 and x <= 8 and state == 0 then 
      -- copy functionality 
      -- if we are in copy mode then don't switch 
      -- memories - copy about instead 
      if copysource_x == -1 then 
        -- first button sets the source
        copysource_x = x
        copysource_y = y
      else 
        -- copy source into target 
        if copy_source_x ~= -1 and not ( copysource_x == x and copysource_y == y) then
          sourcecell = cellfromgrid( copysource_x , copysource_y )
          targetcell = cellfromgrid( x , y )
          for i=1,8 do
            gettracK( targetcell , i ).k = gettracK( sourcecell , i ).k
            gettracK( targetcell , i ).n = gettracK( sourcecell , i ).n
            gettracK( targetcell , i ).pos = gettracK( sourcecell , i ).pos
            gettracK( targetcell , i ).s = gettracK( sourcecell , i ).s
            gettracK( targetcell , i ).prob = gettracK( sourcecell , i ).prob
          end
        end
      end
    end
  end
  
  redraw()
end

function grid_redraw()
  -- note slight level variations are because push2 
  -- displays these as different colours 
  -- attempted to do something that should work for both
  -- real grid and push2 version 
  if g == nil then
    -- bail if we are too early 
    return
  end
  -- clear it all 
  g:all(0)
  -- highlight current track
  g:led(1, track_edit, 15)
  -- track page buttons 
  -- low light for off - I kept forgetting which keys they were 
  -- highlight for on 
  for page = 0,2 do
      g:led(page + 4,8,1)
  end
  -- highlight page if open 
  -- if you open it via keys/enc still highlights
  -- which I'm actually ok with 
  if mode == 1 then
    g:led(page + 4,8,14)
  end
  -- mutes are on or off 
  for i = 1,8 do 
    if mutes[i]  then
      g:led(2,i,7)
    end
  end
  -- memory cells 
  -- wondered if I should have a mid level meaning 'have edited'
  -- but not sure if that might just add clutter 
  for x = 4,8 do
    for y = 1,5 do
      g:led(x,y,1)
    end
  end
  -- highlight active memory 
  g:led(currentmemcell_x,currentmemcell_y,15)
  -- copy mode - blink the source if set 
  if copymode then
    if copysource_x ~= -1 then
      if blink then 
        g:led(copysource_x,copysource_y,4)
      else
        g:led(copysource_x,copysource_y,12)
      end
    end
  end
  -- copy button - dim if unpressed, highlight if pressed 
  if copymode  then 
    g:led(8,8,14)
  else
    g:led(8,8,1)
  end
  --- and display! 
  g:refresh()
end


