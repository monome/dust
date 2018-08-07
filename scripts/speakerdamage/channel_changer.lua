-- channel changer
--
-- your own ghosts thru 
-- late-night static and
-- broken antenna frequencies
--
-- KEY 3: change channel  
-- KEY 1 (HOLD): tv guide
-- ENC 1: volume
-- ENC 2: speed
-- ENC 3: pitch
--
-- your display is not broken

engine.name = 'Glut'
local VOICES = 1
local shiftMode = 0
local channel = 0

local function randomsample()
  local i, t, popen = 0, {}, io.popen
  local pfile = popen('ls -a "/home/we/dust/audio/tape"')
  for filename in pfile:lines() do
    i = i + 1
    t[i] = "/home/we/dust/audio/tape/" .. filename
  end
  pfile:close()
  samp = (t[math.random(#t)])
  return (samp)
end

local function randomparams()
  params:set("1: speed", math.random(-200,200))
  params:set("1: jitter", math.random(0,500))
  params:set("1: size", math.random(1,500))
  params:set("1: density", math.random(0,512))
  params:set("1: pitch", math.random(-24,0))
  params:set("1: spread", math.random(0,100))
  params:set("*: mix", math.random(0,100))
  params:set("*: room", math.random(0,100))
  params:set("*: damp", math.random(0,100))
end

function init()
  
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
end

local function reset_voice()
  engine.seek(1, 0)
end

local function start_voice()
  reset_voice()
  engine.gate(1, 1)
end

local function stop_voice()
  engine.gate(1, 0)
end

function enc(n, d)
  if n == 1 then
    params:delta("1: volume", d)
  elseif n == 2 then
    params:delta("1: speed", d)
  elseif n == 3 then
    params:delta("1: pitch", d)
  end
end

function key(n, z)
  if n == 1 then
    shiftMode = z
    redraw()
  elseif n == 3 then
    if z == 1 then
      -- do nothing for now
    else
      channel = channel + 1
      params:set("1: sample", randomsample())
      randomparams()
      start_voice()
      redraw()
    end
  end
end

local function printRound(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function cleanFilename()
  return(string.gsub(params:get("1: sample"), "/home/we/dust/audio/tape/", ""))
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.line_width(1.0)
  
  if shiftMode == 0 then
    --random screen pixels
    for x=1,30 do
      for i=1,128 do
        screen.level(math.random(0, 4))
        screen.rect(i,x,1,1)
        screen.fill()
      end
    end
    for x=31,42 do
      for i=1,128 do
        screen.level(math.random(0, 6))
        screen.rect(i,x,1,1)
        screen.fill()
      end
    end
    for x=43,64 do
      for i=1,128 do
        screen.level(math.random(0, 10))
        screen.rect(i,x,1,1)
        screen.fill()
      end
    end
  else 
    -- tv guide
    screen.level(2)
    screen.rect(0,0,128,30)
    screen.fill()
    screen.level(3)
    screen.rect(0,30,128,42)
    screen.fill()
    screen.level(4)
    screen.rect(0,43,128,21)
    screen.fill()
    screen.font_face(1)
    screen.font_size(8)
    screen.move(3, 10)
    screen.level(0)
    screen.text(cleanFilename())
    screen.move(2, 8)
    screen.level(13)
    screen.text(cleanFilename())
    -- glitch title
    screen.move(35, 28)
    screen.level(1)
    screen.text(cleanFilename())
    screen.move(55, 52)
    screen.level(3)
    screen.text(cleanFilename())
    
    screen.level(0)
    screen.move(3, 18)
    screen.text("speed: " .. printRound(params:get("1: speed"), 1) .. "%")
    screen.level(13)
    screen.move(2, 16)
    screen.text("speed: " .. printRound(params:get("1: speed"), 1) .. "%")
    screen.level(0)
    screen.move(3, 26)
    screen.text("jitter: " .. printRound(params:get("1: jitter"), 1) .. "ms")
    screen.level(13)
    screen.move(2, 24)
    screen.text("jitter: " .. printRound(params:get("1: jitter"), 1) .. "ms")
    screen.level(1)
    screen.move(3, 34)
    screen.text("size: " .. printRound(params:get("1: size"), 1) .. "ms")
    screen.level(14)
    screen.move(2, 32)
    screen.text("size: " .. printRound(params:get("1: size"), 1) .. "ms")
    screen.level(2)
    screen.move(3, 42)
    screen.text("density: " .. printRound(params:get("1: density"), 1) .. "hz")
    screen.level(15)
    screen.move(2, 40)
    screen.text("density: " .. printRound(params:get("1: density"), 1) .. "hz")
    screen.level(2)
    screen.move(3, 50)
    screen.text("pitch: " .. printRound(params:get("1: pitch"), 1) .. "st")
    screen.level(15)
    screen.move(2, 48)
    screen.text("pitch: " .. printRound(params:get("1: pitch"), 1) .. "st")
    screen.level(2)
    screen.move(3,58)
    screen.text("spread: " .. printRound(params:get("1: spread"), 1) .. "%")
    screen.level(15)
    screen.move(2,56)
    screen.text("spread: " .. printRound(params:get("1: spread"), 1) .. "%")
  end

  -- channel number
  screen.level(0)
  screen.rect(109,6,18,16)
  screen.fill()
  screen.level(2)
  screen.rect(108,4,18,16)
  screen.fill()
  screen.font_face(3)
  screen.font_size(12)
  screen.move(111,17)
  screen.level(0)
  screen.text(channel)
  screen.move(110,15)
  screen.level(15)
  screen.text(channel)
  
  screen.update()
end
 