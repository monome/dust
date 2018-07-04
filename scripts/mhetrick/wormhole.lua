-- wormhole
-- (spacetime deluxe
-- from norns study 3)
-- with rings by burn
--
-- ENC 1 - change row
-- ENC 2 - select edit position
-- ENC 3 - edit current step
-- KEY 1 - lock all sequences to top row
-- KEY 2 - return current row to default
-- KEY 3 - randomize current row
--
-- the top row sequences note functions.
-- it plays a note on each step
-- each step is a symbol for the action.
-- _ = do nothing
-- + = increase note
-- - = decrease note
-- < = go to bottom note
-- > = go to top note
-- * = random note
-- ? = random step (+, -, or stay put)
-- ! = reverse play head
-- : = randomly reverse play head
-- # = jump random position
--
-- top row: functions
-- middle row: gates
-- bottom row: clock speed

-- augment/change this script 
-- with new functions!

engine.name = "KarplusRings"
local cs = require 'controlspec'

numRows = 3
activeRow = 1

topNote = 110 --was 120
bottomNote = 40 --was 40
note = bottomNote

lockSteps = false

position = 1
step = {7,2,7,2, 7,2,7,8, 7,3,7,3, 7,3,7,3}
STEPS = 16
edit = 1
stepDir = 1

gatePosition = 1
gate = {2,1,2,2, 2,1,2,1, 2,2,1,2, 2,1,2,1}
gateLabel = {"_", "X"}

metroPosition = 1
metroRange = 6
metroArray = {3,1,1,1, 1,1,1,1, 2,1,1,1, 1,1,1,1}
metroTimes = {1, 0.0625, 0.125, 0.25, 0.375, 0.5}
metroLabel = {"_", "1", "2", "3", "4", "5"}

function nothing() end
function inc() note = util.clamp(note + 5, bottomNote, topNote) end
function dec() note = util.clamp(note - 5, bottomNote, topNote) end
function bottom() note = bottomNote end
function top() note = topNote end
function rand() note = math.random(topNote - bottomNote) + bottomNote end
function drunk() note = util.clamp(note + (5 * math.random(-1, 1)), bottomNote, topNote) end
function reverseHead() stepDir = stepDir * -1 end
function randomReverse() if math.random(2) == 2 then stepDir = stepDir * -1 end end
function positionrand() position = math.random(STEPS) end

act = {nothing, inc, dec, bottom, top, rand, drunk, reverseHead, randomReverse, positionrand}
COMMANDS = 10
label = {"_","+", "-", "<", ">", "*", "?", "!", ":", "#"}

function init()
  cs.AMP = cs.new(0,1,'lin',0,0.75,'')
  params:add_control("amp",cs.AMP)
  params:set_action("amp",
  function(x) engine.amp(x) end)
  engine.amp(0.75)

  cs.DECAY = cs.new(0.1,15,'lin',0,3.6,'s')
  params:add_control("damping",cs.DECAY)
  params:set_action("damping",
  function(x) engine.decay(x) end)

  cs.COEF = cs.new(0,1,'lin',0,0.11,'')
  params:add_control("brightness",cs.COEF)
  params:set_action("brightness",
  function(x) engine.coef(x) end)

  cs.LPF_FREQ = cs.new(100,10000,'lin',0,3600,'')
  params:add_control("lpf_freq",cs.LPF_FREQ)
  params:set_action("lpf_freq",
  function(x) engine.lpf_freq(x) end)
  engine.lpf_freq(3600.0)

  cs.LPF_GAIN = cs.new(0,3.2,'lin',0,0.5,'')
  params:add_control("lpf_gain",cs.LPF_GAIN)
  params:set_action("lpf_gain",
  function(x) engine.lpf_gain(x) end)

  cs.BPF_FREQ = cs.new(100,10000,'lin',0,1200,'')
  params:add_control("bpf_freq",cs.BPF_FREQ)
  params:set_action("bpf_freq",
  function(x) engine.bpf_freq(x) end)
  engine.bpf_freq(1200.0)

  cs.BPF_RES = cs.new(0,4,'lin',0,0.5,'')
  params:add_control("bpf_res",cs.BPF_RES)
  params:set_action("bpf_res",
  function(x) engine.bpf_res(x) end)

  counter = metro.alloc(count, 0.125, -1)
  counter:start()
end

function count()
  if stepDir == -1 then
    position = position + stepDir
    if position == 0 then position = STEPS end
  else
    position = (position % STEPS) + stepDir
  end
  
  if lockSteps == true 
  then 
    gatePosition = position
    metroPosition = position
  else 
    gatePosition = (gatePosition % STEPS) + 1
    metroPosition = (metroPosition % STEPS) + 1
  end
  
  if metroArray[metroPosition] > 1 then
    counter.time = metroTimes[metroArray[metroPosition]]
  end
  
  act[step[position]]()
  
  if gate[gatePosition] == 2 then
    engine.hz(midi_to_hz(note))
  end
  
  redraw()
end

function redraw()
  screen.clear()
  
  for i = 1,16 do
    screen.level((i == edit and activeRow == 1) and 15 or 2)
    screen.move(i*8-8,10)
    screen.text(label[step[i]])
    
    screen.level((i == edit and activeRow == 2) and 15 or 2)
    screen.move(i*8-8, 30)
    screen.text(gateLabel[gate[i]])
    
    screen.level((i == edit and activeRow == 3) and 15 or 2)
    screen.move(i*8-8, 50)
    screen.text(metroLabel[metroArray[i]])
    
    if i == position then
      screen.move(i*8-8, 15)
      screen.line_rel(6,0)
      screen.stroke()
    end
      
    if i == gatePosition then
      screen.move(i*8-8, 35)
      screen.line_rel(6,0)
      screen.stroke()
    end
    
    if i == metroPosition then
      screen.move(i*8-8, 55)
      screen.line_rel(6,0)
      screen.stroke()
    end
  end
  
  screen.update()
end

function enc(n,d)
  if n == 1 then
    activeRow = util.clamp(activeRow + d, 1, numRows)
  elseif n == 2 then
    edit = util.clamp(edit + d, 1, STEPS)
  elseif n ==3 then
    if activeRow == 1 then
      step[edit] = util.clamp(step[edit]+d, 1, COMMANDS)
    elseif activeRow == 2 then
      gate[edit] = util.clamp(gate[edit]+d, 1, 2)
    elseif activeRow == 3 then
      metroArray[edit] = util.clamp(metroArray[edit]+d, 1, metroRange)
    end
  end
  redraw()
end

function key(n,z)
  if n == 1 and z == 1 then
    lockSteps = not lockSteps
  end
  if n == 2 and z == 1 then
    init_steps()
  end
  if n == 3 and z == 1 then
    randomize_steps()
  end
end

function midi_to_hz(note)
  return (440/32) * (2 ^ ((note - 9) / 12))
end

function randomize_steps()
  for i= 1,16 do
    if activeRow == 1 then step[i] = math.random(COMMANDS) end
    if activeRow == 2 then gate[i] = math.random(2) end
    if activeRow == 3 then metroArray[i] = math.random(metroRange) end
  end
end

function init_steps()
  for i= 1,16 do
    if activeRow == 1 then step[i] = 1 end
    if activeRow == 2 then gate[i] = 1 end
    if activeRow == 3 then metroArray[i] = 1 end
  end
  metroArray[1] = 3
end