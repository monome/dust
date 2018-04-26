-- glut
--
-- granular thing
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

    params:add_control("voice"..v..".rate",controlspec.new(-8, 8, "lin", 0, 1, ""))
    params:set_action("voice"..v..".rate", function(value) engine.rate(v, value) end)
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
    params:delta("voice"..focus..".rate", d / 10)
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
  screen.level(15)

  screen.move(0, 10)
  screen.text("voice: "..focus)

  screen.move(0, 20)
  screen.text("rate: "..params:string("voice"..focus..".rate"))

  screen.update()
end

-- called on script quit, release memory
cleanup = function()
  glut_positions = nil
end
