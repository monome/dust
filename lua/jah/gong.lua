-- gong
-- polyphonic fm synth

local ControlSpec = require 'controlspec'
local VoiceAllocator = require 'lib/exp/voice'


engine.name = 'R'

local oscxlevel_spec = ControlSpec.DB
local oscxoutlevel_spec = ControlSpec.DB
local oscxfreqoscxmod_spec = ControlSpec.DB

local partial_spec = ControlSpec.new(0.5, 10, 'lin', 0.5, 1)

local lpfcutoff_spec = ControlSpec(20, 10000, 'exp', 0, 440, " Hz")
local lpfres_spec = ControlSpec.UNIPOLAR
local hpfcutoff = ControlSpec(1, 10000, 'exp', 0, 440, " Hz")
local hpfres = ControlSpec.UNIPOLAR

local envattack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
local envdecay_spec = ControlSpec.new(0, 1, 'lin', 0, 0.3, "secs")
local envsustain_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "secs")
local envrelease_spec = ControlSpec.new(0, 3, 'lin', 0, 1, "secs")
local envmod_spec = ControlSpec.DB

local delay_time_spec = ControlSpec.DELAY:copy()
delay_time_spec.maxval = 3

local polyphony = 4
local midinote_indicator_level
local midicc_indicator_level
local note_downs = {}

local function to_hz(note)
  local exp = (note - 21) / 12
  return 27.5 * 2^exp
end

local function screen_update_voice_indicators()
  screen.move(0,16)
  screen.font_size(8)
  for voicenum=1,polyphony do
    if note_downs[voicenum] then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.text(voicenum)
  end
  screen.update()
end

local function screen_update_midi_indicators()
  --screen.move(125, 20)
  screen.move(0,60)
  screen.font_size(8)
  if midi_available then
    screen.level(15)
    screen.text("midi:")
    screen.text(" ")
    screen.level(midinote_indicator_level)
    screen.text("note ")
    screen.level(midicc_indicator_level)
    screen.text("cc")
  else
    screen.level(3)
    screen.text("no midi")
  end
end

local function r_param(name, voiceref, param, value)
  if voiceref == "all" then
    for voicenum=1,polyphony do
      engine.param(name..voicenum, param, value)
    end
  else
    engine.param(name..voiceref, param, value)
  end
end

local function alloc_voice(voicenum, freq)
  r_param("fm", voicenum, "osc1freq", freq)
  r_param("fm", voicenum, "osc2freq", freq * params:get("osc2/partial"))
  r_param("pole", voicenum, "envgate", 1)
end

local function free_voice(voicenum)
  r_param("pole", voicenum, "envgate", 0)
end

local function note_on(note, velocity)
  --[[
  local voicenum = 1
  note_downs[voicenum] = true
  alloc_voice(voicenum, to_hz(note))
  screen_update_voice_indicators()
  ]]
  alloc_voice(voicenum, to_hz(note))
  global_slot = global_va:get()
  global_slot.on_release = function()
    free_voice(voicenum)
  end
end

local function note_off(note)
  --[[
  local voicenum = 1
  note_downs[voicenum] = false
  free_voice(voicenum)
  screen_update_voice_indicators()
  ]]
  global_va:release(global_slot)
end

local function setup_r_config()
  engine.capacity(polyphony*2+2+2)

  for voicenum=1,polyphony do
    engine.module("fm"..voicenum, "fmthing")
    engine.module("pole"..voicenum, "newpole")
    engine.patch("fm"..voicenum, "pole"..voicenum, 0)
  end

  engine.module("ldelay", "delay")
  engine.module("rdelay", "delay")

  engine.patch("ldelay", "lout", 0)
  engine.patch("rdelay", "rout", 0)

  engine.module("lout", "output")
  engine.module("rout", "output")
  engine.param("rout", "config", 1) -- TODO: split output up in left and right?

  for voicenum=1,polyphony do
    engine.patch("pole"..voicenum, "lout", 0)
    engine.patch("pole"..voicenum, "rout", 0)
  end
end

local function add_fmthing_params()
  local all_fm = function(param, value)
    r_param("fm", "all", param, value)
  end

  params:add_control("osc1/level", oscxlevel_spec)
  params:set("osc1/level", -10)
  params:set_action("osc1/level", function(value) all_fm("osc1level", value) end)

  params:add_control("osc1/outlevel", oscxoutlevel_spec)
  params:set("osc1/outlevel", -10)
  params:set_action("osc1/outlevel", function(value) all_fm("osc1outlevel", value) end)

  params:add_control("osc1/freqosc2mod", oscxfreqoscxmod_spec)
  params:set("osc1/freqosc2mod", -15)
  params:set_action("osc1/freqosc2mod", function(value) all_fm("osc1freqosc2mod", value) end)

  params:add_control("osc2/level", oscxlevel_spec)
  params:set("osc2/level", 0)
  params:set_action("osc2/level", function(value) all_fm("osc2level", value) end)

  params:add_control("osc2/partial", partial_spec)

