-- lag test script
-- (4 voice gong triggered
-- by metro)

local ControlSpec = require 'controlspec'
local Voice = require 'exp/voice'

engine.name = 'R'

local envattack_spec = ControlSpec.new(0, 1000, 'lin', 0, 5, "ms")
local envdecay_spec = ControlSpec.new(0, 5000, 'lin', 0, 500, "ms")
local envsustain_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
local envrelease_spec = ControlSpec.new(0, 5000, 'lin', 0, 1000, "ms")

local POLYPHONY = 4
local INITIAL_NOTE = 60
local notes = {}
local note_downs = {}

local function midicps(note)
  local exp = (note - 21) / 12
  return 27.5 * 2^exp
end

local function r_param(name, voiceref, param, value)
  if voiceref == "all" then
    for voicenum=1, POLYPHONY do
      -- print('engine.param("'..name..voicenum..'", '..param..', '..value..')')
      engine.param(name..voicenum, param, value)
    end
  else
    -- print(name..voiceref, param, value)
    engine.param(name..voiceref, param, value)
  end
end

local function update_osc_freq(voicenum, oscnum)
  if voicenum == "all" then
    for v=1, POLYPHONY do update_osc_freq(v, oscnum) end
  else
    local freq
    if params:get("osc"..oscnum.." type") == 1 then
      freq = midicps(notes[voicenum] or INITIAL_NOTE) * params:get("osc"..oscnum.." partial no")
    else
      freq = params:get("osc"..oscnum.." fixed freq")
    end
    r_param("fm", voicenum, "osc"..oscnum.."freq", freq)
  end
end

local function trig_voice(voicenum, note)
  notes[voicenum] = note
  if params:get("osc1 type") == 1 then
    update_osc_freq(voicenum, 1)
  end
  if params:get("osc2 type") == 1 then
    update_osc_freq(voicenum, 2)
  end
  if params:get("osc3 type") == 1 then
    update_osc_freq(voicenum, 3)
  end
  r_param("fm", voicenum, "envgate", 1)
  r_param("pole", voicenum, "envgate", 1)
end

local function release_voice(voicenum)
  -- print("release_voice: "..voicenum)
  r_param("fm", voicenum, "envgate", 0)
  r_param("pole", voicenum, "envgate", 0)
end

local noteslots = {}

local function note_on(note, velocity)
  -- print("note_on: "..note..", "..velocity)
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
  end
end

local function note_off(note)
  slot = noteslots[note]
  if slot then
    voice:release(slot)
    note_downs[slot.id] = false
  end
end

local function setup_r_config()
  engine.capacity(POLYPHONY*2+2+2)

  for voicenum=1, POLYPHONY do
    engine.module("fm"..voicenum, "fmthing")
    engine.module("pole"..voicenum, "newpole")
    engine.patch("fm"..voicenum, "pole"..voicenum, 0)
  end

  engine.module("ldelay", "delay")
  engine.module("rdelay", "delay")

  engine.module("lout", "output")
  engine.module("rout", "output")
  engine.param("rout", "config", 1) -- TODO: split output up in left and right?

  for voicenum=1, POLYPHONY do
    engine.patch("pole"..voicenum, "lout", 0)
    engine.patch("pole"..voicenum, "rout", 0)
  end

  engine.patch("ldelay", "lout", 0)
  engine.patch("rdelay", "rout", 0)
end

local all_fm = function(param, value)
  r_param("fm", "all", param, value)
end

