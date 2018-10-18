-- FM7
--
-- FM polysynth
-- controlled by grid or MIDI
--
-- grid pattern player:
-- 1 1 record toggle
-- 1 2 play toggle
-- 1 8 transpose mode
-- enc 1: change presets
-- key 2: random modulation matrix
-- key 3: play a random note

local FM7 = require 'lazzarello/fm7'
local tab = require 'tabutil'
local pattern_time = require 'pattern_time'
local UI = require 'mark_eats/ui'

local g = grid.connect()

local mode_transpose = 0
local root = { x=5, y=5 }
local trans = { x=5, y=5 }
local lit = {}
local encoder_mode = 1

local screen_framerate = 15
local screen_refresh_metro

local MAX_NUM_VOICES = 16

engine.name = 'FM7'

-- pythagorean minor/major, kinda
local ratios = { 1, 9/8, 6/5, 5/4, 4/3, 3/2, 27/16, 16/9 }
local base = 27.5 -- low A

local function getHz(deg,oct)
  return base * ratios[deg] * (2^oct)
end

local function getHzET(note)
  return 55*2^(note/12)
end
-- current count of active voices
local nvoices = 0

local function getEncoderMode()
  return encoder_mode
end

local function setEncoderMode(mode)
  encoder_mode = mode
end


local ctrl_functions = {
  function(arg) engine.hz1(arg) end,
  function(arg) engine.hz2(arg) end,
  function(arg) engine.hz3(arg) end,
  function(arg) engine.hz4(arg) end,
  function(arg) engine.hz5(arg) end,
  function(arg) engine.hz6(arg) end,
  function(arg) engine.phase1(arg) end,
  function(arg) engine.phase2(arg) end,
  function(arg) engine.phase3(arg) end,
  function(arg) engine.phase4(arg) end,
  function(arg) engine.phase5(arg) end,
  function(arg) engine.phase6(arg) end,
  function(arg) engine.amp1(arg) end,
  function(arg) engine.amp2(arg) end,
  function(arg) engine.amp3(arg) end,
  function(arg) engine.amp4(arg) end,
  function(arg) engine.amp5(arg) end,
  function(arg) engine.amp6(arg) end,
}

function init()
  pat = pattern_time.new()
  pat.process = grid_note_trans

  engine.amp(0.05)
  engine.stopAll()

  FM7.add_params()

  --params:read("tehn/earthsea.pset")
  --params:bang()

  if g then gridredraw() end

  screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function(stage)
    redraw()
  end
  screen_refresh_metro:start(1 / screen_framerate)

  local startup_ani_count = 1
  local startup_ani_metro = metro.alloc()
  startup_ani_metro.callback = function(stage)
    startup_ani_count = startup_ani_count + 1
  end
  startup_ani_metro:start( 0.1, 3 )
  ph_position,hz_position,amp_position = 0,0,0
  selected = {}
  mods = {}
  carriers = {}
  for m = 1,6 do
    selected[m] = {}
    mods[m] = {}
    carriers[m] = 0
    for n = 1,6 do
      selected[m][n] = 0
      mods[m][n] = 0
    end
  end
  light = 0
  number = 3
  
  pages = UI.Pages.new(1, 33)
end

function g.event(x, y, z)
  if x == 1 and (y > 2 and y < 8) then
    if z == 1 and getEncoderMode() == y - 1 then
      setEncoderMode(1)
    elseif z == 1 then
      setEncoderMode(y - 1) 
    end
  end

  if x == 1 then
    if z == 1 then
      if y == 1 and pat.rec == 0 then
        mode_transpose = 0
        trans.x = 5
        trans.y = 5
        pat:stop()
        engine.stopAll()
        pat:clear()
        pat:rec_start()
      elseif y == 1 and pat.rec == 1 then
        pat:rec_stop()
        if pat.count > 0 then
          root.x = pat.event[1].x
          root.y = pat.event[1].y
          trans.x = root.x
          trans.y = root.y
          pat:start()
        end
      elseif y == 2 and pat.play == 0 and pat.count > 0 then
        if pat.rec == 1 then
          pat:rec_stop()
        end
        pat:start()
      elseif y == 2 and pat.play == 1 then
        pat:stop()
        engine.stopAll()
        nvoices = 0
        lit = {}
      elseif y == 8 then
        mode_transpose = 1 - mode_transpose
      end
    end
  else
    if mode_transpose == 0 then
      local e = {}
      e.id = x*8 + y
      e.x = x
      e.y = y
      e.state = z
      pat:watch(e)
      grid_note(e)
    else
      trans.x = x
      trans.y = y
    end
  end
  gridredraw()