end

local all_poles = function(param, value)
  r_param("pole", "all", param, value)
end

local function add_pole_params()
  params:add_control("lpf/cutoff", lpfcutoff_spec)
  params:set_action("lpf/cutoff", function(value) all_poles("lpfcutoff", value) end)
  params:add_control("lpf/resonance", lpfres_spec)
  params:set_action("lpf/resonance", function(value) all_poles("lpfres", value) end)

  params:add_control("hpf/cutoff", lpfcutoff_spec)
  params:set_action("hpf/cutoff", function(value) all_poles("hpfcutoff", value) end)
  params:add_control("hpf/resonance", lpfres_spec)
  params:set_action("hpf/resonance", function(value) all_poles("hpfres", value) end)

  params:add_control("env2/attack", envattack_spec)
  params:set_action("env2/attack", function(value) all_poles("envattack", value) end)

  params:add_control("env2/decay", envdecay_spec)
  params:set_action("env2/decay", function(value) all_poles("envdecay", value) end)

  params:add_control("env2/sustain", envsustain_spec)
  params:set_action("env2/sustain", function(value) all_poles("envsustain", value) end)

  params:add_control("env2/release", envrelease_spec)
  params:set_action("env2/release", function(value) all_poles("envrelease", value) end)

  params:add_control("env2/ampmod", envmod_spec)
  params:set("env2/ampmod", 0)
  params:set_action("env2/ampmod", function(value) all_poles("ampenvmod", value) end)

  params:add_control("env2/lpf/cutoffmod", envmod_spec)
  params:set("env2/lpf/cutoffmod", -60)
  params:set_action("env2/lpf/cutoffmod", function(value) all_poles("lpfcutoffenvmod", value) end)

  params:add_control("env2/hpf/cutoffmod", envmod_spec)
  params:set("env2/hpf/cutoffmod", -60)
  params:set_action("env2/hpf/cutoffmod", function(value) all_poles("hpfcutoffenvmod", value) end)
end

local function add_delay_params()
  params:add_control("delay send", ControlSpec.DB)
  params:set("delay send", -30)
  params:set_action("delay send", function(value)
    all_poles("ldelay", value)
    all_poles("rdelay", value)
  end)

  params:add_control("delay time/left", delay_time_spec)
  params:set("delay time/left", 0.23)
  params:set_action("delay time/left", function(value)
    engine.param("ldelay", "delaytime", value)
  end)
  params:add_control("delay time/right", delay_time_spec)
  params:set("delay time/right", 0.45)
  params:set_action("delay time/right", function(value)
    engine.param("rdelay", "delaytime", value)
  end)

  params:add_control("delay feedback", ControlSpec.DB)
  params:set("delay feedback", -20)
  params:set_action("delay feedback", function(value)
    engine.patch('ldelay', 'rdelay', value)
    engine.patch('rdelay', 'ldelay', value)
  end)
end

init = function()
  setup_r_config()
  add_fmthing_params()
  add_pole_params()
  add_delay_params()

  global_va = Voice.new(polyphony)
  -- params:read("gong.pset")
  params:bang()

  screen.line_width(1.0)
end

redraw = function()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("gong")
  screen_update_voice_indicators()
  screen_update_midi_indicators()
  screen.update()
end

enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
  end
end

key = function(n, z)
  if n == 2 and z == 1 then
    note_on(60, 100)
  elseif n == 2 and z == 0 then
    note_off(60)
  elseif n == 3 and z == 1 then
    note_on(64, 100)
  elseif n == 3 and z == 0 then
    note_off(64)
  end
end

cleanup = function()
  norns.midi.event = nil
  -- params:write("gong.pset")
end

norns.midi.add = function(id, name, dev)
  midi_available = true
  midinote_indicator_level = 3
  midicc_indicator_level = 3
  redraw()
end

norns.midi.remove = function(id)
  midi_available = false
  redraw()
end

norns.midi.event = function(id, data)
  status = data[1]
  data1 = data[2]
  data2 = data[3]
  if status == 144 then
    midinote_indicator_level = math.random(15)
    --[[
    if data1 == 0 then
      return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
    end
    ]]
    note_on(data1, data2)
    redraw()
  elseif status == 128 then
    --[[
    if data1 == 0 then
      return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
    end
    ]]
    note_off(data1)
  elseif status == 176 then
    midicc_indicator_level = math.random(15)
    cc(data1, data2)
    redraw()
  elseif status == 224 then
    bend(data1, data2)
  end
end