local function add_fmthing_params()
  local numoscs = 3
  local partial_spec = ControlSpec.new(0.5, 10, 'lin', 0.25, 1)
  local index_spec = ControlSpec.new(0, 24, 'lin', 0, 3, "")

  for oscnum=1,numoscs do
    params:add_control("osc"..oscnum.." gain", ControlSpec.AMP)
    -- params:set_action("osc"..oscnum.." gain", function(value) all_fm("osc"..oscnum.."gain", value) end)
    params:set_action("osc"..oscnum.." gain", function(value)
      for voicenum=1, POLYPHONY do
        engine.param("fm"..voicenum, "osc"..oscnum.."gain", value)
      end
    end)

    local osc_type_action = function(value)
      update_osc_freq("all", oscnum)
    end
    params:add_option("osc"..oscnum.." type", {"partial", "fixed"})
    params:set_action("osc"..oscnum.." type", osc_type_action)
    params:add_control("osc"..oscnum.." partial no", partial_spec)
    params:set_action("osc"..oscnum.." partial no", osc_type_action)
    params:add_control("osc"..oscnum.." fixed freq", ControlSpec.WIDEFREQ)
    params:set_action("osc"..oscnum.." fixed freq", osc_type_action)
    params:add_control("osc"..oscnum.." index", index_spec)
    params:set_action("osc"..oscnum.." index", function(value) all_fm("osc"..oscnum.."index", value) end)

    params:add_control("osc"..oscnum.." > out", ControlSpec.UNIPOLAR)
    params:set_action("osc"..oscnum.." > out", function(value) all_fm("osc"..oscnum.."outlevel", value) end)

    for dest=1,numoscs do
      params:add_control("osc"..oscnum.." > osc"..dest.." freq", ControlSpec.UNIPOLAR)
      params:set_action("osc"..oscnum.." > osc"..dest.." freq", function(value) all_fm("osc"..oscnum.."_to_osc"..dest.."freq", value) end)
    end
  end

  params:add_control("env1 attack", envattack_spec)
  params:set_action("env1 attack", function(value) all_fm("envattack", value) end)

  params:add_control("env1 decay", envdecay_spec)
  params:set_action("env1 decay", function(value) all_fm("envdecay", value) end)

  params:add_control("env1 sustain", envsustain_spec)
  params:set_action("env1 sustain", function(value) all_fm("envsustain", value) end)

  params:add_control("env1 release", envrelease_spec)
  params:set_action("env1 release", function(value) all_fm("envrelease", value) end)

  for oscnum=1,numoscs do
    params:add_control("env1 > osc"..oscnum.." freq", ControlSpec.BIPOLAR)
    params:set_action("env1 > osc"..oscnum.." freq", function(value) all_fm("env_to_osc"..oscnum.."freq", value) end)

    params:add_control("env1 > osc"..oscnum.." gain", ControlSpec.UNIPOLAR)
    params:set_action("env1 > osc"..oscnum.." gain", function(value) all_fm("env_to_osc"..oscnum.."gain", value) end)
  end
end

local all_poles = function(param, value)
  r_param("pole", "all", param, value)
end

local function add_pole_params()
  params:add_control("lpf cutoff", ControlSpec.new(20, 10000, 'exp', 0, 10000, "Hz"))
  params:set_action("lpf cutoff", function(value) all_poles("lpfcutoff", value) end)

  params:add_control("lpf resonance", ControlSpec.UNIPOLAR)
  params:set_action("lpf resonance", function(value) all_poles("lpfres", value) end)

  params:add_control("hpf cutoff", ControlSpec.new(1, 10000, 'exp', 0, 1, "Hz"))
  params:set_action("hpf cutoff", function(value) all_poles("hpfcutoff", value) end)

  params:add_control("hpf resonance", ControlSpec.UNIPOLAR)
  params:set_action("hpf resonance", function(value) all_poles("hpfres", value) end)

  params:add_control("amp gain", ControlSpec.AMP)
  params:set_action("amp gain", function(value) all_poles("ampgain", value) end)

  params:add_control("lfo rate", ControlSpec.LOFREQ)
  params:set_action("lfo rate", function(value) all_poles("lforate", value) end)

  params:add_control("lfo > lpf cutoff", ControlSpec.BIPOLAR)
  params:set_action("lfo > lpf cutoff", function(value) all_poles("lfo_to_lpfcutoff", value) end)

  params:add_control("lfo > hpf cutoff", ControlSpec.BIPOLAR)
  params:set_action("lfo > hpf cutoff", function(value) all_poles("lfo_to_hpfcutoff", value) end)

  params:add_control("lfo > hpf resonance", ControlSpec.BIPOLAR)
  params:set_action("lfo > hpf resonance", function(value) all_poles("lfo_to_hpfres", value) end)

  params:add_control("lfo > lpf resonance", ControlSpec.BIPOLAR)
  params:set_action("lfo > lpf resonance", function(value) all_poles("lfo_to_lpfres", value) end)

  params:add_control("lfo > amp gain", ControlSpec.BIPOLAR)
  params:set_action("lfo > amp gain", function(value) all_poles("lfo_to_ampgain", value) end)

  params:add_control("env2 attack", envattack_spec)
  params:set_action("env2 attack", function(value) all_poles("envattack", value) end)

  params:add_control("env2 decay", envdecay_spec)
  params:set_action("env2 decay", function(value) all_poles("envdecay", value) end)

  params:add_control("env2 sustain", envsustain_spec)
  params:set_action("env2 sustain", function(value) all_poles("envsustain", value) end)

  params:add_control("env2 release", envrelease_spec)
  params:set_action("env2 release", function(value) all_poles("envrelease", value) end)

  params:add_control("env2 > amp gain", ControlSpec.BIPOLAR)
  params:set_action("env2 > amp gain", function(value) all_poles("env_to_ampgain", value) end)

  params:add_control("env2 > lpf cutoff", ControlSpec.BIPOLAR)
  params:set_action("env2 > lpf cutoff", function(value) all_poles("env_to_lpfcutoff", value) end)

  params:add_control("env2 > lpf resonance", ControlSpec.BIPOLAR)
  params:set_action("env2 > lpf resonance", function(value) all_poles("env_to_lpfres", value) end)

  params:add_control("env2 > hpf cutoff", ControlSpec.BIPOLAR)
  params:set_action("env2 > hpf cutoff", function(value) all_poles("env_to_hpfcutoff", value) end)

  params:add_control("env2 > hpf resonance", ControlSpec.BIPOLAR)
  params:set_action("env2 > hpf resonance", function(value) all_poles("env_to_hpfres", value) end)
