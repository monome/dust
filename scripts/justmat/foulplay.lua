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
-- on the home screen,
-- holding key3 will engage
-- alternate controls.
--
-- key3 + enc1 = mix volume
-- key3 + enc2 = rotation
-- key3 + enc3 = bpm
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
-- grid support added 
-- by junklight 
-- ----------
--
-- col 1 select track edit
-- col 2 provides mute toggles 
--
-- change track edit pages 
-- with grid buttons 4-7 on
-- the bottom row.
-- 
-- button 8 on the bottom row
-- is the copy button.
--
-- the dimly lit 5x5 grid is 
-- made up of memory cells.
-- simply press a cell to select 
-- it.
--
-- to copy a pattern to a new 
-- cell hold the copy button, 
-- and press the cell you'd 
-- like to copy.
-- the cell will blink. while
-- still holding copy, press the
-- destination cell.
-- release the copy button.
-- 


require 'er'

engine.name = 'Ack'

local ack = require 'jah/ack'
local BeatClock = require 'beatclock'

local clk = BeatClock.new()

local ALT = 0
local reset = false
-- 0 == home, 1 == track edit
local view = 0      
local page = 0
local track_edit = 1
local stopped = 1 
-- added for grid support - junklight 
local current_mem_cell = 1
local current_mem_cell_x = 4
local current_mem_cell_y = 1
local copy_mode = false
local blink = false
local copy_source_x = -1
local copy_source_y = -1
-- mutes are global 
-- grid column 2 and tracks 1-8
local mutes = {} 
for i=1,8 do
  mutes[i] = false
end


function simplecopy(obj)
  if type(obj) ~= 'table' then return obj end
  local res = {}
  for k, v in pairs(obj) do 
    res[simplecopy(k)] = simplecopy(v) 
  end
  return res
end
---------------

local memory_cell = {}
for j = 1,25 do 
  memory_cell[j] = {}
  for i=1, 8 do
    memory_cell[j][i] = {
      k = 0,
      n = 16,
      pos = 1,
      s = {},
      prob = 100,
      trig_logic = 0,
      logic_target = track_edit,
      rotation = 0
  }                                                       
  end
end

local function gettrack( cell , tracknum ) 
  return memory_cell[cell][tracknum]
end

local function cellfromgrid( x , y )
  return (((y - 1) * 5) + (x -4)) + 1
end

gettrack(current_mem_cell,i)

local function rotate_pattern(t, rot, n, r)
  n, r = n or #t, {}
  rot = rot % n
  for i = 1, rot do
    r[i] = t[n - rot + i]
  end
  for i = rot + 1, n do
    r[i] = t[i - rot]
  end
  return r
end

local function reer(i)
  if gettrack(current_mem_cell,i).k == 0 then
    for n=1,32 do gettrack(current_mem_cell,i).s[n] = false end
  else
    gettrack(current_mem_cell,i).s = rotate_pattern(er(gettrack(current_mem_cell,i).k, gettrack(current_mem_cell,i).n), gettrack(current_mem_cell, i).rotation)
  end
end

-- in the logic target logic - mutes are ignored on the target track 
-- so a track may not be playing but can still effect the track 
-- that uses it as a target 

local function trig()
  for i, t in ipairs(memory_cell[current_mem_cell]) do
    if t.trig_logic==0 and t.s[t.pos]  then
      if math.random(100) <= t.prob and mutes[i] == false then
        engine.trig(i-1)
      end
    elseif t.trig_logic == 1 then  -- and
      if t.s[t.pos] and gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos]  then
        if math.random(100) <= t.prob and mutes[i] == false then
          engine.trig(i-1)
        end  
      end
    elseif t.trig_logic == 2 then  -- or
      if t.s[t.pos] or gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos] then
        if math.random(100) <= t.prob and mutes[i] == false then
          engine.trig(i-1)
        end
      end
    elseif t.trig_logic == 3 then  -- nand
      if t.s[t.pos] and gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos]  then
      elseif t.s[t.pos] then
        if math.random(100) <= t.prob and mutes[i] == false then
          engine.trig(i-1)
        end
      end  
    elseif t.trig_logic == 4 then  -- nor
      if not t.s[t.pos] and not gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos] and mutes[i] == false then
        engine.trig(i-1)
      end 
    elseif t.trig_logic == 5 then  -- xor
      if mutes[i] == false then 
        if not t.s[t.pos] and not gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos] then
        elseif t.s[t.pos] and gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos] then
        else engine.trig(i-1) end
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
  
  loadstate()
  
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
  
  --for i=1, 8 do reer(i) end
