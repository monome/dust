-- hello_gong:

-- hello gong.
-- 6 voice polyphonic fm synth
-- controlled by midi
--
-- enc2: timbre macro control
-- enc3: time macro control
-- key2: trig random note
--
-- more parameters in
-- menu > parameters
--
-- midi: play notes
--

local ControlSpec = require 'controlspec'
local Voice = require 'exp/voice'
local Gong = require 'jah/gong'

engine.name = 'Gong'

local POLYPHONY = 6
local midinote_indicator_level = 0
local midicc_indicator_level = 0
local note_downs = {}

local function screen_update_voice_indicators()
  screen.move(0,16)
  screen.font_size(8)
  for voicenum=1,POLYPHONY do
    if note_downs[voicenum] then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.text(voicenum)
  end
end

local function screen_update_midi_indicators()
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

local function trig_voice(voicenum, note)
  engine.noteOn(voicenum, note)
end

local function release_voice(voicenum)
  engine.noteOff(voicenum)
end

local noteslots = {}

local function note_on(note, velocity)
  if not noteslots[note] then
    local slot = voice:get()
    local voicenum = slot.id
    trig_voice(voicenum, note)
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

local function default_patch()
  params:set("osc2 > osc3 freq", 1)
  params:set("osc2 partial no", 2)
  params:set("osc3 gain", 1)
  params:set("osc3 index", 5)
  params:set("osc3 > out", 0.1)
  params:set("env1 > osc2 gain", 1)
  params:set("env2 > amp gain", 1)
  params:set("delay send", -20)
  params:set("delay time left", 0.03)
  params:set("delay time right", 0.05)
  params:set("delay feedback", -30)
end

function init()
  Gong.add_params()

  voice = Voice.new(POLYPHONY)
  -- params:read("gong.pset")

  screen.line_width(1.0)
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("hello gong")
  screen_update_voice_indicators()
  screen_update_midi_indicators()
  screen.update()
end

enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
  elseif n == 2 then
    params:delta("timbre", delta)
  elseif n == 3 then
    params:delta("timemod", delta)
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
    --[[
  elseif status == 176 then
    midicc_indicator_level = math.random(15)
    cc(data1, data2)
    redraw()
  elseif status == 224 then
    bend(data1, data2)
    ]]
  end
end
