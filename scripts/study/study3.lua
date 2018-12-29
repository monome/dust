-- spacetime
-- norns study 3
--
-- ENC 1 - sweep filter
-- ENC 2 - select edit position
-- ENC 3 - choose command
-- KEY 3 - randomize command set
--
-- spacetime is a weird function sequencer.
-- it plays a note on each step
-- each step is a symbol for the action.
-- + = increase note
-- - = decrease note
-- < = go to bottom note
-- > = go to top note
-- * = random note
-- M = fast metro
-- m = slow metro
-- # = jump random position
--
-- augment/change this script with new functions!

engine.name = "PolyPerc"

note = 40
position = 1
step = {1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1}
STEPS = 16
edit = 1

function inc() note = util.clamp(note + 5, 40, 120) end
function dec() note = util.clamp(note - 5, 40, 120) end
function bottom() note = 40 end
function top() note = 120 end
function rand() note = math.random(80) + 40 end
function metrofast() counter.time = 0.125 end
function metroslow() counter.time = 0.25 end
function positionrand() position = math.random(STEPS) end

act = {inc, dec, bottom, top, rand, metrofast, metroslow, positionrand}
COMMANDS = 8
label = {"+", "-", "<", ">", "*", "M", "m", "#"}

function init()
  params:add_control("cutoff", "cutoff", controlspec.new(50, 5000, 'exp', 0, 555, 'hz'))
  params:set_action("cutoff", function(x) engine.cutoff(x) end)
  counter = metro.alloc(count, 0.125, -1)
  counter:start()
end

function count()
  position = (position % STEPS) + 1
  act[step[position]]()
  engine.hz(midi_to_hz(note))
  redraw()
end

function redraw()
  screen.clear()
  
  for i = 1,16 do
    screen.level((i == edit) and 15 or 2)
    screen.move(i*8-8,40)
    screen.text(label[step[i]])
    if i == position then
      screen.move(i*8-8, 45)
      screen.line_rel(6,0)
      screen.stroke()
    end
  end
  
  screen.update()
end

function enc(n,d)
  if n == 1 then
    params:delta("cutoff", d)
  elseif n == 2 then
    edit = util.clamp(edit + d, 1, STEPS)
  elseif n ==3 then
    step[edit] = util.clamp(step[edit]+d, 1, COMMANDS)
  end
  redraw()
end

function key(n,z)
  if n == 3 and z == 1 then
    randomize_steps()
  end
end

function midi_to_hz(note)
  return (440/32) * (2 ^ ((note - 9) / 12))
end

function randomize_steps()
  for i= 1,16 do
    step[i] = math.random(COMMANDS)
  end
end