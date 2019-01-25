-- step.
-- sample based step sequencer
-- controlled by grid
-- 
-- key2 = stop sequencer
-- key3 = play sequencer
-- enc2 = tempo
-- enc3 = swing amount
-- 
-- grid = edit trigs
-- 
engine.name = 'Ack'

local ControlSpec = require 'controlspec'
local Grid = require 'grid'
local Metro = require 'metro'
local Ack = require 'jah/ack'

local TRIG_LEVEL = 15
local PLAYPOS_LEVEL = 7
local CLEAR_LEVEL = 0

local grid_device

local tempo_spec = ControlSpec.new(20, 300, ControlSpec.WARP_LIN, 0, 120, "BPM")
local swing_amount_spec = ControlSpec.new(0, 100, ControlSpec.WARP_LIN, 0, 0, "%")

local NUMPATTERNS = 99
local MAXWIDTH = 16
local HEIGHT = 8
local gridwidth = MAXWIDTH
local playing = false
local queued_playpos
local playpos = -1
local timer

local ppqn = 24 
local ticks
local ticks_to_next
local odd_ppqn
local even_ppqn

local trigs = {}

local function set_trig(patternno, x, y, value)
  trigs[patternno*MAXWIDTH*HEIGHT + y*MAXWIDTH + x] = value
end

local function trig_is_set(patternno, x, y)
  return trigs[patternno*MAXWIDTH*HEIGHT + y*MAXWIDTH + x]
end

local function save_patterns()
  local fd=io.open(data_dir .. "jah/step.data","w+")
  io.output(fd)
  for patternno=1,NUMPATTERNS do
    for y=1,HEIGHT do
      for x=1,MAXWIDTH do
        local int
        if trig_is_set(patternno, x, y) then
          int = 1
        else
          int = 0
        end
        io.write(int .. "\n")
      end
    end
  end
  io.close(fd)
end

local function load_patterns()
  local fd=io.open(data_dir .. "jah/step.data","r")
  if fd then
    print("found datafile")
    io.input(fd)
    for patternno=1,NUMPATTERNS do
      for y=1,HEIGHT do
        for x=1,MAXWIDTH do
          set_trig(patternno, x, y, tonumber(io.read()) == 1)
        end
      end   
    end
    io.close(fd)
  end
end  

local function refresh_grid_button(x, y, refresh)
  if grid_device then
    if params:get("last_row_cuts") == 2 and y == 8 then
      if x-1 == playpos then
        grid_device:led(x, y, PLAYPOS_LEVEL)
      else
        grid_device:led(x, y, CLEAR_LEVEL)
      end
    else
      if trig_is_set(params:get("pattern"), x, y) then
        grid_device:led(x, y, TRIG_LEVEL)
      elseif x-1 == playpos then
        grid_device:led(x, y, PLAYPOS_LEVEL)
      else
        grid_device:led(x, y, CLEAR_LEVEL)
      end
    end
    if refresh then
      grid_device:refresh()
    end
  end
end

local function refresh_grid_column(x, refresh)
  if grid_device then
    for y=1,HEIGHT do
      refresh_grid_button(x, y, false)
    end
    if refresh then
      grid_device:refresh()
    end
  end
end

local function refresh_grid()
  if grid_device then
    for x=1,MAXWIDTH do
      refresh_grid_column(x, false)
    end
    grid_device:refresh()
  end
end

local function is_even(number)
  return number % 2 == 0
end

local function tick()
  ticks = (ticks or -1) + 1

  if queued_playpos and params:get("cut_quant") == 1 then
    ticks_to_next = 0
  end

  if (not ticks_to_next) or ticks_to_next == 0 then
    local previous_playpos = playpos
    if queued_playpos then
      playpos = queued_playpos
      queued_playpos = nil
    else
      playpos = (playpos + 1) % gridwidth
    end
    local ts = {}
    for y=1,8 do
      if trig_is_set(params:get("pattern"), playpos+1, y) and not (params:get("last_row_cuts") == 2 and y == 8) then
        ts[y] = 1
      else
        ts[y] = 0
      end
    end
    engine.multiTrig(ts[1], ts[2], ts[3], ts[4], ts[5], ts[6], ts[7], ts[8])

    if previous_playpos ~= -1 then
      refresh_grid_column(previous_playpos+1)
    end
    if playpos ~= -1 then
      refresh_grid_column(playpos+1)
    end
    if grid_device then
      grid_device:refresh()
    end
    if is_even(playpos) then
      ticks_to_next = even_ppqn
    else
      ticks_to_next = odd_ppqn
    end
    redraw()
  else
    ticks_to_next = ticks_to_next - 1
  end