end

function reset_pattern()
  reset = true
  clk:reset()
end

function step()
  if reset then
    for i=1,8 do 
      gettrack(current_mem_cell,i).pos = 1 
    end
    reset = false
  else
    for i=1,8 do 
      gettrack(current_mem_cell,i).pos = (gettrack(current_mem_cell,i).pos % gettrack(current_mem_cell,i).n) + 1 
    end 
  end
  trig()
  redraw()
end

function key(n,z)
  -- normal and track edit views
  if n==1 then view = z end 
  if n==3 and z==1 and view==1 then
    page = (page + 1) % 4
  end
  if n==3 then ALT = z end
  
  -- track selection in track edit view
  if view==1 then                                                            
    if n==2 and z==1 then                                                     
      track_edit = (track_edit % 8) + 1
    end  
  end 
  
  if ALT==1 then   
    -- track phase reset
    if n==2 and z==1 then                                                    
      reset_pattern()
      if stopped == 1 then                                                    
          step()
      end
    end
  end 
  -- home view. start/stop
  if ALT==0 and view==0 then
    if n==2 and z==1 then                                                
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
  if ALT==1 then
    -- mix volume control
    if n==1 then
      mix:delta("output", d)
    -- track rotation control  
    elseif n==2 then
      gettrack(current_mem_cell, track_edit).rotation = util.clamp(gettrack(current_mem_cell, track_edit).rotation + d, 0, 32)
      gettrack(current_mem_cell,track_edit).s = rotate_pattern( gettrack(current_mem_cell,track_edit).s, gettrack(current_mem_cell, track_edit).rotation )
      redraw()
    -- bpm control  
    elseif n==3 then
      params:delta("bpm", d)                
    end
  -- track edit view  
  elseif view==1  and page==0 then 
    -- per track volume control
    if n==1 then
      params:delta(track_edit .. ": vol", d)
    elseif n==2 then
      params:delta(track_edit .. ": vol env atk", d)        
    elseif n==3 then
      params:delta(track_edit .. ": vol env rel", d)
    end
  
  elseif view==1 and page==1 then
    -- trigger logic and probability settings
    if n==1 then
      gettrack(current_mem_cell,track_edit).trig_logic = util.clamp(d + gettrack(current_mem_cell,track_edit).trig_logic, 0, 5)
    elseif n==2 then
      gettrack(current_mem_cell,track_edit).logic_target = util.clamp(d+ gettrack(current_mem_cell,track_edit).logic_target, 1, 8)
    elseif n==3 then
      gettrack(current_mem_cell,track_edit).prob = util.clamp(d + gettrack(current_mem_cell,track_edit).prob, 1, 100)
    end  
      
  elseif view==1 and page==2 then
    -- sample playback settings
    if n==1 then
      params:delta(track_edit .. ": speed", d)
    elseif n==2 then
      params:delta(track_edit .. ": start pos", d)             
    elseif n==3 then 
      params:delta(track_edit .. ": end pos", d)
    end 
  
  elseif view==1 and page==3 then
    -- filter and fx sends
    if n==1 then
      params:delta(track_edit .. ": filter cutoff", d)
    elseif n==2 then
      params:delta(track_edit .. ": delay send", d)
    elseif n==3 then
      params:delta(track_edit .. ": reverb send", d)
    end
  -- HOME
  -- choose focused track, track fill, and track length
  elseif n==1 and d==1 then 
    track_edit = (track_edit % 8) + d 
  elseif n==1 and d==-1 then
    track_edit = (track_edit + 6) % 8 + 1
  elseif n == 2 then  
    gettrack(current_mem_cell,track_edit).k = util.clamp(gettrack(current_mem_cell,track_edit).k+d,0,gettrack(current_mem_cell,track_edit).n)
  elseif n==3 then 
    gettrack(current_mem_cell,track_edit).n = util.clamp(gettrack(current_mem_cell,track_edit).n+d,1,32)
    gettrack(current_mem_cell,track_edit).k = util.clamp(gettrack(current_mem_cell,track_edit).k,0,gettrack(current_mem_cell,track_edit).n)
  end
  reer(track_edit)
  redraw()
