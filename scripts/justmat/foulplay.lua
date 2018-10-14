-- euclidean sample instrument
-- with trigger conditions.
--
-- ----------
--
-- based on tehn/playfair,
-- with generous contributions
-- from junklight and okyeron.
--
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
-- key3 is alt.
--
-- alt + enc1 = mix volume
-- alt + enc2 = rotation
-- alt + enc3 = bpm
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
-- grid
-- ----------
--
-- col 1 select track edit
-- col 2 provides mute toggles
--
-- the dimly lit 5x5 grid is
-- made up of memory cells.
-- memory cells hold both
-- pattern and pset data.
-- simply pressing a cell
-- will load the pattern
-- data.
--
-- button 4 on row 7 starts
-- and stops the clock.
-- while the clock is stopped
-- the button will blink.
--
-- button 5 on row 7 is
-- the phase reset button.
--
-- button 8 on row 7 is
-- the pset load button.
--
-- to load a pset, press
-- and hold the pset load
-- button while touching
-- the desired memory cell.
--
-- open track edit pages
-- with grid buttons 4-7 on
-- the bottom row.
--
-- button 8 on the bottom row
-- is the copy button.
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

er = require 'er'

engine.name = 'Ack'

local g = grid.connect()
local m = midi.connect()

local ack = require 'jah/ack'
local BeatClock = require 'beatclock'

local clk = BeatClock.new()

local alt = 0
local reset = false
-- 0 == home, 1 == track edit
local view = 0
local page = 0
local track_edit = 1
local stopped = 1
local pset_load_mode = false
local current_pset = 0

-- a table of midi note on/off status i = 1/0
local note_off_queue = {}
for i = 1, 8 do
  note_off_queue[i] = 0
end

-- added for grid support - junklight
local current_mem_cell = 1
local current_mem_cell_x = 4
local current_mem_cell_y = 1
local copy_mode = false
local blink = false
local copy_source_x = -1
local copy_source_y = -1


function simplecopy(obj)
  if type(obj) ~= 'table' then return obj end
  local res = {}
  for k, v in pairs(obj) do
    res[simplecopy(k)] = simplecopy(v)
  end
  return res
end


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
      rotation = 0,
      mute = 0
  }
  end
end


local function gettrack( cell , tracknum )
  return memory_cell[cell][tracknum]
end


local function cellfromgrid( x , y )
  return (((y - 1) * 5) + (x -4)) + 1
end


local function rotate_pattern(t, rot, n, r)
  -- rotate_pattern comes to us via okyeron and stackexchange
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
    gettrack(current_mem_cell,i).s = rotate_pattern(er.gen(gettrack(current_mem_cell,i).k, gettrack(current_mem_cell,i).n), gettrack(current_mem_cell, i).rotation)
  end
end


