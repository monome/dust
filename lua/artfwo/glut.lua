-- glut
--
-- granular sampler in progress
--
-- ////////
-- ////
-- //////
-- /////////////
-- //
-- ///////
-- ///
-- /

engine.name = 'Glut'

local VOICES = 7

local positions = {-1, -1, -1, -1, -1, -1, -1}
local gates = {0, 0, 0, 0, 0, 0, 0}
local current_voice = 1
local current_param = 1
local param_names = {
  "rate",
  "jitter",
  "dur",
  "density",
  "pitch",
  "spread",
}

local gridbuf = require 'gridbuf'
local grid_ctl = gridbuf.new(16, 8)
local grid_voc = gridbuf.new(16, 8)

local function ledinterp(value, width)
  local pos = value * width

  local levels = {}
  for i = 1, width do
    levels[i] = 0
  end

  local left = math.floor(pos)
  local index_left = left + 1
  local dist_left = math.abs(pos - left)

  local right = math.floor(pos + 1)
  local index_right = right + 1
  local dist_right = math.abs(pos - right)

  if index_left < 1 then index_left = width end
  if index_left > width then index_left = 1 end

  if index_right < 1 then index_right = width end
  if index_right > width then index_right = 1 end

  levels[index_left] = math.floor(math.abs(1 - dist_left) * 15)
  levels[index_right] = math.floor(math.abs(1 - dist_right) * 15)

  return levels
end

local function start_voice(voice, pos)
  engine.pos(voice, pos)
  engine.gate(voice, 1)
  gates[voice] = 1
end

local function stop_voice(voice)
  gates[voice] = 0
  engine.gate(voice, 0)
end

local function fileselect_callback(path)
  if path ~= "cancel" then
    engine.read(current_voice, path)
  end
end

local function gridredraw()
  if g == nil then
    return
  end

  grid_ctl:led_level_all(0)
  grid_voc:led_level_all(0)

  for i=1, 16 do
    grid_ctl:led_level_set(i, current_voice + 1, 3)
  end

  for i=1, 7 do
    if gates[i] > 0 then
      grid_ctl:led_level_set(i, 1, 7)
      grid_voc:led_level_row(1, i + 1, ledinterp(positions[i], 16))
    end
  end

  local buf = grid_ctl | grid_voc
  buf:render(g)
  g:refresh()
end

function init()
  -- grid refresh timer
  c = metro[1]
  c.count = -1
  c.time = 1 / 60
  c.callback = function(stage)
    gridredraw()
  end
  c:start()

  -- add samples first
  for v = 1, VOICES do
    params:add_file("sample"..v)
    params:set_action("sample"..v, function(file) engine.read(v, file) end)

    p = poll.set('phase_' .. v, function(pos) positions[v] = pos end)
    p.time = 0.05
    p:start()
  end

  -- load default sounds
  engine.read(1, "/usr/share/sounds/alsa/Front_Left.wav")
  engine.read(2, "/usr/share/sounds/alsa/Front_Right.wav")
  engine.read(3, "/usr/share/sounds/alsa/Rear_Left.wav")
  engine.read(4, "/usr/share/sounds/alsa/Rear_Right.wav")

  for v = 1, VOICES do

    params:add_control("rate"..v, controlspec.new(-8, 8, "lin", 0, 1, ""))
    params:set_action("rate"..v, function(value) engine.rate(v, value) end)

    params:add_control("jitter"..v, controlspec.new(0, 0.5, "lin", 0, 0.01, "sec"))
    params:set_action("jitter"..v, function(value) engine.jitter(v, value) end)

    params:add_control("dur"..v, controlspec.new(0.001, 10, "lin", 0, 0.1, "sec"))
    params:set_action("dur"..v, function(value) engine.dur(v, value) end)

    params:add_control("density"..v, controlspec.new(0, 512, "lin", 0, 20, ""))
    params:set_action("density"..v, function(value) engine.density(v, value) end)

    params:add_control("pitch"..v, controlspec.new(0, 8, "lin", 0, 1, ""))
    params:set_action("pitch"..v, function(value) engine.pitch(v, value) end)

    params:add_control("spread"..v, controlspec.new(0, 1, "lin", 0, 0, ""))
    params:set_action("spread"..v, function(value) engine.spread(v, value) end)
  end

  params:bang()
end

function gridkey(x, y, state)
  if state > 0 then
    -- set voice pos
    if y > 1 then
      local voice = y - 1
      start_voice(voice, (x - 1) / 16)
    else
      local voice = x
      stop_voice(voice)
    end
  end
end

function enc(n, d)
  if n == 1 then
    current_voice = current_voice + d
    if current_voice > 7 then current_voice = 7 end
    if current_voice < 1 then current_voice = 1 end
  elseif n == 2 then
    current_param = util.clamp(current_param + d, 1, 6)
  elseif n == 3 then
    params:delta(param_names[current_param]..current_voice, d / 10)
  end
  redraw()
end

function key(n, z)
  if n == 2 then
    fileselect.enter("/home/pi/dust", fileselect_callback)
  end
end

function redraw()
  screen.clear()

  screen.level(5)
  screen.move(127, 10)
  screen.text_right("voice: "..current_voice)

  if current_param == 1 then screen.level(15) else screen.level(5) end
  screen.move(0, 10)
  screen.text("speed: "..params:string("rate"..current_voice))

  if current_param == 2 then screen.level(15) else screen.level(5) end
  screen.move(0, 20)
  screen.text("jitter: "..params:string("jitter"..current_voice))

  if current_param == 3 then screen.level(15) else screen.level(5) end
  screen.move(0, 30)
  screen.text("dur: "..params:string("dur"..current_voice))

  if current_param == 4 then screen.level(15) else screen.level(5) end
  screen.move(0, 40)
  screen.text("density: "..params:string("density"..current_voice))

  if current_param == 5 then screen.level(15) else screen.level(5) end
  screen.move(0, 50)
  screen.text("pitch: "..params:string("pitch"..current_voice))

  if current_param == 6 then screen.level(15) else screen.level(5) end
  screen.move(0, 60)
  screen.text("spread: "..params:string("spread"..current_voice))

  screen.level(5)
  screen.move(127, 60)
  screen.text_right("key2 - load")

  screen.update()
end

-- called on script quit, release memory
function cleanup()
  for v = 1, VOICES do
    poll.polls['phase_' .. v]:stop()
  end
end
