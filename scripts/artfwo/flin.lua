-- flin
--
-- cyclic poly-rhythm music box
--
-- originally by tehn
--
-- press buttons on the grid to
-- start cycling notes

engine.name = 'PolySub'

local GRID_HEIGHT = 8
local DURATION_1 = 1 / 20
local GRID_FRAMERATE = 1 / 60
local SCREEN_FRAMERATE = 1 / 30

local notes = { 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24, 26, 28 }
local cycles = {}
local cycle_metros = {}
local current_cycle = 1
local transpose = 48

local grid_refresh_metro
local screen_refresh_metro

local function midicps(m)
  return (440 / 32) * math.pow(2, (m - 9) / 12)
end

local function draw_cycle(x, stage)
  local leds = cycles[x].leds

  if g then
    for y=1, GRID_HEIGHT do
      g:led(x, y, cycles[x].running and 5 or 0)
    end

    if cycles[x].running then
      for y=1, GRID_HEIGHT do
        if leds[y] > 0 then
          g:led(x, y, 15)
        end
      end
    end
  end
end

local function update_cycle(x, stage)
  local leds = cycles[x].leds
  for i=1, GRID_HEIGHT * 4 do leds[i] = 0 end

  local index = (stage - 1) % (GRID_HEIGHT * 2) + 1

  for i=1, cycles[x].length do
    leds[index] = 1
    index = index - 1
  end

  local on = leds[1] == 1
  if on then
    engine.start(x, midicps(notes[x] + params:get("transpose")))
  else
    engine.stop(x)
  end
end

local function start_cycle(x, speed, length)
  local timer = cycle_metros[x]
  timer.time = 4 / params:get("tempo") * cycles[x].speed

  timer.callback = function(stage)
    update_cycle(x, stage)
    draw_cycle(x, stage)
  end

  timer:start()
  cycles[x].running = true
end

local function stop_cycle(x)
  cycle_metros[x]:stop()
  cycle_metros[x].callback = nil
  cycles[x].running = false
  draw_cycle(x)
  engine.stop(x)
end

function init()
  for i=1, 16 do
    cycle_metros[i] = metro.alloc()
    cycles[i] = { running = false, keys_pressed = 0, speed = 1, length = 1, leds = {} }
    for j = 1, GRID_HEIGHT * 4 do
      cycles[i].leds[j] = 0
    end
  end

  params:add_number("tempo", 30, 240, 90)
  params:set_action("tempo", function(t)
    for i=1,16 do
      cycle_metros[i].time = 4 / t * cycles[i].speed
    end
  end)

  params:add_number("transpose", 0, 127, 48)

  params:add_separator()

  params:add_control("legato", controlspec.new(0, 3, "lin", 0, 0.1, "s"))
  params:set_action("legato", function(x) engine.hzLag(x) end)

  params:add_control("shape", controlspec.new(0,1,"lin",0,0,""))
  params:set_action("shape", function(x) engine.shape(x) end)

  params:add_control("timbre", controlspec.new(0,1,"lin",0,0.5,""))
  params:set_action("timbre", function(x) engine.timbre(x) end)

  params:add_control("noise", controlspec.new(0,1,"lin",0,0,""))
  params:set_action("noise", function(x) engine.noise(x) end)

  params:add_control("cut", controlspec.new(0,32,"lin",0,8,""))
  params:set_action("cut", function(x) engine.cut(x) end)

  params:add_control("fgain", controlspec.new(0,6,"lin",0,0,""))
  params:set_action("fgain", function(x) engine.fgain(x) end)

  params:add_control("cutEnvAmt", controlspec.new(0,1,"lin",0,0,""))
  params:set_action("cutEnvAmt", function(x) engine.cutEnvAmt(x) end)

  params:add_control("detune", controlspec.new(0,1,"lin",0,0,""))
  params:set_action("detune", function(x) engine.detune(x) end)

  params:add_control("ampAtk", controlspec.new(0.01,10,"lin",0,0.05,""))
  params:set_action("ampAtk", function(x) engine.ampAtk(x) end)

  params:add_control("ampDec", controlspec.new(0,2,"lin",0,0.1,""))
  params:set_action("ampDec", function(x) engine.ampDec(x) end)

  params:add_control("ampSus", controlspec.new(0,1,"lin",0,1,""))
  params:set_action("ampSus", function(x) engine.ampSus(x) end)

  params:add_control("ampRel", controlspec.new(0.01,10,"lin",0,1,""))
  params:set_action("ampRel", function(x) engine.ampRel(x) end)

  params:add_control("cutAtk", controlspec.new(0.01,10,"lin",0,0.05,""))
  params:set_action("cutAtk", function(x) engine.cutAtk(x) end)

  params:add_control("cutDec", controlspec.new(0,2,"lin",0,0.1,""))
  params:set_action("cutDec", function(x) engine.cutDec(x) end)

  params:add_control("cutSus", controlspec.new(0,1,"lin",0,1,""))
  params:set_action("cutSus", function(x) engine.cutSus(x) end)

  params:add_control("cutRel", controlspec.new(0.01,10,"lin",0,1,""))
  params:set_action("cutRel", function(x) engine.cutRel(x) end)

  if g then g:all(0) end

  grid_refresh_metro = metro.alloc()
  grid_refresh_metro.time = GRID_FRAMERATE
  grid_refresh_metro.callback = function(stage)
    if g then g:refresh() end
  end
  grid_refresh_metro:start()

  screen_refresh_metro = metro.alloc()
  screen_refresh_metro.time = SCREEN_FRAMERATE
  screen_refresh_metro.callback = function(stage)
    redraw()
  end
  screen_refresh_metro:start()
end

function gridkey(x, y, s)
  if y == GRID_HEIGHT then
    if s == 1 then stop_cycle(x) end
    return
  else
    if s == 1 then
      cycles[x].keys_pressed = cycles[x].keys_pressed + 1

      if cycles[x].keys_pressed == 1 then
        stop_cycle(x)
        cycles[x].speed = y
        cycles[x].length = 1
      else
        cycles[x].length = y
      end
    else
      cycles[x].keys_pressed = cycles[x].keys_pressed - 1

      if cycles[x].keys_pressed == 0 then
        start_cycle(x, cycles[x].speed, cycles[x].length)
      end
    end
  end
end

function key(n, z)
  if z == 1 then
    if n == 2 then
      current_cycle = util.clamp(current_cycle - 1, 1, 16)
      redraw()
    elseif n == 3 then
      current_cycle = util.clamp(current_cycle + 1, 1, 16)
      redraw()
    end
  end
end

function enc(n, d)
  if n == 1 then
    mix:delta("output", d)
    redraw()
  elseif n == 2 then
    current_cycle = util.clamp(current_cycle + d, 1, 16)
    redraw()
  elseif n == 3 then
    notes[current_cycle] = util.clamp(notes[current_cycle] + d, -32, 32)
    redraw()
  end
end

function redraw()
  screen.clear()
  screen.aa(0)
  screen.line_width(1)

  screen.level(1)
  screen.move(0, 32)
  screen.line(128,32)
  screen.stroke()

  for i=1,16 do
    local x = (i-1) * 8
    local y = 32 - notes[i] - 2

    if i == current_cycle then
      screen.level(1)
      screen.move(x+2, 0)
      screen.line(x+2, 64)
      screen.stroke()
    end

    if cycles[i].leds[1] > 0 then
      screen.level(15)
    else
      screen.level(i == current_cycle and 7 or 2)
    end
    screen.rect (x, y, 5, 4)
    screen.fill()
  end

  screen.update()
end
