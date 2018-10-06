-- rebound: a kinetic sequencer
--
-- key1: shift^
-- key2: add/^remove orb
-- key3: select next orb
-- enc1: change orb note
-- enc2: rotate orb^s
-- enc3: accelerate orb^s

-- written by nf in august 2018
-- params and scales taken from tehn/awake, thanks

-- TODO:
-- - ack-based version

local cs = require 'controlspec'
local Midi = require 'midi'
local MusicUtil = require 'mark_eats/musicutil'

engine.name = "PolyPerc"

local m = midi.connect()

local balls = {}
local cur_ball = 0

local BeatClock = require 'beatclock'
local clk = BeatClock.new()

local scale_notes = {}
local note_queue = {}
local note_off_queue = {}

local min_note = 0
local max_note = 127
local min_rand_note = min_note+24
local max_rand_note = max_note-24

local shift = false

local info_note_name = ""
local info_visible = false
local info_timer = metro.alloc()
info_timer.callback = function() info_visible = false end
function show_info()
  info_visible = true
  info_timer:start(1, 1)
  local b = balls[cur_ball]
  local n = MusicUtil.snap_note_to_array(b.n, scale_notes)
  info_note_name = MusicUtil.note_num_to_name(n, true)
end

function init()
  screen.aa(1)

  local u = metro.alloc()
  u.time = 1/60
  u.count = -1
  u.callback = update
  u:start()

  clk.on_step = play_notes
  clk.on_select_internal = function() clk:start() end
  clk:add_clock_params()

  params:add_separator()

  local scales = {}
  for i=1,#MusicUtil.SCALES do
    scales[i] = MusicUtil.SCALES[i].name
  end
  params:add_option("scale", "scale", scales)
  params:set_action("scale", build_scale)

  params:add_option("root", "root", MusicUtil.NOTE_NAMES)
  params:set_action("root", build_scale)

  params:add_separator()

  cs.AMP = cs.new(0,1,'lin',0,0.5,'')
  params:add_control("amp", "amp", cs.AMP)
  params:set_action("amp",
  function(x) engine.amp(x) end)

  cs.PW = cs.new(0,100,'lin',0,80,'%')
  params:add_control("pw", "pw", cs.PW)
  params:set_action("pw",
  function(x) engine.pw(x/100) end)

  cs.REL = cs.new(0.1,3.2,'lin',0,0.2,'s')
  params:add_control("release", "release", cs.REL)
  params:set_action("release",
  function(x) engine.release(x) end)

  cs.CUT = cs.new(50,5000,'exp',0,555,'hz')
  params:add_control("cutoff", "cutoff", cs.CUT)
  params:set_action("cutoff",
  function(x) engine.cutoff(x) end)

  cs.GAIN = cs.new(0,4,'lin',0,1,'')
  params:add_control("gain", "gain", cs.GAIN)
  params:set_action("gain",
  function(x) engine.gain(x) end)

  params:bang()
end

function build_scale()
  scale_notes = MusicUtil.generate_scale(params:get("root"), params:get("scale"), 9)
end

function redraw()
  screen.clear()
  if shift then
    screen.level(5)
    screen.line_width(1)
    screen.rect(1,1,126,62)
    screen.stroke()
  end
  for i=1,#balls do
    drawball(balls[i], i == cur_ball)
  end
  if info_visible and cur_ball > 0 then
    screen.level(15)
    screen.font_face(3)
    screen.font_size(16)
    screen.move(8,52)
    screen.text(cur_ball)
    screen.move(32,52)
    screen.text(info_note_name)
  end
  screen.update()
end

function update()
  for i=1,#balls do
    updateball(balls[i])
  end
  redraw()
end

function enc(n, d)
  if n == 1 and not shift and cur_ball > 0 then
    -- note
    balls[cur_ball].n = math.min(math.max(balls[cur_ball].n+d, min_note), max_note)
    show_info()
  elseif n == 2 then
    -- rotate
    for i=1,#balls do
      if shift or i == cur_ball then
        balls[i].a = balls[i].a - d/10
      end
    end
  elseif n == 3 then
    -- accelerate
    for i=1,#balls do
      if shift or i == cur_ball then
        balls[i].v = balls[i].v + d/10
      end
    end
  end
end

function key(n, z)
  if n == 1 then
    -- shift
    shift = z == 1
  elseif n == 2 and z == 1 then
    if shift then
      -- remove ball
      table.remove(balls, cur_ball)
      if cur_ball > #balls then
        cur_ball = #balls
      end
    else
      -- add ball
      table.insert(balls, newball())
      cur_ball = #balls
    end
    show_info()
  elseif n == 3 and z == 1 and not shift and #balls > 0 then
    -- select next ball
    cur_ball = cur_ball%#balls+1
    show_info()
  end
end

function newball()
  return {
    x = 64,
    y = 32,
    v = 0.5*math.random()+0.5,
    a = math.random()*2*math.pi,
    n = math.floor(math.random()*(max_rand_note-min_rand_note)+min_rand_note),
  }
end

function drawball(b, hilite)
  screen.level(hilite and 15 or 5)
  screen.circle(b.x, b.y, hilite and 2 or 1.5)
  screen.fill()
end

function updateball(b)
  b.x = b.x + math.sin(b.a)*b.v
  b.y = b.y + math.cos(b.a)*b.v

  local minx = 2
  local miny = 2
  local maxx = 126
  local maxy = 62
  if b.x >= maxx then
    b.x = maxx
    b.a = 2*math.pi - b.a
    enqueue_note(b, 0)
  elseif b.x <= minx then
    b.x = minx
    b.a = 2*math.pi - b.a
    enqueue_note(b, 1)
  elseif b.y >= maxy then
    b.y = maxy
    b.a = math.pi - b.a
    enqueue_note(b, 2)
  elseif b.y <= miny then
    b.y = miny
    b.a = math.pi - b.a
    enqueue_note(b, 3)
  end
end

function enqueue_note(b, z)
  local n = b.n
  if z == 0 then
    n = n + 12
  elseif z == 1 then
    n = n - 12
  end
  n = math.max(min_note, math.min(max_note, n))
  table.insert(note_queue, n)
end

function play_notes()
  -- send note off for previously played notes
  while #note_off_queue > 0 do
    m.send({type='note_off', note=table.remove(note_off_queue)})
  end
  -- play queued notes
  while #note_queue > 0 do
    local n = table.remove(note_queue)
    n = MusicUtil.snap_note_to_array(n, scale_notes)
    engine.hz(MusicUtil.note_num_to_freq(n))
    m.send({type='note_on', note=n})
    table.insert(note_off_queue, n)
  end
end