end

local function update_metro_time()
  timer.time = 60/params:get("tempo")/ppqn/params:get("beats_per_pattern")
end

local function update_swing(swing_amount)
  local swing_ppqn = ppqn*swing_amount/100*0.75
  even_ppqn = util.round(ppqn+swing_ppqn)
  odd_ppqn = util.round(ppqn-swing_ppqn)
end

local function gridkey_event(x, y, state)
  if state == 1 then
    if params:get("last_row_cuts") == 2 and y == 8 then
      queued_playpos = x-1
    else
      set_trig(params:get("pattern"), x, y, not trig_is_set(params:get("pattern"), x, y))
      refresh_grid_button(x, y, true)
    end
    if grid_device then
      grid_device:refresh()
    end
  end
  redraw()
end

function Grid.add(dev)
  if not grid_device then
    dev.key = gridkey_event
    if gridwidth ~= dev.cols then
      gridwidth = dev.cols
    end
    dev.remove = function()
      grid_device = nil
    end
    grid_device = dev
    refresh_grid()
  end
end

function init()
  for patternno=1,NUMPATTERNS do
    for x=1,MAXWIDTH do
      for y=1,HEIGHT do
        set_trig(patternno, x, y, false)
      end
    end
  end

  timer = Metro.alloc()
  timer.callback = tick

  params:add_number("pattern", "pattern", 1, NUMPATTERNS, 1)
  params:set_action("pattern", function(value) refresh_grid() end)
  params:add_option("last_row_cuts", "last row cuts", {"no", "yes"}, 1)
  params:set_action("last_row_cuts", function(value)
    last_row_cuts = (value == 2)
    refresh_grid()
  end)
  params:add_option("cut_quant", "cut quant", {"no", "yes"}, 1)
  params:add_number("beats_per_pattern", "beats per pattern", 1, 8, 4)
  params:set_action("beats_per_pattern", function(value) update_metro_time() end)
  params:add_control("tempo", "tempo", tempo_spec)
  params:set_action("tempo", function(bpm) update_metro_time() end)

  update_metro_time()

  params:add_control("swing_amount", "swing amount", swing_amount_spec)
  params:set_action("swing_amount", update_swing)

  params:add_separator()
  Ack.add_params()

  load_patterns()
  params:read("jah/step.pset")
  params:bang()

  playing = true
  timer:start()
end

function cleanup()
  if grid_device then
    grid_device:all(0)
    grid_device:refresh()
  end
  params:write("jah/step.pset")
  save_patterns()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    params:delta("tempo", delta)
  elseif n == 3 then
    params:delta("swing_amount", delta)
  end
  redraw()
end

function key(n, z)
  if n == 2 and z == 1 then
    if playing == false then
      playpos = -1
      queued_playpos = 0
      redraw()
      refresh_grid()
    else
      playing = false
      timer:stop()
    end
  elseif n == 3 and z == 1 then
    if z == 1 then
      playing = true
      timer:start()
    end
  end
  redraw()
end

function redraw()
  screen.font_size(8)
  screen.clear()
  screen.level(15)
  screen.move(10,30)
  if playing then
    screen.level(3)
    screen.text("[] stop")
  else
    screen.level(15)
    screen.text("[] stopped")
  end
  screen.font_size(8)
  screen.move(70,30)
  if playing then
    screen.level(15)
    screen.text("|> playing")
    screen.text(" "..playpos+1)
  else
    screen.level(3)
    screen.text("|> play")
  end
  screen.level(15)
  screen.move(10,50)
  screen.text(params:string("tempo"))
  screen.move(70,50)
  screen.text(params:string("swing_amount"))
  screen.level(3)
  screen.move(10,60)
  screen.text("tempo")
  screen.move(70,60)
  screen.text("swing")
  screen.update()
end
