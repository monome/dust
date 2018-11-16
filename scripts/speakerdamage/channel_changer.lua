-- channel changer
--
-- your tape transmitted thru 
-- late-night static and
-- broken antenna frequencies
--
-- KEY3: change channel  
-- KEY1 hold: tv guide
-- ENC1: volume
-- ENC2: speed
-- ENC3: pitch
--
-- change the channel to begin

engine.name = 'Glut'
local VOICES = 1
local shift = 0
local channel = 0
local screen_dirty = true

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
  params:set("1speed", math.random(-200,200))
  params:set("1jitter", math.random(0,500))
  params:set("1size", math.random(1,500))
  params:set("1density", math.random(0,512))
  params:set("1pitch", math.random(-24,0))
  params:set("1spread", math.random(0,100))
  params:set("reverb_mix", math.random(0,100))
  params:set("reverb_room", math.random(0,100))
  params:set("reverb_damp", math.random(0,100))
end

function init()
  local SCREEN_FRAMERATE = 15
  local screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  
  local sep = ": "

  params:add_taper("reverb_mix", "*"..sep.."mix", 0, 100, 50, 0, "%")
  params:set_action("reverb_mix", function(value) engine.reverb_mix(value / 100) end)

  params:add_taper("reverb_room", "*"..sep.."room", 0, 100, 50, 0, "%")
  params:set_action("reverb_room", function(value) engine.reverb_room(value / 100) end)

  params:add_taper("reverb_damp", "*"..sep.."damp", 0, 100, 50, 0, "%")
  params:set_action("reverb_damp", function(value) engine.reverb_damp(value / 100) end)
  
  for v = 1, VOICES do
    params:add_separator()

    params:add_file(v.."sample", v..sep.."sample")
    params:set_action(v.."sample", function(file) engine.read(v, file) end)

    params:add_taper(v.."volume", v..sep.."volume", -60, 20, 0, 0, "dB")
    params:set_action(v.."volume", function(value) engine.volume(v, math.pow(10, value / 20)) end)

    params:add_taper(v.."speed", v..sep.."speed", -200, 200, 100, 0, "%")
    params:set_action(v.."speed", function(value) engine.speed(v, value / 100) end)

    params:add_taper(v.."jitter", v..sep.."jitter", 0, 500, 0, 5, "ms")
    params:set_action(v.."jitter", function(value) engine.jitter(v, value / 1000) end)

    params:add_taper(v.."size", v..sep.."size", 1, 500, 100, 5, "ms")
    params:set_action(v.."size", function(value) engine.size(v, value / 1000) end)

    params:add_taper(v.."density", v..sep.."density", 0, 512, 20, 6, "hz")
    params:set_action(v.."density", function(value) engine.density(v, value) end)

    params:add_taper(v.."pitch", v..sep.."pitch", -24, 24, 0, 0, "st")
    params:set_action(v.."pitch", function(value) engine.pitch(v, math.pow(0.5, -value / 12)) end)

    params:add_taper(v.."spread", v..sep.."spread", 0, 100, 0, 0, "%")
    params:set_action(v.."spread", function(value) engine.spread(v, value / 100) end)

    params:add_taper(v.."fade", v..sep.."att / dec", 1, 9000, 1000, 3, "ms")
    params:set_action(v.."fade", function(value) engine.envscale(v, value / 1000) end)
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

function enc(n, d)
  if n == 1 then
    params:delta("1volume", d)
  elseif n == 2 then
    params:delta("1speed", d)
    screen_dirty = true
  elseif n == 3 then
    params:delta("1pitch", d)
    screen_dirty = true
  end
end

function key(n, z)
  if n == 1 then
    shift = z
    screen_dirty = true
  elseif n == 3 then
    if z == 1 then
      -- nothing for now
    else
      channel = channel + 1
      params:set("1sample", randomsample())
      randomparams()
      start_voice()
      screen_dirty = true
    end
  end
end

local function printround(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function drawtv()
  --random screen pixels
  local heighta = math.random(1,30)
  local heightb = math.random(31,64)
  for x=1,heighta do
    for i=1,128 do
      screen.level(math.random(0, 4))
      screen.rect(i,x,1,1)
      screen.fill()
    end
  end
  for x=heighta+1,heightb-1 do
    for i=1,128 do
      screen.level(math.random(0, 6))
      screen.rect(i,x,1,1)
      screen.fill()
    end
  end
  for x=heightb,64 do
    for i=1,128 do
      screen.level(math.random(0, 10))
      screen.rect(i,x,1,1)
      screen.fill()
    end
  end
end

local function cleanfilename()
  return(string.gsub(params:get("1sample"), "/home/we/dust/audio/tape/", ""))
end

local function guidetext(parameter, measure)
  return(parameter .. ": " .. printround(params:get("1"..parameter), 1) .. measure)
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.line_width(1.0)
  
  if shift == 0 then
    drawtv()
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
    screen.text(cleanfilename())
    screen.move(2, 8)
    screen.level(13)
    screen.text(cleanfilename())
    -- glitch title
    screen.move(35, 28)
    screen.level(1)
    screen.text(cleanfilename())
    screen.move(55, 52)
    screen.level(3)
    screen.text(cleanfilename())
    
    screen.level(0)
    screen.move(3, 18)
    screen.text(guidetext("speed", "%"))
    screen.level(13)
    screen.move(2, 16)
    screen.text(guidetext("speed", "%"))
    screen.level(0)
    screen.move(3, 26)
    screen.text(guidetext("jitter", "ms"))
    screen.level(13)
    screen.move(2, 24)
    screen.text(guidetext("jitter", "ms"))
    screen.level(1)
    screen.move(3, 34)
    screen.text(guidetext("size", "ms"))
    screen.level(14)
    screen.move(2, 32)
    screen.text(guidetext("size", "ms"))
    screen.level(2)
    screen.move(3, 42)
    screen.text(guidetext("density", "hz"))
    screen.level(15)
    screen.move(2, 40)
    screen.text(guidetext("density", "hz"))
    screen.level(2)
    screen.move(3, 50)
    screen.text(guidetext("pitch", "st"))
    screen.level(15)
    screen.move(2, 48)
    screen.text(guidetext("pitch", "st"))
    screen.level(2)
    screen.move(3,58)
    screen.text(guidetext("spread", "%"))
    screen.level(15)
    screen.move(2,56)
    screen.text(guidetext("spread", "%"))
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