end

function grid_note(e)
  local note = ((7-e.y)*5) + e.x
  if e.state > 0 then
    if nvoices < MAX_NUM_VOICES then
      --engine.start(id, getHz(x, y-1))
      --print("grid > "..id.." "..note)
      engine.start(e.id, getHzET(note))
      lit[e.id] = {}
      lit[e.id].x = e.x
      lit[e.id].y = e.y
      nvoices = nvoices + 1
    end
  else
    if lit[e.id] ~= nil then
      engine.stop(e.id)
      lit[e.id] = nil
      nvoices = nvoices - 1
    end
  end
  gridredraw()
end

function grid_note_trans(e)
  local note = ((7-e.y+(root.y-trans.y))*5) + e.x + (trans.x-root.x)
  if e.state > 0 then
    if nvoices < MAX_NUM_VOICES then
      --engine.start(id, getHz(x, y-1))
      --print("grid > "..id.." "..note)
      engine.start(e.id, getHzET(note))
      lit[e.id] = {}
      lit[e.id].x = e.x + trans.x - root.x
      lit[e.id].y = e.y + trans.y - root.y
      nvoices = nvoices + 1
    end
  else
    engine.stop(e.id)
    lit[e.id] = nil
    nvoices = nvoices - 1
  end
  gridredraw()
end

local function toggleModLED(mode)
  if mode ~= 1 then
    g.led(1,mode + 1,12)
  end
end

function gridredraw()
  g.all(0)
  g.led(1,1,2 + pat.rec * 10)
  g.led(1,2,2 + pat.play * 10)
  g.led(1,8,2 + mode_transpose * 10)
  toggleModLED(getEncoderMode())

  if mode_transpose == 1 then g.led(trans.x, trans.y, 4) end
  for i,e in pairs(lit) do
    g.led(e.x, e.y,15)
  end

  g:refresh()
end

function enc(n,delta)
  if n == 1 then
    pages:set_index_delta(delta, true)
    --print("set algo ".. (pages.index - 1))
    if (pages.index - 1) < 10 then
      params:read("lazzarello/fm7-0".. (pages.index - 1) .. ".pset")
    else
      params:read("lazzarello/fm7-".. (pages.index - 1) .. ".pset")
    end
  elseif n == 2 then
    print("encoder 2")

  elseif n == 3 then
    print("encoder 3")
  end
end

function key(n,z)
  if n == 2 and z== 1 then
    -- clear selected
    for x = 1,6 do
      for y = 1,6 do
        selected[x][y] = 0
        mods[x][y] = 0
        carriers[x] = 0
        params:set("hz"..x.."_to_hz"..y,mods[x][y])
      end
      params:set("carrier"..x,carriers[x])
    end
    
    -- choose new random mods
    for i = 1,number do
      x = math.random(6)
      y = math.random(6)
      selected[x][y] = 1
      mods[x][y] = 1 
      carriers[x] = 1
      params:set("hz"..x.."_to_hz"..y,mods[x][y])
      params:set("carrier"..x,carriers[x])
    end
  end
  redraw()
  if n == 3 then
    local note = ((7-math.random(8))*5) + math.random(16)
    if z == 1 then
      if nvoices < MAX_NUM_VOICES then
      --engine.start(id, getHz(x, y-1))
      --print("grid > "..id.." "..note)
        engine.start(0, getHzET(note))
        nvoices = nvoices + 1
      end
    else
      engine.stop(0)
      nvoices = nvoices - 1
    end
  end
end

