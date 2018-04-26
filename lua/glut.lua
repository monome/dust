-- glut
--
-- granular sampler
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

VOICES=4

glut_positions = {-1, -1, -1, -1, -1, -1, -1}
glut_gates = {0, 0, 0, 0, 0, 0, 0}
focus = 1
param_focus = 1
param_names = {
  "rate",
  "dur",
  "density",
  "pitch",
}

-- init function
function init()
  engine.list_commands()
  -- set engine params
  engine.read(1, "/usr/share/sounds/alsa/Front_Left.wav")
  engine.read(2, "/usr/share/sounds/alsa/Front_Right.wav")
  engine.read(3, "/usr/share/sounds/alsa/Rear_Left.wav")
  engine.read(4, "/usr/share/sounds/alsa/Rear_Right.wav")

  -- grid refresh timer
  c = metro[1]
  c.count = -1
  c.time = 1 / 60
  c.callback = function(stage)
    gridredraw()
  end
  c:start()


  for v=1, VOICES do
    -- set poll
    p = poll.set('phase_' .. v, function(pos) update_pos(v, pos) end)
    p.time = 0.05
    p:start()

    params:add_control("rate"..v, controlspec.new(-8, 8, "lin", 0, 1, ""))
    params:set_action("rate"..v, function(value) engine.rate(v, value) end)

    params:add_control("dur"..v, controlspec.new(0.001, 10, "lin", 0, 1, "sec"))
    params:set_action("dur"..v, function(value) engine.dur(v, value) end)

    params:add_control("density"..v, controlspec.new(0, 512, "lin", 0, 1, ""))
    params:set_action("density"..v, function(value) engine.density(v, value) end)

    params:add_control("pitch"..v, controlspec.new(0, 8, "lin", 0, 1, ""))
    params:set_action("pitch"..v, function(value) engine.pitch(v, value) end)
  end
end

function update_pos(voice, pos)
  local led_pos = math.floor(pos * 16) + 1
  glut_positions[voice] = led_pos
end

function start_voice(voice, pos)
  engine.pos(voice, pos)
  engine.gate(voice, 1)
  glut_gates[voice] = 1
end

function stop_voice(voice)
  glut_gates[voice] = 0
  engine.gate(voice, 0)
end

-- grid key function
function gridkey(x, y, state)
  if state > 0 then
    -- set voice pos
    if y > 1 then
      local voice = y - 1
      start_voice(voice, (x - 1) / 16.0)
    else
      local voice = x
      stop_voice(voice)
    end
  end
end

function enc(n, d)
  if n == 1 then
    focus = focus + d
    if focus > 7 then focus = 7 end
    if focus < 1 then focus = 1 end
  elseif n == 2 then
    param_focus = util.clamp(param_focus + d, 1, 4)
  elseif n == 3 then
    params:delta(param_names[param_focus]..focus, d / 10)
  end
  redraw()
end

function gridredraw()
  if g == nil then
    return
  end

  g:all(0)
  for i=1, 16 do
    g:led(i, focus + 1, 3)
  end
  for i=1, 7 do
    if glut_gates[i] > 0 then
      g:led(i, 1, 7)
      g:led(glut_positions[i], i + 1, 15)
    end
  end
  g:refresh()
end

function redraw()
  screen.clear()

  screen.level(5)
  screen.move(0, 10)
  screen.text("voice: "..focus)

  if param_focus == 1 then screen.level(15) else screen.level(5) end
  screen.move(0, 20)
  screen.text("rate: "..params:string("rate"..focus))

  if param_focus == 2 then screen.level(15) else screen.level(5) end
  screen.move(0, 30)
  screen.text("dur: "..params:string("dur"..focus))

  if param_focus == 3 then screen.level(15) else screen.level(5) end
  screen.move(0, 40)
  screen.text("density: "..params:string("density"..focus))

  if param_focus == 4 then screen.level(15) else screen.level(5) end
  screen.move(0, 50)
  screen.text("pitch: "..params:string("pitch"..focus))

  screen.update()
end

-- called on script quit, release memory
cleanup = function()
  glut_positions = nil
end