end

function redraw()
  screen.aa(0)
  screen.clear()
  if view==0 and ALT==0 then
    for i=1, 8 do
      screen.level((i == track_edit) and 15 or 4)
      screen.move(8, i*7.70)
      screen.text_center(gettrack(current_mem_cell,i).k)
      screen.move(25,i*7.70)
      screen.text_center(gettrack(current_mem_cell,i).n)
      for x=1,gettrack(current_mem_cell,i).n do
        screen.level(gettrack(current_mem_cell,i).pos==x and 15 or 2)
        screen.move(x*3 + 35, i*7.70)
        if gettrack(current_mem_cell,i).s[x] then
          screen.line_rel(0,-6)
        else
          screen.line_rel(0,-2)
        end 
        screen.stroke()
      end
    end
  elseif view==0 and ALT==1 then
    screen.level(4)
    screen.move(0,8 + 11)
    screen.text("vol")
    screen.move(0, 16 + 11)
    screen.text(mix:get("output"))
    screen.move(0, 21 + 11)
    screen.line(20, 21 + 11)
    screen.move(0, 30 + 11)
    screen.text("bpm")
    screen.move(0, 40 + 11)
    if params:get("clock") == 1 then
      screen.text(params:get("bpm"))
    end
    
    for i=1,8 do
      screen.level((i == track_edit) and 15 or 4)
      screen.move(25, i*7.70)
      screen.text_center(gettrack(current_mem_cell, i).rotation)
      for x=1,gettrack(current_mem_cell,i).n do
        screen.level(gettrack(current_mem_cell,i).pos==x and 15 or 2)
        screen.move(x*3 + 35, i*7.70)
        if gettrack(current_mem_cell,i).s[x] then
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
    if gettrack(current_mem_cell,track_edit).trig_logic == 0 then
      screen.text_center("1. trig logic : -")
      screen.move(64, 35)
      screen.level(1)
      screen.text_center("2. logic target : -")
      screen.level(4)
    elseif gettrack(current_mem_cell,track_edit).trig_logic == 1 then
      screen.text_center("1. trig logic : and")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. gettrack(current_mem_cell,track_edit).logic_target)
    elseif gettrack(current_mem_cell,track_edit).trig_logic == 2 then
      screen.text_center("1. trig logic : or")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. gettrack(current_mem_cell,track_edit).logic_target)
    elseif gettrack(current_mem_cell,track_edit).trig_logic == 3 then
      screen.text_center("1. trig logic : nand")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. gettrack(current_mem_cell,track_edit).logic_target)
    elseif gettrack(current_mem_cell,track_edit).trig_logic == 4 then
      screen.text_center("1. trig logic : nor")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. gettrack(current_mem_cell,track_edit).logic_target)
    elseif gettrack(current_mem_cell,track_edit).trig_logic == 5 then
      screen.text_center("1. trig logic : xor")
      screen.move(64, 35)
      screen.text_center("2. logic target : " .. gettrack(current_mem_cell,track_edit).logic_target)  
    end
    screen.move(64, 45)
    screen.text_center("3. trig probability : " .. gettrack(current_mem_cell,track_edit).prob .. "%")
    
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
  end
  screen.stroke() 
  screen.update()
end

midi.add = function(dev)
  dev.event = clk.process_midi
  print("foulplay: midi device added", dev.id, dev.name)
end

-- grid stuff - junklight