local function draw_matrix_outputs()
  for m = 1,6 do
    for n = 1,6 do
      screen.rect(m*9, n*9, 9, 9)

      l = 2
      if selected[m][n] == 1 then
        l = l + 3 + light
      end
      screen.level(l)
      screen.move_rel(2, 6)
      screen.text(mods[m][n])
      screen.stroke()
    end
  end
  for m = 1,6 do
    screen.rect(80,m*9,9,9)
    screen.move_rel(12, 6)
    screen.text("out "..m)
    screen.move_rel(-32,0)
    screen.text(carriers[m])
    screen.stroke()    
  end  
end

local function draw_algo_rel(num)
    -- my first try was clever but not really intuitive.
    -- keeping it for posterity.
    screen.move(0,10)
    screen.text("algo "..num)
    local size = 9
    local x = 32
    local y = 5
    local spacing = 16
    local text_coords = {2,6}
    screen.rect(x,y,size,size)
    screen.move_rel(text_coords[1], text_coords[2])
    screen.text(6)
    y = y + spacing
    screen.rect(x,y,size,size)
    screen.move_rel(text_coords[1], text_coords[2])
    screen.text(5)
    y = y + spacing
    screen.rect(x,y,size,size)
    screen.move_rel(text_coords[1], text_coords[2])
    screen.text(4)
    y = y + spacing
    screen.rect(x,y,size,size)
    screen.move_rel(text_coords[1], text_coords[2])
    screen.text(3)
    x = x - spacing
    screen.rect(x,y,size,size)
    screen.move_rel(text_coords[1], text_coords[2])
    screen.text(1)
    y = y - spacing
    screen.rect(x,y,size,size)
    screen.move_rel(text_coords[1], text_coords[2])
    screen.text(2)
    screen.stroke()
end
local algo_box_coords = 
  {
--[[
absolute coords for operator box positions
 5|
21|
37|
53|__ __ __ __ __ ___
   32 48 64 80 96 112
   
    tuples in table are {x coord, y coord, connection_index,feedback_index}
--]]
    {{48,53,0,0},{48,37,1,0},{64,53,0,0},{64,37,3,0},{64,21,4,0},{64,5,5,6}},
    {{48,53,0,0},{48,37,1,2},{64,53,0,0},{64,37,3,0},{64,21,4,0},{64,5,5,0}},
    {{48,53,0,0},{48,37,1,0},{48,21,2,0},{64,53,0,0},{64,37,4,0},{64,21,5,6}},
    {{48,53,0,0},{48,37,1,0},{48,21,2,0},{64,53,0,6},{64,37,4,0},{64,21,5,0}},
    {{48,53,0,0},{48,37,1,0},{64,53,0,0},{64,37,3,0},{80,53,0,0},{80,37,5,6}},
    {{48,53,0,0},{48,37,1,0},{64,53,0,0},{64,37,3,0},{80,53,0,6},{80,37,5,0}},
    {{48,53,0,0},{48,37,1,0},{64,53,0,0},{64,37,3,0},{80,37,3,0},{80,21,5,6}},
    {{48,53,0,0},{48,37,1,0},{64,53,0,0},{64,37,3,4},{80,37,3,0},{80,21,5,0}},
    {{48,53,0,0},{48,37,1,2},{64,53,0,0},{64,37,3,0},{80,37,3,0},{80,21,5,0}},
    {{48,53,0,0},{48,37,1,0},{48,21,2,3},{64,53,0,0},{80,37,4,0},{64,37,4,0}},
    {{48,53,0,0},{48,37,1,0},{48,21,2,0},{64,53,0,0},{80,37,4,0},{64,37,4,6}},
    {{32,53,0,0},{32,37,1,2},{64,53,0,0},{48,37,3,0},{64,37,3,0},{80,37,3,0}},
    {{32,53,0,0},{32,37,1,0},{64,53,0,0},{48,37,3,0},{64,37,3,0},{80,37,3,6}},
    {{32,53,0,0},{32,37,1,0},{64,53,0,0},{64,37,3,0},{80,37,4,0},{64,21,4,6}},
    {{32,53,0,0},{32,37,1,2},{64,53,0,0},{64,37,3,0},{80,37,4,0},{64,21,4,0}},
    {{64,53,0,0},{48,37,1,0},{64,37,1,0},{64,21,3,0},{80,37,1,0},{80,21,5,6}},
    {{64,53,0,0},{48,37,1,2},{64,37,1,0},{64,21,3,0},{80,37,1,0},{80,21,5,0}},
    {{64,53,0,0},{48,37,1,0},{64,37,1,3},{80,37,1,0},{80,21,4,0},{80,5,5,0}},
    {{48,53,0,0},{48,37,1,0},{48,21,2,0},{64,53,0,0},{80,53,0,0},{64,37,{4,5},6}},
    {{32,53,0,0},{48,53,0,0},{32,37,{1,2},3},{80,53,0,0},{64,37,4,0},{80,37,4,0}},
    {{32,53,0,0},{48,53,0,0},{32,37,{1,2},3},{64,53,0,0},{80,53,0,0},{64,37,{4,5},0}},
    {{32,53,0,0},{32,37,1,0},{48,53,0,0},{64,53,0,0},{80,53,0,0},{64,37,{3,4,5},6}},
    {{32,53,0,0},{48,53,0,0},{48,37,3,0},{64,53,0,0},{80,53,0,0},{64,37,{4,5},6}},
    {{32,53,0,0},{48,53,0,0},{64,53,0,0},{80,53,0,0},{96,53,0,0},{80,37,{3,4,5},6}},
    {{32,53,0,0},{48,53,0,0},{64,53,0,0},{80,53,0,0},{96,53,0,0},{80,37,{4,5},6}},
    {{32,53,0,0},{48,53,0,0},{48,37,2,3},{80,53,0,0},{64,37,4,0},{80,37,4,0}},
    {{32,53,0,0},{48,53,0,0},{48,37,2,3},{80,53,0,0},{64,37,4,0},{80,37,4,0}},
    {{48,53,0,0},{48,37,1,0},{64,53,0,0},{64,37,3,0},{64,21,4,5},{80,53,0,0}},
    {{32,53,0,0},{48,53,0,0},{64,53,0,0},{64,37,3,0},{80,53,0,0},{80,37,5,6}},
    {{32,53,0,0},{48,53,0,0},{64,53,0,0},{64,37,3,0},{64,21,4,5},{80,53,0,0}},
    {{32,53,0,0},{48,53,0,0},{64,53,0,0},{80,53,0,0},{96,53,0,0},{96,37,5,6}},
    {{32,53,0,0},{48,53,0,0},{64,53,0,0},{80,53,0,0},{96,53,0,0},{112,53,0,6}}
  }

