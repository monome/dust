-- easygrain
--
-- a simplified glut
-- for traveling with nothing
-- not even a grid
--
-- KEY 1: Alt-key
-- KEY 2: Start/Stop
-- KEY 3: Retrigger
--        Main    Alt
-- ENC 1: Speed Jitter
-- ENC 2: Size  Density
-- ENC 3: Pitch Spread

engine.name = 'Glut'
local VOICES = 1
voiceGate = 0
shiftMode = 0
grainPosition = 0

function init()
  
  local phase_poll = poll.set('phase_' .. 1, function(pos) grainPosition = pos end)
  phase_poll.time = 0.05
  phase_poll:start()
  
  local sep = ": "

  params:add_taper("*"..sep.."mix", 0, 100, 50, 0, "%")
  params:set_action("*"..sep.."mix", function(value) engine.reverb_mix(value / 100) end)

  params:add_taper("*"..sep.."room", 0, 100, 50, 0, "%")
  params:set_action("*"..sep.."room", function(value) engine.reverb_room(value / 100) end)

  params:add_taper("*"..sep.."damp", 0, 100, 50, 0, "%")
  params:set_action("*"..sep.."damp", function(value) engine.reverb_damp(value / 100) end)

  for v = 1, VOICES do
    params:add_separator()

    params:add_file(v..sep.."sample")
    params:set_action(v..sep.."sample", function(file) engine.read(v, file) end)

    params:add_taper(v..sep.."volume", -60, 20, 0, 0, "dB")
    params:set_action(v..sep.."volume", function(value) engine.volume(v, math.pow(10, value / 20)) end)

    params:add_taper(v..sep.."speed", -200, 200, 100, 0, "%")
    params:set_action(v..sep.."speed", function(value) engine.speed(v, value / 100) end)

    params:add_taper(v..sep.."jitter", 0, 500, 0, 5, "ms")
    params:set_action(v..sep.."jitter", function(value) engine.jitter(v, value / 1000) end)

    params:add_taper(v..sep.."size", 1, 500, 100, 5, "ms")
    params:set_action(v..sep.."size", function(value) engine.size(v, value / 1000) end)

    params:add_taper(v..sep.."density", 0, 512, 20, 6, "hz")
    params:set_action(v..sep.."density", function(value) engine.density(v, value) end)

    params:add_taper(v..sep.."pitch", -24, 24, 0, 0, "st")
    params:set_action(v..sep.."pitch", function(value) engine.pitch(v, math.pow(0.5, -value / 12)) end)

    params:add_taper(v..sep.."spread", 0, 100, 0, 0, "%")
    params:set_action(v..sep.."spread", function(value) engine.spread(v, value / 100) end)

    params:add_taper(v..sep.."att / dec", 1, 9000, 1000, 3, "ms")
    params:set_action(v..sep.."att / dec", function(value) engine.envscale(v, value / 1000) end)
  end

  params:bang()
  
  counter = metro.alloc(count, 0.01, -1)
  counter:start()
end

function count()
  redraw()
end

local function reset_voice()
  engine.seek(1, 0)
end

local function start_voice()
  reset_voice()
  engine.gate(1, 1)
  voiceGate = 1
end

local function stop_voice()
  voiceGate = 0
  engine.gate(1, 0)
end



function enc(n, d)
  if n == 1 then
    if shiftMode == 0 then
      params:delta("1: speed", d)
    else
      params:delta("1: jitter", d)
    end
  elseif n == 2 then
    if shiftMode == 0 then
      params:delta("1: size", d)
    else
      params:delta("1: density", d)
    end
  elseif n == 3 then
    if shiftMode == 0 then
      params:delta("1: pitch", d)
    else
      params:delta("1: spread", d)
    end
  end
end

function key(n, z)
  if n == 1 then
    shiftMode = z
  elseif n == 2 then
    if z == 1 then
      if voiceGate == 0 then start_voice() else stop_voice() end
    end
  elseif n == 3 then
    if z == 1 then 
      reset_voice() 
    end
  end
end

function printRound(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function redraw()
  -- do return end
  screen.clear()
  screen.level(15)

  rectHeight = 10
  rectPadding = 10

  screen.rect(rectPadding, rectHeight, 100, 10)
  screen.stroke()
  
  if voiceGate == 1 then
    screen.rect(rectPadding, rectHeight, 100*grainPosition, 10)
    screen.fill()
  end
  
  if shiftMode == 0 then
    screen.move(4, 40)
    screen.text(printRound(params:get("1: speed"), 1))
    screen.move(0, 50)
    screen.text("Speed")
    
    screen.move(60, 40)
    screen.text(printRound(params:get("1: size"), 1))
    screen.move(60, 50)
    screen.text("Size")
    
    screen.move(96, 40)
    screen.text(printRound(params:get("1: pitch"), 1))
    screen.move(95, 50)
    screen.text("Pitch")
  else
    screen.move(6, 40)
    screen.text(printRound(params:get("1: jitter"), 1))
    screen.move(0, 50)
    screen.text("Jitter")
    
    screen.move(60, 40)
    screen.text(printRound(params:get("1: density"), 1))
    screen.move(53, 50)
    screen.text("Density")
    
    screen.move(97, 40)
    screen.text(printRound(params:get("1: spread"), 1))
    screen.move(90, 50)
    screen.text("Spread")
  end

  screen.update()
end