-- gong
-- polyphonic fm synth

local ControlSpec = require 'controlspec'
local Control = require 'control'
local Formatters = require 'jah/formatters'

engine.name = 'R'

local fm_osc1level_spec = ControlSpec.DB
local fm_osc1outlevel_spec = ControlSpec.DB
local fm_osc2level_spec = ControlSpec.DB
local fm_osc1freqosc2mod_spec = ControlSpec.DB

local partial_spec = ControlSpec.new(0.5, 10, 'lin', 0.5, 1)

local pole_envattack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
local pole_envdecay_spec = ControlSpec.new(0, 1, 'lin', 0, 0.3, "secs")
local pole_envsustain_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "secs")
local pole_envrelease_spec = ControlSpec.new(0, 3, 'lin', 0, 1, "secs")
local pole_ampenvmod_spec = ControlSpec.DB

--[[
local pole_lowpassfiltercutoff_spec = ControlSpec(20, 10000, 'exp', 0, 440, " Hz")
local pole_lowpassfilterres_spec = ControlSpec.UNIPOLAR
local pole_highpassfiltercutoff = ControlSpec(20, 10000, 'exp', 0, 440, " Hz")
local pole_highpassfilterres = ControlSpec.UNIPOLAR
]]

local polyphony = 4
local midinote_indicator_level
local midicc_indicator_level
local note_downs = {}

local function to_hz(note)
  local exp = (note - 21) / 12
  return 27.5 * 2^exp
end

local function screen_update_channels()
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

local function r_voice(voicenum, name, param, value)
  engine.param(name..voicenum, param, value)
end

local function r_all(name, param, value)
  for voicenum=1,polyphony do
    r_voice(voicenum, name, param, value)
  end
end

local function fm_all(param, value)
  r_all("fm", param, value)
end

local function fm_voice(voicenum, param, value)
  r_voice(voicenum, "fm", param, value)
end

local function pole_all(param, value)
  r_all("pole", param, value)
end

local function pole_voice(voicenum, param, value)
  r_voice(voicenum, "pole", param, value)
end

local function alloc_voice(voicenum, freq)
  fm_voice(voicenum, "osc1freq", freq)
  fm_voice(voicenum, "osc2freq", freq * params:get("osc2partial"))
  pole_voice(voicenum, "envgate", 1)
end

local function free_voice(voicenum)
  pole_voice(voicenum, "envgate", 0)
end

local function note_on(note, velocity)
  local voicenum = 1
  note_downs[voicenum] = true
  alloc_voice(voicenum, to_hz(note))
  screen_update_channels()
end

local function note_off(note)
  local voicenum = 1
  note_downs[voicenum] = false
  free_voice(voicenum)
  screen_update_channels()
end

init = function()
  screen.aa(1)
  screen.line_width(1.0)

  engine.capacity(polyphony*2+2)

  for voicenum=1,polyphony do
    engine.module("fm"..voicenum, "fmthing")
    engine.module("pole"..voicenum, "newpole")
    engine.patch("fm"..voicenum, "pole"..voicenum, 0)
  end

  engine.module("lout", "output")
  engine.module("rout", "output")
  engine.param("rout", "config", 1)

  for voicenum=1,polyphony do
    engine.patch("pole"..voicenum, "lout", 0)
    engine.patch("pole"..voicenum, "rout", 0)
  end

  params:add_control("osc1level", fm_osc1level_spec)
  params:set("osc1level", -10)
  params:set_action("osc1level", function(value) fm_all("osc1level", value) end)
  params:add_control("osc1outlevel", fm_osc1outlevel_spec)
  params:set("osc1outlevel", -10)
  params:set_action("osc1outlevel", function(value) fm_all("osc1outlevel", value) end)
  params:add_control("osc2level", fm_osc2level_spec)
  params:set("osc2level", 0)
  params:set_action("osc2level", function(value) fm_all("osc2level", value) end)
  params:add_control("osc2partial", partial_spec)
  params:add_control("osc1freqosc2mod", fm_osc1freqosc2mod_spec)
  params:set("osc1freqosc2mod", -15)
  params:set_action("osc1freqosc2mod", function(value) fm_all("osc1freqosc2mod", value) end)
  params:add_control("ampenv/attack", pole_envattack_spec)
  params:set_action("ampenv/attack", function(value) pole_all("envattack", value) end)
  params:add_control("ampenv/decay", pole_envdecay_spec)
  params:set_action("ampenv/decay", function(value) pole_all("envdecay", value) end)
  params:add_control("ampenv/sustain", pole_envsustain_spec)
  params:set_action("ampenv/sustain", function(value) pole_all("envsustain", value) end)
  params:add_control("ampenv/release", pole_envrelease_spec)
  params:set_action("ampenv/release", function(value) pole_all("envrelease", value) end)
  params:add_control("ampenvmod", pole_ampenvmod_spec)
  params:set("ampenvmod", 0)
  params:set_action("ampenvmod", function(value) pole_all("ampenvmod", value) end)

  -- params:read("param_ack.pset")
  params:bang()
end

redraw = function()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("gong")
  screen_update_channels()
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
  -- params:write("param_ack.pset")
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
