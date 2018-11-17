-- Ekombi
--
--  polyrhythmic sampler
--
--
-- 4, two-track channels
-- ------------------------------------------
-- trackA: sets the length
-- of the tuplet
--
-- trackB: sets length of the
-- 'measure' in quarter notes
-- -------------------------------------------
--
-- grid controls
-- ---------------------------------
-- hold a key and press another
-- key in the same row to set
-- the length of the track
--
-- tapping gridkeys toggles the
-- tuplet subdivisions and
-- quarter notes on/off
-- -------------------------------------------
--
-- norns controls
-- -------------------------------------------
-- enc1: bpm
-- enc2: select pattern
-- enc3: filter cutoff
--
-- key1: save pattern
-- key2: load pattern
-- key3: stop clock
-- ---------------------------------------------

engine.name = 'Ack'

local ack = require 'jah/ack'

local g = grid.connect()

--[[whats next?:
                - enc3 meter
                - patterns display on screen before loading for a set amount of time,
                  then returns to displaying current grid pattern
                - continue optimizing
                - beatclock integration for midi sync
]]--

--[[current issues:
                  - are rhythms totally accurate?
--]]



------------
-- variables
------------



-- clocking variables
position = 0
q_position = 0
bpm = 60
counter = nil
running = false
ppq =  480 -- pulses per quarter, lower this if you come across performance issues.

-- pattern variables
pattern_select = 1

-- display variables
pattern_display = "default"
meter_display = 47

-- grid variables
-- for holding one gridkey and pressing another further right
held = {}
heldmax = {}
done = {}
first = {}
second = {}
for row = 1,8 do
  held[row] = 0
  heldmax[row] = 0
  done[row] = 0
  first[row] = 0
  second[row] = 0
end

-- 4, two-track channels (A is even rows, TrackB is odd rows)
track = {}
for i=1,8 do
  if i % 2 == 1 then
    track[i] = {}
    track[i][1] = {}
    track[i][1][1] = 0
  else
    track[i] = {}
    for n=1, 16 do
      track[i][n] = {}
      for j=1, 16 do
        track[i][n][j] = 1
      end
    end
  end
end



----------------
-- initilization
----------------



function init()

  -- parameters
  params:add_number("bpm", "bpm", 15, 400, 60)

  ack.add_effects_params()

  for channel=1,4 do
    ack.add_channel_params(channel)
  end

  params:read("tyler/ekombi.pset")

  -- metronome setup
  counter = metro.alloc()
  counter.time = 60 / (params:get("bpm") * ppq)
  counter.count = -1
  counter.callback = count
  -- counter:start()

  gridredraw()
  redraw()
end



-------------------------
-- grid control functions
-------------------------



function g.event(x, y, z)
  -- sending data to two separate functions
  gridkeyhold(x,y,z)
  gridkey(x,y,z)
end

function gridkey(x,y,z)
  if z == 1 then
  cnt = tab.count(track[y])

    -- error control
    if cnt == 0 or cnt == nil then
      if x > 1 then
        return
      elseif x == 1 then
          track[y] = {}
          track[y][x] = {}
          track[y][x][x] = 1
        gridredraw()
      end
      return

    else
      -- track-B un-reset-able
      if x == 16 and y % 2 == 1 then
        track[y] = {}
        track[y][1] = {}
        track[y][1][1] = 0
        return
      end

      -- note toggle on/off
      if x > cnt then
        return
      else
        if track[y][cnt][x] == 1 then
          track[y][cnt][x] = 0
        else
          track[y][cnt][x] = 1
        end
      end

      -- automatic clock startup
      if running == false then
        counter:start()
        running = true
      end

    end
  end
  redraw()
  gridredraw()
end



function gridkeyhold(x, y, z)
  if z == 1 and held[y] then heldmax[y] = 0 end
  held[y] = held[y] + (z*2 -1)

  if held[y] > heldmax[y] then heldmax[y] = held[y] end

  if y > 8 and held[y] == 1 then
      first[y] = x
  elseif y <= 8 and held[y] == 2 then
    second[y] = x
  elseif z == 0 then
    if y <= 8 and held[y] == 1 and heldmax[y] == 2 then
      track[y] = {}
      for i = 1, second[y] do
        track[y][i] = {}
        for n=1, i do
          track[y][i][n] = 1
        end
      end
    end
  end

  redraw()
  gridredraw()
end



---------------------------
-- norns control functions
---------------------------



function enc(n,d)
  if n == 1 then
    params:delta("bpm",d)
  end

  if n == 2 then
    pattern_select = util.clamp(pattern_select + d, 1, 16)
    print("pattern:"..pattern_select)
  end

  if n == 3 then
    for i=1, 4 do
      params:delta(i..": filter cutoff", d)
      --print(d, params:get(i..": filter cutoff"))
    end
    --meter_display = util.clamp(meter_display + d/100, 0, 47)
  end

redraw()
end

function key(n,z)

  if z == 1 then

    if n == 1 then
      save_pattern()
    end

    if n == 2 then
      load_pattern()
      pattern_display = pattern_select
    end

    if n == 3 then
      if running then
        counter:stop()
        running = false
      else
        position = 0
        counter:start()
        running = true
      end
    end

  end

gridredraw()
redraw()
end
------------------
-- active functions
-------------------