local function trig()
  -- mute state is ignored for trigger logics
  for i, t in ipairs(memory_cell[current_mem_cell]) do
    -- no trigger logic
    if t.trig_logic==0 and t.s[t.pos]  then
      if math.random(100) <= t.prob and t.mute == 0 then
        if params:get(i.."send_midi") == 1 then
          engine.trig(i-1)
        else
          m.note_on(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
          note_off_queue[i] = 1
        end
      end
    else
      if note_off_queue[i] == 1 then
        m.note_off(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
        note_off_queue[i] = 0
      end
    end
    -- logical and
    if t.trig_logic == 1 then
      if t.s[t.pos] and gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos]  then
        if math.random(100) <= t.prob and t.mute == 0 then
          if params:get(i.."send_midi") == 1 then
            engine.trig(i-1)
          else
            m.note_on(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
            note_off_queue[i] = 1
          end
        else break end
      else
        if note_off_queue[i] == 1 then
          m.note_off(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
          note_off_queue[i] = 0
        end
      end
    -- logical or
    elseif t.trig_logic == 2 then
      if t.s[t.pos] or gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos] then
        if math.random(100) <= t.prob and t.mute == 0 then
          if params:get(i.."send_midi") == 1 then
            engine.trig(i-1)
          else
            m.note_on(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
            note_off_queue[i] = 1
          end
        else break end
      else
        if note_off_queue[i] == 1 then
          m.note_off(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
          note_off_queue[i] = 0
        end
      end
    -- logical nand
    elseif t.trig_logic == 3 then
      if t.s[t.pos] and gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos]  then
      elseif t.s[t.pos] then
        if math.random(100) <= t.prob and t.mute == 0 then
          if params:get(i.."send_midi") == 1 then
            engine.trig(i-1)
          else
            m.note_on(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
            note_off_queue[i] = 1
          end
        else break end
      else
        if note_off_queue[i] == 1 then
          m.note_off(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
          note_off_queue[i] = 0
        end
      end
    -- logical nor
    elseif t.trig_logic == 4 then
      if not t.s[t.pos] then
        if not gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos] and t.mute == 0 then
          if params:get(i.."send_midi") == 1 then
            engine.trig(i-1)
          else
            m.note_on(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
            note_off_queue[i] = 1
          end
        else break end
      else
        if note_off_queue[i] == 1 then
          m.note_off(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
          note_off_queue[i] = 0
        end
      end
    -- logical xor
    elseif t.trig_logic == 5 then
      if t.mute == 0 then
        if not t.s[t.pos] and not gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos] then
        elseif t.s[t.pos] and gettrack(current_mem_cell,t.logic_target).s[gettrack(current_mem_cell,t.logic_target).pos] then
        else
          if params:get(i.."send_midi") == 1 then
            engine.trig(i-1)
          else
            m.note_on(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
            note_off_queue[i] = 1
          end
          if note_off_queue[i] == 1 then
            m.note_off(params:get(i.."midi_note"), 100, params:get(i.."midi_chan"))
            note_off_queue[i] = 0
          end
        end
      else break end
    end
  end
end


function init()
  for i=1, 8 do reer(i) end

  screen.line_width(1)

  clk.on_step = step
  clk.on_select_internal = function() clk:start() end
  clk.on_select_external = reset_pattern

  -- add params
  clk:add_clock_params()
  params:add_separator()
  for i = 1, 8 do
    params:add_option(i.."send_midi", i..": send midi", {"no", "yes"}, 1)
    params:add_number(i.."midi_chan", i..": midi chan", 1, 16, 1)
    params:add_number(i.."midi_note", i..": midi note", 0, 127, 0)
    ack.add_channel_params(i)
    params:add_separator()
  end
  ack.add_effects_params()
  -- load default pset
  params:read("justmat/foulplay.pset")
  params:bang()
  -- load pattern data
  loadstate()

  if stopped==1 then
    clk:stop()
  else
    clk:start()
  end

  -- grid refresh timer, 15 fps
  metro_grid_redraw = metro.alloc(function(stage) grid_redraw() end, 1 / 15)
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
  -- home and track edit views
  if n==1 then view = z end
  if n==3 and z==1 and view==1 then
    if params:get(track_edit.."send_midi") == 1 then
      page = (page + 1) % 4
    -- there are only 2 pages of midi options
    else page = (page + 1) % 2 end
  end
  if n==3 then alt = z end
  -- track selection in track edit view
  if view==1 then
    if n==2 and z==1 then
      track_edit = (track_edit % 8) + 1
    end
  end

  if alt==1 then
    -- track phase reset
    if n==2 and z==1 then
      reset_pattern()
      if stopped == 1 then
          step()
      end
    end
  end
  -- home view. start/stop
  if alt==0 and view==0 then
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
  if alt==1 then
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
    -- only show the engine edit options if midi note send is off
    if params:get(track_edit.."send_midi") == 1 then
    -- per track volume control
      if n==1 then
        params:delta(track_edit .. "_vol", d)
      elseif n==2 then
        params:delta(track_edit .. "_vol_env_atk", d)
      elseif n==3 then
        params:delta(track_edit .. "_vol_env_rel", d)
      end
    -- if send midi is on
    else
      -- encoder 1 sets midi channel, 2 selects a note to send
      if n==1 then
        params:delta(track_edit .. "_midi_chan", d)
      elseif n==2 then
        params:delta(track_edit .. "_midi_note", d)
      end
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
      params:delta(track_edit .. "_speed", d)
    elseif n==2 then
      params:delta(track_edit .. "_start_pos", d)
    elseif n==3 then
      params:delta(track_edit .. "_end_pos", d)
    end

  elseif view==1 and page==3 then
    -- filter and fx sends
    if n==1 then
      params:delta(track_edit .. "_filter_cutoff", d)
    elseif n==2 then
      params:delta(track_edit .. "_delay_send", d)
    elseif n==3 then
      params:delta(track_edit .. "_reverb_send", d)
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
  if view==0 and alt==0 then
    for i=1, 8 do
      if gettrack(current_mem_cell, i).mute == 1 then
       screen.move(17,i*7.70)
       screen.text_center("m")
      end
      screen.level((i == track_edit) and 15 or 4)
      screen.move(8, i*7.70)
      screen.text_center(gettrack(current_mem_cell,i).k)
      screen.move(25,i*7.70)
      screen.text_center(gettrack(current_mem_cell,i).n)
      for x=1,gettrack(current_mem_cell,i).n do
        screen.level(gettrack(current_mem_cell,i).pos==x and 15 or 2)
        screen.move(x*3 + 32, i*7.70)
        if gettrack(current_mem_cell,i).s[x] then
          screen.line_rel(0,-6)
        else
          screen.line_rel(0,-2)
        end
        screen.stroke()
      end
    end
  elseif view==0 and alt==1 then
    screen.level(4)
    screen.move(0, 8 + 11)
    screen.text("vol")
    screen.move(0, 16 + 11)
    screen.text(string.format("%.1f", mix:get("output")))
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
        screen.move(x*3 + 32, i*7.70)
        if gettrack(current_mem_cell,i).s[x] then
          screen.line_rel(0,-6)
        else
          screen.line_rel(0,-2)
        end
        screen.stroke()
      end
    end

  elseif view==1 and page==0 then
    if params:get(track_edit.."send_midi") == 1 then
      screen.move(5, 10)
      screen.level(15)
      screen.text("track : " .. track_edit)
      screen.move(120, 10)
      screen.text_right("page " .. page + 1)
      screen.move(5, 15)
      screen.line(121, 15)
      screen.move(64, 25)
      screen.level(4)
      screen.text_center("1. vol : " .. string.format("%.1f", params:get(track_edit .. "_vol")))
      screen.move(64, 35)
      screen.text_center("2. envelope attack : " .. params:get(track_edit .. "_vol_env_atk"))
      screen.move(64, 45)
      screen.text_center("3. envelope release : " .. params:get(track_edit .. "_vol_env_rel"))
    else
      screen.move(5, 10)
      screen.level(15)
      screen.text("track : " .. track_edit)
      screen.move(120, 10)
      screen.text_right("page " .. page + 1)
      screen.move(5, 15)
      screen.line(121, 15)
      screen.move(64, 25)
      screen.level(4)
      screen.text_center("1. midi channel : " .. params:get(track_edit .. "_midi_chan"))
      screen.move(64, 35)
      screen.text_center("2. midi note : " .. params:get(track_edit .. "_midi_note"))
    end

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
    screen.text_center("1. speed : " .. params:get(track_edit .. "_speed"))
    screen.move(64, 35)
    screen.text_center("2. start pos : " .. params:get(track_edit .. "_start_pos"))
    screen.move(64, 45)
    screen.text_center("3. end pos : " .. params:get(track_edit .. "_end_pos"))

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
    screen.text_center("1. filter cutoff : " .. math.floor(params:get(track_edit .. "_filter_cutoff") + 0.5))
    screen.move(64, 35)
    screen.text_center("2. delay send : " .. params:get(track_edit .. "_delay_send"))
    screen.move(64, 45)
    screen.text_center("3. reverb send : " .. params:get(track_edit .. "_reverb_send"))
  end
  screen.stroke()
  screen.update()
end


midi.add = function(dev)
  dev.event = clk.process_midi
  print("foulplay: midi device added", dev.id, dev.name)
end

-- grid stuff - junklight

function g.event(x, y, state)
  -- use first column to switch track edit
  if x == 1 then
    track_edit = y
  end
  -- second column provides mutes
  if x == 2 and state == 1 then
    if gettrack(current_mem_cell, y).mute == 0 then
      gettrack(current_mem_cell, y).mute = 1
    elseif gettrack(current_mem_cell, y).mute == 1 then
      gettrack(current_mem_cell, y).mute = 0
    end
  end
  -- x 4-6, are used to open track parameters pages
  if y == 8 and x >= 4 and x <= 7 and state == 1 then
    view = 1
    page = x - 4
  else
    view = 0
  end
  -- start and stop button.
  if x == 4 and y == 7 and state == 1 then
    if stopped == 1 then
      clk:start()
      stopped = 0
    else
      clk:stop()
      stopped = 1
    end
  end
  -- reset button
  if x == 5 and y == 7 and state == 1 then
    reset_pattern()
    if stopped == 1 then
      step()
    end
  end
  -- set pset load button
  if x == 8 and y == 7 and state == 1 then
    pset_load_mode = true
  elseif x == 8 and y == 7 and state == 0 then
    pset_load_mode = false
  end
  -- load pset 1-25
  if pset_load_mode then
    if y >= 1 and y <= 5 and x >= 4 and x <= 8 and state == 1 then
      params:read("justmat/foulplay-" .. string.format("%02d", cellfromgrid(x, y)) .. ".pset")
      params:bang()
      print("loaded pset " .. cellfromgrid(x, y))
      current_pset = cellfromgrid(x, y)
      -- if you were stopped before loading, stay stopped after loading
      if stopped == 1 then
        clk:stop()
      end
    end
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
  -- switches on grid down
  if not copy_mode and not pset_load_mode then
    if y >= 1 and y <= 5 and x >= 4 and x <= 8 and state == 1 then
      current_mem_cell = cellfromgrid(x,y)
      current_mem_cell_x = x
      current_mem_cell_y = y
      for i = 1, 8 do reer(i) end
    end
  else
    if y >= 1 and y <= 5 and x >= 4 and x <= 8 and state == 0 then
      if not pset_load_mode then
        -- copy functionality
        if copy_source_x == -1 then
          -- first button sets the source
          copy_source_x = x
          copy_source_y = y
        else
          -- second button copies source into target
          if copy_source_x ~= -1 and not ( copy_source_x == x and copy_source_y == y) then
            sourcecell = cellfromgrid( copy_source_x , copy_source_y )
            targetcell = cellfromgrid( x , y )
            memory_cell[targetcell] = simplecopy(memory_cell[sourcecell])
          end
        end
      end
    end
  end
  redraw()
end


function grid_redraw()
  if g == nil then
    -- bail if we are too early
    return
  end
  g.all(0)
  -- highlight current track
  g.led(1, track_edit, 15)
  -- track edit page buttons
  for page = 0, 3 do
      g.led(page + 4, 8, 3)
  end
  -- highlight page if open
  if view == 1 then
    g.led(page + 4, 8, 14)
  end
  -- mutes - bright for on, dim for off
  for i = 1,8 do
    if gettrack(current_mem_cell, i).mute == 1 then
      g.led(2, i, 15)
    else g.led(2, i, 4)
    end
  end
  -- memory cells
  for x = 4,8 do
    for y = 1,5 do
      g.led(x, y, 3)
    end
  end
  -- highlight active cell
  g.led(current_mem_cell_x, current_mem_cell_y, 15)
  if copy_mode then
    -- copy mode - blink the source if set
    if copy_source_x ~= -1 then
      if blink then
        g.led(copy_source_x, copy_source_y, 4)
      else
        g.led(copy_source_x, copy_source_y, 12)
      end
    end
  end
  -- start/stop
  if stopped == 0 then
    g.led(4, 7, 15)
  elseif stopped == 1 then
    if blink then
      g.led(4, 7, 4)
    else
      g.led(4, 7, 12)
    end
  end
  -- reset button
  g.led(5, 7, 3)
  -- load pset button
  if pset_load_mode then
    g.led(8, 7, 12)
  else g.led(8, 7, 3) end
  -- copy button
  if copy_mode  then
    g.led(8, 8, 14)
  else
    g.led(8, 8, 3)
  end
  g.refresh()
end


function savestate()
  local file = io.open(data_dir .. "justmat/foulplay-pattern.data", "w+")
  io.output(file)
  io.write("v1" .. "\n")
  for j = 1, 25 do
    for i = 1, 8 do
      io.write(memory_cell[j][i].k .. "\n")
      io.write(memory_cell[j][i].n .. "\n")
      io.write(memory_cell[j][i].prob .. "\n")
      io.write(memory_cell[j][i].trig_logic .. "\n")
      io.write(memory_cell[j][i].logic_target .. "\n")
      io.write(memory_cell[j][i].rotation .. "\n")
      io.write(memory_cell[j][i].mute .. "\n")
    end
  end
  io.close(file)
end

function loadstate()
  local file = io.open(data_dir .. "justmat/foulplay-pattern.data", "r")
  if file then
    print("datafile found")
    io.input(file)
    if io.read() == "v1" then
      for j = 1, 25 do
        for i = 1, 8 do
          memory_cell[j][i].k = tonumber(io.read())
          memory_cell[j][i].n = tonumber(io.read())
          memory_cell[j][i].prob = tonumber(io.read())
          memory_cell[j][i].trig_logic = tonumber(io.read())
          memory_cell[j][i].logic_target = tonumber(io.read())
          memory_cell[j][i].rotation = tonumber(io.read())
          memory_cell[j][i].mute = tonumber(io.read())
        end
      end
    else
      print("invalid data file")
    end
    io.close(file)
  end
  for i = 1, 8 do reer(i) end
end


cleanup = function()
  savestate()
end