local function draw_algo(num)
    screen.move(0,10)
    screen.text("algo "..num)
    local size = 9
    local text_coords = {2,6}
  for a = 1,6 do
    local x = algo_box_coords[num][a][1]
    local y = algo_box_coords[num][a][2]
    local conn = algo_box_coords[num][a][3]
    local fb = algo_box_coords[num][a][4]
    if type(conn) == "number" then
      if conn > 0 then
        -- this is a line going down to the next box
        -- need a line going across to the next box
        -- and a line feedbacking to an arbitrary box
        screen.move(x+size/2,y+size)
        screen.line(x+size/2,y+16)
      end
    end
    screen.rect(x,y,size,size)
    screen.move_rel(text_coords[1], text_coords[2])
    screen.text(a)
    screen.stroke()
  end
end

function redraw()
  screen.clear()
  pages:redraw()
  
  if pages.index == 1 then
    draw_matrix_outputs()
  else
    draw_algo(pages.index - 1)
  end

  screen.update()
end

local function note_on(note, vel)
  if nvoices < MAX_NUM_VOICES then
    --engine.start(id, getHz(x, y-1))
    engine.start(note, getHzET(note))
    nvoices = nvoices + 1
  end
end

local function note_off(note, vel)
  engine.stop(note)
  nvoices = nvoices - 1
end

local function midi_event(data)
  if data[1] == 144 then
    if data[3] == 0 then
      note_off(data[2])
    else
      note_on(data[2], data[3])
    end
  elseif data[1] == 128 then
    note_off(data[2])
  elseif data[1] == 176 then
    --cc(data1, data2)
  elseif data[1] == 224 then
    --bend(data1, data2)
  end
end

midi.add = function(dev)
  print('earthsea: midi device added', dev.id, dev.name)
  dev.event = midi_event
end

function cleanup()
  pat:stop()
  pat = nil
end
