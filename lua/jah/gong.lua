-- gong
--
-- polyphonic fm synth

local ControlSpec = require 'controlspec'
local Voice = require 'exp/voice'

engine.name = 'R'

local envattack_spec = ControlSpec.new(0, 1000, 'lin', 0, 5, "ms")
local envdecay_spec = ControlSpec.new(0, 5000, 'lin', 0, 500, "ms")
local envsustain_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
local envrelease_spec = ControlSpec.new(0, 5000, 'lin', 0, 1000, "ms")

local polyphony = 3
local midinote_indicator_level
local midicc_indicator_level
local note_downs = {}

local function midicps(note)
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
      print('engine.param("'..name..voicenum..'", '..param..', '..value..')')
      engine.param(name..voicenum, param, value)
    end
  else
    print(name..voiceref, param, value)
    engine.param(name..voiceref, param, value)
  end
end

local function trig_voice(voicenum, freq)
  print("trig_voice: "..voicenum..", "..freq)
  r_param("fm", voicenum, "osc1freq", freq * params:get("osc1/partial"))
  r_param("fm", voicenum, "osc2freq", freq * params:get("osc2/partial"))
  r_param("fm", voicenum, "osc3freq", freq * params:get("osc3/partial"))
  r_param("fm", voicenum, "envgate", 1)
  r_param("pole", voicenum, "envgate", 1)
end

local function release_voice(voicenum)
  print("release_voice: "..voicenum)
  r_param("fm", voicenum, "envgate", 0)
  r_param("pole", voicenum, "envgate", 0)
end

local noteslots = {}

local function note_on(note, velocity)
  print("note_on: "..note..", "..velocity)
  if not noteslots[note] then
    local slot = voice:get()
    local voicenum = slot.id
    trig_voice(voicenum, midicps(note))
    slot.on_release = function()
      release_voice(voicenum)
      noteslots[note] = nil
    end
    noteslots[note] = slot
    note_downs[voicenum] = true
    redraw()
  end
end

local function note_off(note)
  slot = noteslots[note]
  if slot then
    voice:release(slot)
    note_downs[slot.id] = false
    redraw()
  end
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

  engine.module("lout", "output")
  engine.module("rout", "output")
  engine.param("rout", "config", 1) -- TODO: split output up in left and right?

  for voicenum=1,polyphony do
    engine.patch("pole"..voicenum, "lout", 0)
    engine.patch("pole"..voicenum, "rout", 0)
  end

  engine.patch("ldelay", "lout", 0)
  engine.patch("rdelay", "rout", 0)
end

local function add_fmthing_params()
  local all_fm = function(param, value)
    r_param("fm", "all", param, value)
  end

  local partial_spec = ControlSpec.new(1, 10, 'lin', 1, 1)
  local index_spec = ControlSpec.new(0, 24, 'lin', 0, 3, "")

  for oscnum=1,3 do
    params:add_control("osc"..oscnum.."/gain", ControlSpec.AMP)
    params:set_action("osc"..oscnum.."/gain", function(value) all_fm("osc"..oscnum.."gain", value) end)
    params:add_control("osc"..oscnum.."/partial", partial_spec)
    params:add_control("osc"..oscnum.."/index", index_spec)
    params:set_action("osc"..oscnum.."/index", function(value) all_fm("osc"..oscnum.."index", value) end)

    params:add_control("osc"..oscnum.." > out", ControlSpec.UNIPOLAR)
    params:set_action("osc"..oscnum.." > out", function(value) all_fm("osc"..oscnum.."outlevel", value) end)

    for dest=1,3 do
      params:add_control("osc"..oscnum.." > osc"..dest.."/freq", ControlSpec.UNIPOLAR)
      params:set_action("osc"..oscnum.." > osc"..dest.."/freq", function(value) all_fm("osc"..oscnum.."_to_osc"..dest.."freq", value) end)
    end
  end

  params:add_control("env1/attack", envattack_spec)
  params:set_action("env1/attack", function(value) all_fm("envattack", value) end)

  params:add_control("env1/decay", envdecay_spec)
  params:set_action("env1/decay", function(value) all_fm("envdecay", value) end)

  params:add_control("env1/sustain", envsustain_spec)
  params:set_action("env1/sustain", function(value) all_fm("envsustain", value) end)

  params:add_control("env1/release", envrelease_spec)
  params:set_action("env1/release", function(value) all_fm("envrelease", value) end)

  for oscnum=1,4 do
    params:add_control("env1 > osc"..oscnum.."/freq", ControlSpec.BIPOLAR)
    params:set_action("env1 > osc"..oscnum.."/freq", function(value) all_fm("env_to_osc"..oscnum.."freq", value) end)

    params:add_control("env1 > osc"..oscnum.."/gain", ControlSpec.UNIPOLAR)
    params:set_action("env1 > osc"..oscnum.."/gain", function(value) all_fm("env_to_osc"..oscnum.."gain", value) end)
  end
end

local all_poles = function(param, value)
  r_param("pole", "all", param, value)
end

