-- randy study 4m - remote 13.3
-- physical

-- physical
-- norns study 4 - remote
--
-- grid controls arpeggio
-- midi sends notes out to world
-- ENC2 = bpm
-- ENC3 = scale

--engine.name = 'Passersby'

music = require 'mark_eats/musicutil'
beatclock = require 'beatclock'
--passersby = require "mark_eats/passersby"

steps = {}
position = 1
transpose = 0
k_pos = 1

mode = math.random(#music.SCALES)
scale = music.generate_scale_of_length(60,music.SCALES[mode].name,8)

clk = beatclock.new()
clk_midi = midi.connect()
clk_midi.event = clk.process_midi

function init()
  for i=1,16 do
    table.insert(steps,math.random(8))
  end
  grid_redraw()

  clk.on_step = count
  clk.on_select_internal = function() clk:start() end
  clk.on_select_external = function() print("external") end
  clk:add_clock_params()

  --params:add_separator()
  --passersby.add_params()

  clk:start()
end

function key(n,z)
  if n == 3 and z == 1 then
    if k_pos == 0 then
      clk:start()
      k_pos= 1
    elseif k_pos == 1 then
      clk:stop()
      k_pos = 0
    end
  end
end

function enc(n,d)
  if n == 2 then
    params:delta("bpm",d)
  elseif n == 3 then
    mode = util.clamp(mode + d, 1, #music.SCALES)
    scale = music.generate_scale_of_length(60,music.SCALES[mode].name,8)
  end
  redraw()
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.move(0,30)
  screen.text("bpm: "..params:get("bpm"))
  screen.move(0,40)
  screen.text(music.SCALES[mode].name)
  screen.update()
end

g = grid.connect()

g.event = function(x,y,z)
  if z == 1 then
    if steps[x] == y then
      steps[x] = 0
    else
      steps[x] = y
    end
    grid_redraw()
  end
end

function grid_redraw()
  g.all(0)
  for i=1,16 do
    g.led(i,steps[i],i==position and 15 or 4)
  end
  g.refresh()
end

m = midi.connect(2)

function count()
  position = (position % 16) + 1
  cur_note = music.freq_to_note_num(music.note_num_to_freq(scale[steps[position]] + transpose),1)

  m.note_on(cur_note,100)
  m.note_off(cur_note,0)

  grid_redraw()
end

k = midi.connect(1)
k.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "note_on" then
    transpose = d.note - 60
  end
end