--[[
    this is the heart of polyrhythm generating, each track is checked to see which note divisions are on or off,
    first, the B track is checked (the 'quarter' note, before the tuplet division) then if the note is on, we check
    each of the subdivisions, and if those turn out to be on, the nth subdivision of the tuple of the track is triggered.
    The complicated divisons and multiplations of each of the track sets and subsets is to find the exact position value,
    that when / by that value returns n-1, the track triggers.
]]--


function count(c)
  position = (position + 1) % (ppq)
  counter.time = 60 / (params:get("bpm") * ppq)
  if position == 0 then
    q_position = q_position + 1
    fast_gridredraw()
  end

  pending = {}
  for i=2, 8, 2 do
    cnt = tab.count(track[i])
    if cnt == 0 or cnt == nil then
      return
    else
      if track[i][cnt][(q_position%cnt)+1] == 1 then
        table.insert(pending,i-1)
      end
    end
  end

  if tab.count(pending) > 0 then
    for i=1, tab.count(pending) do
      cnt = tab.count(track[pending[i]])
      if cnt == 0 or cnt == nil then
        return
      else
        for n=1, cnt do
          if position / ( ppq // (tab.count(track[pending[i]][cnt]))) == n-1 then
            if track[pending[i]][cnt][n] == 1 then
              engine.trig(pending[i]//2) -- samples are only 0-3
            end
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
    -- grid pattern preset display
    for i=1, 8 do
      for n=1, tab.count(track[i]) do
        if track[i][tab.count(track[i])][n] == 1 then
          screen.rect((n-1)*7, 1 + i*7, 6, 6)
          screen.fill()
          screen.move(tab.count(track[i])*7, i*7 + 7)
          screen.text(tab.count(track[i]))
        else
          screen.rect(1 + (n-1)*7, 2 + i*7, 5, 5)
          screen.stroke()
          screen.move(tab.count(track[i])*7, 7 + i*7)
          screen.text(tab.count(track[i]))
        end
      end
    end

    -- meter display
    --screen.rect(124,56,3,-meter_display)
    --screen.fill()

    -- param display
    screen.move(0,5)
    screen.text("bpm:"..params:get("bpm"))
    screen.move(64,5)
    screen.level(15)
    screen.text_center("pattern:"..pattern_select)

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

  screen.level(1)
    -- currently selected pattern
    screen.move(128,5)
    screen.text_right(pattern_display)

    --[[ meter outline
    screen.rect(124, 9, 4, 47)
    screen.move(124, 32)
    screen.line_rel(3,0)
    screen.move(124, 33)
    screen.line_rel(3,0)
    screen.stroke()
    --]]

screen.update()
end

function gridredraw()
  g.all(0)

  -- draw channels with sub divisions on/off
  for i=1, 8 do
    for n=1, tab.count(track[i]) do
      ct = tab.count(track[i])
      if ct == 0 or nil then return
      else
        if i % 2 == 1 then
          if track[i][ct][n] == 1 then
            g.led(n, i, 12)
          else
            g.led(n, i, 4)
          end

        elseif i % 2 == 0 then
          if track[i][ct][n] == 1 then
            g.led(n, i, 8)
          else
            g.led(n, i, 2)
          end
          g.led((q_position % ct) + 1, i, 15)
        end
      end
    end
  end

g.refresh()
end

function fast_gridredraw()

  for i=1, 8 do
    for n=1, tab.count(track[i]) do
      ct = tab.count(track[i])
      if ct == 0 or nil then return
      else
        if i % 2 == 0 then
          if track[i][ct][n] == 1 then
            g.led(n, i, 8)
          else
            g.led(n, i, 2)
          end
          g.led((q_position % ct) + 1, i, 15)
        end
      end
    end
  end

g.refresh()
end



------------------
-- save/load functions
----------------------


-- each pattern takes up 136 lines of data
-- 1 :first line is the length of the track
-- 1 :ON following lines display on/off state
-- 0 :OFF
-- 00:NIL following 16-n lines are nil values
--
function save_pattern()
  local count = 0
  local file = io.open(data_dir .. "tyler/ekombi.data", "r+")
  io.output(file)
  for l=1, ((pattern_select - 1) * 136) do
      file:read("*line")
  end
    for i = 1, 8 do
      count = tab.count(track[i])
      if count == nil then
        io.close(file)
        return
      end
      io.write(count .. "\n")
      for n=1, count do
        io.write(track[i][count][n] .. "\n")
      end
      for n=1, 16 - count do
          io.write("00\n")
      end
    end
  print("SAVE COMPLETE")
  io.close(file)
end

function load_pattern()
  local tracklen = 0
  local file = io.open(data_dir .. "tyler/ekombi.data", "r")
  if file then
    print("datafile found")
    io.input(file)
    for l=1, ((pattern_select - 1) * 136) do
      file:read("*line")
    end
    for i = 1, 8 do
      track[i] = {}
      tracklen = tonumber(io.read("*line"))
      for n=1, tracklen do
        track[i][n] = {}
      end
      for j=1, tracklen do
        track[i][tracklen][j] = tonumber(io.read("*line"))
      end
      for m = 1, 16 - tab.count(track[i]) do
        io.read("*line")
      end
    end

    print("LOAD COMPLETE")
    io.close(file)
  end
end