local function add_pole_params()
  params:add_control("lpf/cutoff", ControlSpec.new(20, 10000, 'exp', 0, 10000, "Hz"))
  params:set_action("lpf/cutoff", function(value) all_poles("lpfcutoff", value) end)

  params:add_control("lpf/resonance", ControlSpec.UNIPOLAR)
  params:set_action("lpf/resonance", function(value) all_poles("lpfres", value) end)

  params:add_control("hpf/cutoff", ControlSpec.new(1, 10000, 'exp', 0, 1, "Hz"))
  params:set_action("hpf/cutoff", function(value) all_poles("hpfcutoff", value) end)

  params:add_control("hpf/resonance", ControlSpec.UNIPOLAR)
  params:set_action("hpf/resonance", function(value) all_poles("hpfres", value) end)

  params:add_control("amp/gain", ControlSpec.AMP)
  params:set_action("amp/gain", function(value) all_poles("ampgain", value) end)

  params:add_control("lfo/rate", ControlSpec.LOFREQ)
  params:set_action("lfo/rate", function(value) all_poles("lforate", value) end)

  params:add_control("lfo > lpf/cutoff", ControlSpec.BIPOLAR)
  params:set_action("lfo > lpf/cutoff", function(value) all_poles("lfo_to_lpfcutoff", value) end)

  params:add_control("lfo > hpf/cutoff", ControlSpec.BIPOLAR)
  params:set_action("lfo > hpf/cutoff", function(value) all_poles("lfo_to-hpfcutoff", value) end)

  params:add_control("lfo > hpf/resonance", ControlSpec.BIPOLAR)
  params:set_action("lfo > hpf/resonance", function(value) all_poles("lfo_to_hpfres", value) end)

  params:add_control("lfo > lpf/resonance", ControlSpec.BIPOLAR)
  params:set_action("lfo > lpf/resonance", function(value) all_poles("lfo_to_lpfres", value) end)

  params:add_control("lfo > amp/gain", ControlSpec.BIPOLAR)
  params:set_action("lfo > amp/gain", function(value) all_poles("lfo_to_ampgain", value) end)

  params:add_control("env2/attack", envattack_spec)
  params:set_action("env2/attack", function(value) all_poles("envattack", value) end)

  params:add_control("env2/decay", envdecay_spec)
  params:set_action("env2/decay", function(value) all_poles("envdecay", value) end)

  params:add_control("env2/sustain", envsustain_spec)
  params:set_action("env2/sustain", function(value) all_poles("envsustain", value) end)

  params:add_control("env2/release", envrelease_spec)
  params:set_action("env2/release", function(value) all_poles("envrelease", value) end)

  params:add_control("env2 > amp/gain", ControlSpec.BIPOLAR)
  params:set_action("env2 > amp/gain", function(value) all_poles("env_to_ampgain", value) end)

  params:add_control("env2 > lpf/cutoff", ControlSpec.BIPOLAR)
  params:set_action("env2 > lpf/cutoff", function(value) all_poles("env_to_lpfcutoff", value) end)

  params:add_control("env2 > lpf/resonance", ControlSpec.BIPOLAR)
  params:set_action("env2 > lpf/resonance", function(value) all_poles("env_to_lpfres", value) end)

  params:add_control("env2 > hpf/cutoff", ControlSpec.BIPOLAR)
  params:set_action("env2 > hpf/cutoff", function(value) all_poles("env_to_hpfcutoff", value) end)

  params:add_control("env2 > hpf/resonance", ControlSpec.BIPOLAR)
  params:set_action("env2 > hpf/resonance", function(value) all_poles("env_to_hpfres", value) end)
end

local function add_delay_params()
  params:add_control("delay send", ControlSpec.AMP)
  params:set_action("delay send", function(value)
    for voicenum=1,polyphony do
      engine.patch("pole"..voicenum, "ldelay", value)
      engine.patch("pole"..voicenum, "rdelay", value)
    end
  end)

  local delay_time_spec = ControlSpec.DELAY:copy()
  delay_time_spec.maxval = 3

  params:add_control("delay time/left", delay_time_spec)
  params:set_action("delay time/left", function(value)
    engine.param("ldelay", "delaytime", value)
  end)
  params:add_control("delay time/right", delay_time_spec)
  params:set_action("delay time/right", function(value)
    engine.param("rdelay", "delaytime", value)
  end)

  params:add_control("delay feedback", ControlSpec.AMP)
  params:set_action("delay feedback", function(value)
    engine.patch('ldelay', 'rdelay', value)
    engine.patch('rdelay', 'ldelay', value)
  end)

end

local function default_patch()
  params:set("osc3/gain", 1)
  params:set("osc3 > out", 1)
  params:set("env2 > amp/gain", 1)
  -- params:set("env2 > lpf/cutoff", 1)
  params:set("delay send", 0.9)
  params:set("delay time/left", 0.03)
  params:set("delay time/right", 0.05)
  params:set("delay feedback", 0.9)
end

local timer

init = function()
  setup_r_config()
  add_fmthing_params()
  add_pole_params()
  add_delay_params()
  default_patch()

  timer = metro[1]
  timer:start(0.05, 1)
  timer.callback = function()
    print("banging..")
    params:bang()
    print("..banged")
  end


  voice = Voice.new(polyphony)
  -- params:read("gong.pset")

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
  timer.count = -1 -- TODO: reset to ensure timer set to default, should not be needed
  timer:stop()
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
