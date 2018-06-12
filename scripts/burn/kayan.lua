-- kayan: probabalistic
-- melody discovery
--
-- ENC2 = reveal melody
-- KEY2 = discover new melody
--
-- support your local
-- rainforest
--
-- created by @burn

engine.name = 'KarplusRings'

local cs = require 'controlspec'

local sequence = {
  pos = 0,
  note_data = {},
  prob_data = {}
}

local reveal_level = 35;
local octave_range = 2;
local transpose = 2;
local seq_length = 32;
local scale_data = {};
local animation_counter = 0;
local animation_flipflop = true;
local pluck_distance = 0;

function init()

  params:add_number("tempo",20,240,48)
  params:set_action("tempo", function(n)
    t.time = 15/n
  end)

  params:add_number("length",4,64,32)
  params:set_action("length", function(n)
    seq_length = n;
  end)

  params:add_number("transpose",0,5,2)
  params:set_action("transpose", function(n)
    transpose = n;
  end)

  params:add_number("octave_range",1,4,2)
  params:set_action("octave_range", function(n)
    octave_range = n;
  end)

  params:add_separator()

  cs.AMP = cs.new(0,1,'lin',0,0.5,'')
  params:add_control("amp",cs.AMP)
  params:set_action("amp",
  function(x) engine.amp(x) end)

  cs.DECAY = cs.new(0.1,15,'lin',0,3.6,'s')
  params:add_control("damping",cs.DECAY)
  params:set_action("damping",
  function(x) engine.decay(x) end)

  cs.COEF = cs.new(0,1,'lin',0,0.11,'')
  params:add_control("brightness",cs.COEF)
  params:set_action("brightness",
  function(x) engine.coef(x) end)

  cs.LPF_FREQ = cs.new(100,10000,'lin',0,4500,'')
  params:add_control("lpf_freq",cs.LPF_FREQ)
  params:set_action("lpf_freq",
  function(x) engine.lpf_freq(x) end)

  cs.LPF_GAIN = cs.new(0,3.2,'lin',0,0.5,'')
  params:add_control("lpf_gain",cs.LPF_GAIN)
  params:set_action("lpf_gain",
  function(x) engine.lpf_gain(x) end)

  cs.BPF_FREQ = cs.new(100,10000,'lin',0,0.5,'')
  params:add_control("bpf_freq",cs.BPF_FREQ)
  params:set_action("bpf_freq",
  function(x) engine.bpf_freq(x) end)

  cs.BPF_RES = cs.new(0,4,'lin',0,0.5,'')
  params:add_control("bpf_res",cs.BPF_RES)
  params:set_action("bpf_res",
  function(x) engine.bpf_res(x) end)

  create_scale_data();
  create_sequence_data();

  create_playloop_metro()
  create_animation_metro()

  params:bang()
end

function create_scale_data()
  -- want a custom scale? define it here.
  scale = {0,2,3,5,7,10}

  scale_data = {}

  -- copy the scale over 4 octaves
  for octave=0,3 do
    for scale_note = 1,#scale do
      if scale[scale_note] > 11 then error("Note values must be between 0 and 11 inclusive") end
      table.insert(scale_data, (scale[scale_note]+(octave*12)))
    end
  end
  -- scale_data = {0,2,3,5,7,10,12,14,15,17,19,22,24,26,27,29,31,34,36,38,39,41,43,46}
end

-- create all of the note and probability data on init
function create_sequence_data()
  for i=1, 64 do
    sequence.note_data[i] = scale_data[math.random (1, #scale_data)];
    sequence.prob_data[i] = math.random (1, 100);
  end
end

function create_playloop_metro()
  t = metro.alloc()
  t.count = -1
  t.time = 15/params:get("tempo")

  t.callback = function(stage)
    sequence.pos = sequence.pos + 1
    if sequence.pos > seq_length then sequence.pos = 1 end

    -- does the note playing
    if sequence.prob_data[sequence.pos] <= reveal_level then
      animation_counter = 30;
      engine.hz((55*2^(((transpose * 12)+(sequence.note_data[sequence.pos] % (octave_range*12)))/12)))
    end
  end

  t:start()
end

function create_animation_metro()
  x = metro.alloc()

  x.callback = function(stage)
    if norns.menu.status() == false then draw_screen() end
  end

  x:start(0.0224)
end

function key(n, z)
  if n == 2 and z == 0 then
    create_sequence_data();
  end
end

function enc(n, delta)
  if n == 2 then
    animation_counter = 0
    reveal_level = reveal_level + delta
    if reveal_level > 100 then reveal_level = 100 end
    if reveal_level < 0 then reveal_level = 0 end
    draw_screen()
  end
end

function draw_screen()
  if animation_counter >= 0 then
    screen.clear()
    screen.level(15)
    screen.aa(2)
    screen.move(0,32)

    if animation_flipflop == true then
      pluck_distance = 30-(animation_counter/3)
      animation_flipflop = false
    else
      pluck_distance = 30+(animation_counter/3)
      screen.stroke()
      animation_flipflop = true
    end

    screen.curve(-5,32,60,pluck_distance,130,32)
    screen.stroke()
  end

    screen.font_face(0)
    screen.font_size(8)
    screen.level(15)
    -- draw right aligned text
    screen.move(127,63)
    screen.text_right("reveal " .. reveal_level.."%")
    screen.update()

    animation_counter = animation_counter - 1
end