-- grid key function
function gridkey(x, y, state)
  -- use first column to switch track edit
  if x == 1 then
    track_edit = y
  end
  -- second column provides mutes 
  -- key presses just toggle
  -- switches on grid up
  if x == 2 and state == 1 then
    mutes[y] = not mutes[y]
  end
  -- 4-6, are used to open track parameters pages
  if y == 8 and x >= 4 and x <= 7 and state == 1 then
    view = 1
    page = x - 4
  else 
    view = 0
  end
  -- copy button 
  if x == 8 and y==8 and state == 1 then 
    copy_mode = true
    copy_source_x = -1
    copy_source_y = -1
  elseif x == 8 and y==8 and state == 0 then
    copy_mode = false
    copy_source_x = -1
    copy_source_y = -1
  end  
  -- memory cells 
  -- if we aren't in copy_mode 
  -- press to switch memory 
  -- switches on grid down
  if not copy_mode then
    if y >= 1 and y <= 5 and x >= 4 and x <= 8 and state == 1 then 
      current_mem_cell = cellfromgrid(x,y)
      current_mem_cell_x = x
      current_mem_cell_y = y
      for i = 1, 8 do reer(i) end
    end
  else
    if y >= 1 and y <= 5 and x >= 4 and x <= 8 and state == 0 then 
      -- copy functionality 
      -- if we are in copy mode then don't switch 
      -- memories - copy about instead 
      if copy_source_x == -1 then 
        -- first button sets the source
        copy_source_x = x
        copy_source_y = y
      else 
        -- copy source into target 
        if copy_source_x ~= -1 and not ( copy_source_x == x and copy_source_y == y) then
          sourcecell = cellfromgrid( copy_source_x , copy_source_y )
          targetcell = cellfromgrid( x , y )
          memory_cell[targetcell] = simplecopy(memory_cell[sourcecell])
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
  -- dim for off 
  -- bright for on 
  for page = 0,3 do
      g:led(page + 4, 8, 3)
  end
  -- highlight page if open 
  -- if you open it via keys/enc still highlights
  -- which I'm actually ok with 
  if view == 1 then
    g:led(page + 4, 8, 14)
  end
  -- mutes are on or off 
  for i = 1,8 do 
    if mutes[i]  then
      g:led(2, i, 7)
    end
  end
  -- memory cells 
  -- wondered if I should have a mid level meaning 'have edited'
  -- but not sure if that might just add clutter 
  for x = 4,8 do
    for y = 1,5 do
      g:led(x, y, 3)
    end
  end
  -- highlight active memory 
  g:led(current_mem_cell_x, current_mem_cell_y, 15)
  -- copy mode - blink the source if set 
  if copy_mode then
    if copy_source_x ~= -1 then
      if blink then 
        g:led(copy_source_x, copy_source_y, 4)
      else
        g:led(copy_source_x, copy_source_y, 12)
      end
    end
  end
  -- copy button - dim if unpressed, highlight if pressed 
  if copy_mode  then 
    g:led(8, 8, 14)
  else
    g:led(8, 8, 3)
  end
  --- and display! 
  g:refresh()
end

function savestate()
  local file = io.open(data_dir .. "justmat/foulplay.data", "w+")
  io.output(file)
  for j = 1, 25 do
    for i = 1, 8 do
      io.write(memory_cell[j][i].k .. "\n")
      io.write(memory_cell[j][i].n .. "\n")
      io.write(memory_cell[j][i].prob .. "\n")
      io.write(memory_cell[j][i].trig_logic .. "\n")
      io.write(memory_cell[j][i].logic_target .. "\n")
      io.write(memory_cell[j][i].rotation .. "\n")
    end
  end
  io.close(file)
end

function loadstate()
  local file = io.open(data_dir .. "justmat/foulplay.data", "r")
  if file then
    print("datafile found")
    io.input(file)
    for j = 1, 25 do
      for i = 1, 8 do
        memory_cell[j][i].k = tonumber(io.read())
        memory_cell[j][i].n = tonumber(io.read())
        memory_cell[j][i].prob = tonumber(io.read())
        memory_cell[j][i].trig_logic = tonumber(io.read())
        memory_cell[j][i].logic_target = tonumber(io.read())
        memory_cell[j][i].rotation = tonumber(io.read())
      end
    end
    io.close(file) 
  end
  for i = 1, 8 do reer(i) end
end
  
cleanup = function()
  savestate()
end
