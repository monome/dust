-- gong
-- polyphonic fm synth

local ControlSpec = require 'controlspec'
local Voice = require 'exp/voice'

engine.name = 'R'

local partial_spec = ControlSpec.new(0.5, 10, 'lin', 0.25, 1)

local lpfcutoff_spec = ControlSpec.new(20, 10000, 'exp', 0, 10000, " Hz")
local lpfres_spec = ControlSpec.UNIPOLAR
local hpfcutoff_spec = ControlSpec.new(1, 10000, 'exp', 0, 1, " Hz")
local hpfres_spec = ControlSpec.UNIPOLAR

local envattack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.01, "secs")
local envdecay_spec = ControlSpec.new(0, 1, 'lin', 0, 0.3, "secs")
local envsustain_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
local envrelease_spec = ControlSpec.new(0, 3, 'lin', 0, 1, "secs")

local delay_time_spec = ControlSpec.DELAY:copy()
delay_time_spec.maxval = 3

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
    print(name..voiceref, param, value)
    engine.param(name..voiceref, param, value)
  end
end

local function trig_voice(voicenum, freq)
  print("trig_voice: "..voicenum..", "..freq)
  r_param("fm", voicenum, "osc1freq", freq * params:get("osc1/partial"))
  r_param("fm", voicenum, "osc2freq", freq * params:get("osc2/partial"))
  r_param("fm", voicenum, "osc3freq", freq * params:get("osc3/partial"))
  r_param("fm", voicenum, "osc4freq", freq * params:get("osc4/partial"))
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
      noteslots[voicenum] = nil
    end
    note_downs[voicenum] = true
    screen_update_voice_indicators()
  end
end

local function note_off(note)
  slot = noteslots[note]
  if slot then
    voice:release(slot)
    note_downs[slot.id] = false
    screen_update_voice_indicators()
  end
end

