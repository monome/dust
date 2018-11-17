-- euclidean drummer
--
-- enc1 = select
-- enc2 = density
-- enc3 = length
-- key2 = reset phase
-- key3 = start/stop
--
-- key1 = ALT
-- ALT-enc1 = bpm

er = require 'er'

engine.name = 'Ack'

local g = grid.connect()

local ack = require 'jah/ack'
local BeatClock = require 'beatclock'

local clk = BeatClock.new()
local clk_midi = midi.connect()
clk_midi.event = clk.process_midi

local reset = false
local alt = false
local running = true
local track_edit = 1
local current_pattern = 0
local current_pset = 0

local track = {}
for i=1,4 do
  track[i] = {
    k = 0,
    n = 9 - i,
    pos = 1,
    s = {}
  }
end

local pattern = {}
for i=1,112 do
  pattern[i] = {
    data = 0,
    k = {},
    n = {}
  }
  for x=1,4 do
    pattern[i].k[x] = 0
    pattern[i].n[x] = 0
  end
end

local function reer(i)
  if track[i].k == 0 then
    for n=1,32 do track[i].s[n] = false end
  else
    track[i].s = er.gen(track[i].k,track[i].n)
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

  clk.on_step = step
  clk.on_select_internal = function() clk:start() end
  clk.on_select_external = reset_pattern

  clk:add_clock_params()

  for channel=1,4 do
    ack.add_channel_params(channel)
  end
  ack.add_effects_params()

  params:read("tehn/playfair.pset")
  params:bang()

  playfair_load()

  clk:start()
end

function reset_pattern()
  reset = true
  clk:reset()
end

function step()
  if reset then
    for i=1,4 do track[i].pos = 1 end
    reset = false
  else
    for i=1,4 do track[i].pos = (track[i].pos % track[i].n) + 1 end
  end
  trig()
  redraw()
end

function key(n,z)
  if n==1 then alt = z
  elseif n==2 and z==1 then reset_pattern()
  elseif n==3 and z==1 then
    if running then
      clk:stop()
      running = false
    else
      clk:start()
      running = true
    end
  end
  redraw()
end

function enc(n,d)
  if n==1 then
    if alt==1 then
      params:delta("bpm", d)
    else
      track_edit = util.clamp(track_edit+d,1,4)
    end
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
  if params:get("clock") == 1 then
    screen.text(params:get("bpm"))
  else
    for i=1,clk.beat+1 do
       screen.rect(i*2,1,1,2)
    end
    screen.fill()
  end
  for i=1,4 do
    screen.level((i == track_edit) and 15 or 4)
    screen.move(5, i*10 + 10)
    screen.text_center(track[i].k)
    screen.move(20,i*10 + 10)
    screen.text_center(track[i].n)

    for x=1,track[i].n do
      screen.level((track[i].pos==x and not reset) and 15 or 2)
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


local keytimer = 0

function g.event(x,y,z)
  local id = x + (y-1)*16
  if z==1 then
    if id > 16 then
      keytimer = util.time()
    elseif id < 17 then
      params:read("tehn/playfair-" .. string.format("%02d",id) .. ".pset")
      params:bang()
      current_pset = id
    end
  else
    if id > 16 then
      id = id - 16
      local elapsed = util.time() - keytimer
      if elapsed < 0.5 and pattern[id].data == 1 then
        -- recall pattern
        current_pattern = id
        for i=1,4 do
          track[i].n = pattern[id].n[i]
          track[i].k = pattern[id].k[i]
          reer(i)
        end
        --reset_pattern()
      elseif elapsed > 0.5 then
        -- store pattern
        current_pattern = id
        for i=1,4 do
          pattern[id].n[i] = track[i].n
          pattern[id].k[i] = track[i].k
          pattern[id].data = 1
        end
      end
    end
    gridredraw()
  end
end

function gridredraw()
  g.all(0)
  if current_pset > 0 and current_pset < 17 then
    g.led(current_pset,1,9)
  end
  for x=1,16 do
    for y=2,8 do
      local id = x + (y-2)*16
      if pattern[id].data == 1 then
        g.led(x,y,id == current_pattern and 15 or 4)
      end
    end
  end
  g:refresh()
end


function playfair_save()
  local fd=io.open(data_dir .. "tehn/playfair.data","w+")
  io.output(fd)
  for i=1,112 do
    io.write(pattern[i].data .. "\n")
    for x=1,4 do
      io.write(pattern[i].k[x] .. "\n")
      io.write(pattern[i].n[x] .. "\n")
    end
  end
  io.close(fd)
end

function playfair_load()
  local fd=io.open(data_dir .. "tehn/playfair.data","r")
  if fd then
    print("found datafile")
    io.input(fd)
    for i=1,112 do
      pattern[i].data = tonumber(io.read())
      for x=1,4 do
        pattern[i].k[x] = tonumber(io.read())
        pattern[i].n[x] = tonumber(io.read())
      end
    end
    io.close(fd)
  end
end

cleanup = function()
  playfair_save()
end