end

local function add_delay_params()
  params:add_control("delay send", ControlSpec.DB)
  params:set_action("delay send", function(value)
    for voicenum=1, POLYPHONY do
      engine.patch("pole"..voicenum, "ldelay", value)
      engine.patch("pole"..voicenum, "rdelay", value)
    end
  end)

  local delay_time_spec = ControlSpec.DELAY:copy()
  delay_time_spec.maxval = 3

  params:add_control("delay time left", delay_time_spec)
  params:set_action("delay time left", function(value)
    engine.param("ldelay", "delaytime", value)
  end)
  params:add_control("delay time right", delay_time_spec)
  params:set_action("delay time right", function(value)
    engine.param("rdelay", "delaytime", value)
  end)

  params:add_control("delay feedback", ControlSpec.DB)
  params:set_action("delay feedback", function(value)
    engine.patch('ldelay', 'rdelay', value)
    engine.patch('rdelay', 'ldelay', value)
  end)

end

local function default_patch()
  params:set("osc2 > osc3 freq", 1)
  params:set("osc2 partial no", 2)
  params:set("osc3 gain", 1)
  params:set("osc3 index", 5)
  params:set("osc3 > out", 0.1)
  params:set("env1 > osc2 gain", 1)
  params:set("env2 > amp gain", 1)
  params:set("env2 attack", 5)
  params:set("env2 decay", 100)
  params:set("env2 sustain", 0)
  params:set("env2 release", 150)
  params:set("delay send", -200)
end

local timer
local seqtimer
local seqmidinote = 60
local seqnext = "on"
local bpm = 120
local note_on_offs_redraw = true

init = function()
  setup_r_config()
  add_fmthing_params()
  add_pole_params()
  add_delay_params()
  default_patch()

  timer = metro[1]
  timer.callback = function()
    -- print("banging..")
    params:bang()
    -- print("..banged")
  end
  timer:start(0.2, 1)

  voice = Voice.new(POLYPHONY)
  -- params:read("gong.pset")

  screen.line_width(1.0)

  seqtimer = metro[2]
  seqtimer.callback = function()
    if seqnext == "on" then
      -- print("on")
      note_on(seqmidinote, 100)
      seqnext = "off"
    else
      -- print("off")
      note_off(seqmidinote)
      seqnext = "on"
    end
  end
  seqtimer:start(60/bpm/4/2) -- trig quarter notes
end

redraw = function()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("num voices:"..POLYPHONY)
  screen.move(0, 32)
  screen.level(15)
  screen.text("tempo: "..bpm)
  screen.move(0, 40)
  screen.update()
end

enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
  elseif n == 2 then
    bpm = bpm + delta
    seqtimer.time = 60/bpm/4/2
    redraw()
  end
end

cleanup = function()
  -- params:write("gong.pset")
  timer.count = -1 -- TODO: reset to ensure timer set to default, should not be needed
  timer:stop()
  seqtimer:stop()
end