--[[
local notes = {}
local ons = {}

local function contains(tab, element)
  for _, e in ipairs(tab) do
    if e == element then
      return true
    end
  end
  return false
end

local function first(tab, element)
  for _, e in ipairs(tab) do
    return e
  end
  return nil
end

local function detect_index(tab, func)
  -- TODO
end

local function remove_element(tab, element)
  -- TODO
end

local function note_on(note, velocity)
  local voicenum
  if not contains(notes, note) then
    if #ons == polyphony then
      local voicetosteal = first(ons)
			release_voice(voicetosteal)
			voicenum = voicetosteal
      table.remove(ons, 1)
      ons[#ons+1] = voicetosteal
      print("stole: "..voicetosteal..", "..note..", "..ons)
    else
			--voicenum = ((0..~polyphony-1) + (ons.maxItem ? 0) % ~polyphony).removeAll(ons).first;
			ons = ons.add(voicenum);
			[voicenum, note, ons].debug(\new);
    end
    notes[voicenum] = note
    print("notes: "..notes)
    trig_voice(voicenum, midicps(note))
  end
end

local function note_off(note)
	local voicenum
	if contains(notes, note) then
		voicenum = detect_index(notes, function(n)
      return n == note
    end)
		table.remove(ons, voicenum)
		notes[voicenum] = nil
		print("off: "..voicenum..", "..note..", "..ons)
		print("notes: "..notes)
		release_voice(voicenum)
  end
end
]]

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

  for oscnum=1,4 do
    params:add_control("osc"..oscnum.."/gain", ControlSpec.DB)
    params:set_action("osc"..oscnum.."/gain", function(value) all_fm("osc"..oscnum.."gain", value) end)
    params:add_control("osc"..oscnum.."/partial", partial_spec)

    params:add_control("osc"..oscnum.." > out", ControlSpec.DB)
    params:set_action("osc"..oscnum.." > out", function(value) all_fm("osc"..oscnum.."outlevel", value) end)

    for dest=1,4 do
      params:add_control("osc"..oscnum.." > osc"..dest.."/freq", ControlSpec.DB)
      params:set_action("osc"..oscnum.." > osc"..dest.."/freq", function(value) all_fm("osc"..dest.."freqosc"..oscnum.."mod", value) end)
      params:set("osc"..oscnum.." > osc"..dest.."/freq", -60)
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
    params:add_control("env1 > osc"..oscnum.."/freq", ControlSpec.DB)
    params:set_action("env1 > osc"..oscnum.."/freq", function(value) all_fm("osc"..oscnum.."freqenvmod", value) end)
    params:set("env1 > osc"..oscnum.."/freq", -60)

    params:add_control("env1 > osc"..oscnum.."/level", ControlSpec.DB)
    params:set_action("env1 > osc"..oscnum.."/level", function(value) all_fm("osc"..oscnum.."levelenvmod", value) end)
    params:set("env1 > osc"..oscnum.."/level", -60)
  end

  params:set("osc1/gain", 0)
  params:set("osc1 > out", -20)
end

local all_poles = function(param, value)
  r_param("pole", "all", param, value)
end

local function add_pole_params()
  params:add_control("lpf/cutoff", lpfcutoff_spec)
  params:set_action("lpf/cutoff", function(value) all_poles("lpfcutoff", value) end)

  params:add_control("lpf/resonance", lpfres_spec)
  params:set_action("lpf/resonance", function(value) all_poles("lpfres", value) end)

  params:add_control("hpf/cutoff", hpfcutoff_spec)
  params:set_action("hpf/cutoff", function(value) all_poles("hpfcutoff", value) end)

  params:add_control("hpf/resonance", hpfres_spec)
  params:set_action("hpf/resonance", function(value) all_poles("hpfres", value) end)

  params:add_control("amp/gain", ControlSpec.DB)
  params:set_action("amp/gain", function(value) all_poles("ampgain", value) end)

  params:add_control("lfo/rate", ControlSpec.LOFREQ)
  params:set_action("lfo/rate", function(value) all_poles("envattack", value) end)

  params:add_control("env2/attack", envattack_spec)
  params:set_action("env2/attack", function(value) all_poles("envattack", value) end)

  params:add_control("env2/decay", envdecay_spec)
  params:set_action("env2/decay", function(value) all_poles("envdecay", value) end)

  params:add_control("env2/sustain", envsustain_spec)
  params:set_action("env2/sustain", function(value) all_poles("envsustain", value) end)

  params:add_control("env2/release", envrelease_spec)
  params:set_action("env2/release", function(value) all_poles("envrelease", value) end)

  params:add_control("lfo > lpf/cutoff", ControlSpec.DB)
  params:set_action("lfo > lpf/cutoff", function(value) all_poles("lpfcutofflfomod", value) end)
  params:set("lfo > lpf/cutoff", -60)

  params:add_control("env2 > lpf/cutoff", ControlSpec.DB)
  params:set_action("env2 > lpf/cutoff", function(value) all_poles("lpfcutoffenvmod", value) end)
  params:set("env2 > lpf/cutoff", -60)

  params:add_control("lfo > lpf/resonance", ControlSpec.DB)
  params:set_action("lfo > lpf/resonance", function(value) all_poles("lpfcutoffresmod", value) end)
  params:set("lfo > lpf/resonance", -60)

  params:add_control("env2 > lpf/resonance", ControlSpec.DB)
  params:set_action("env2 > lpf/resonance", function(value) all_poles("lpfresenvmod", value) end)
  params:set("env2 > lpf/resonance", -60)

  params:add_control("env2 > hpf/cutoff", ControlSpec.DB)
  params:set_action("env2 > hpf/cutoff", function(value) all_poles("hpfcutoffenvmod", value) end)
  params:set("env2 > hpf/cutoff", -60)

  params:add_control("env2 > hpf/cutoff", ControlSpec.DB)
  params:set_action("env2 > hpf/cutoff", function(value) all_poles("hpfcutoffenvmod", value) end)
  params:set("env2 > hpf/cutoff", -60)

  params:add_control("lfo > hpf/resonance", ControlSpec.DB)
  params:set_action("lfo > hpf/resonance", function(value) all_poles("hpfcutoffresmod", value) end)
  params:set("lfo > hpf/resonance", -60)

  params:add_control("env2 > hpf/resonance", ControlSpec.DB)
  params:set_action("env2 > hpf/resonance", function(value) all_poles("hpfresenvmod", value) end)
  params:set("env2 > hpf/resonance", -60)

  params:add_control("lfo > amp/gain", ControlSpec.DB)
  params:set_action("lfo > amp/gain", function(value) all_poles("amplfomod", value) end)
  params:set("lfo > amp", 0)

  params:add_control("env2 > amp/gain", ControlSpec.DB)
  params:set_action("env2 > amp/gain", function(value) all_poles("ampenvmod", value) end)
  params:set("env2 > amp", 0)
end

local function add_delay_params()
  params:add_control("delay send", ControlSpec.DB)
  params:set_action("delay send", function(value)
    for voicenum=1,polyphony do
      engine.patch("pole"..voicenum, "ldelay", value)
      engine.patch("pole"..voicenum, "rdelay", value)
    end
  end)

  params:add_control("delay time/left", delay_time_spec)
  params:set_action("delay time/left", function(value)
    engine.param("ldelay", "delaytime", value)
  end)
  params:add_control("delay time/right", delay_time_spec)
  params:set_action("delay time/right", function(value)
    engine.param("rdelay", "delaytime", value)
  end)

  params:add_control("delay feedback", ControlSpec.DB)
  params:set_action("delay feedback", function(value)
    engine.patch('ldelay', 'rdelay', value)
    engine.patch('rdelay', 'ldelay', value)
  end)

  params:set("delay send", -30)
  params:set("delay time/left", 0.23)
  params:set("delay time/right", 0.45)
  params:set("delay feedback", -20)
end

init = function()
  setup_r_config()
  add_fmthing_params()
  add_pole_params()
  add_delay_params()
  params:bang()

  voice = Voice.new(polyphony)
  params:read("gong.pset")

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
  params:write("gong.pset")
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
