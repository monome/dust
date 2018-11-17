-- MOLN
--
-- 4 voice polyphonic
-- subtractive synthesizer
--

local ControlSpec = require 'controlspec'
local Control = require 'params/control'
local Option = require 'params/option'
local Formatters = require 'jah/formatters'
local Scroll = require 'jah/scroll'
local R = require 'jah/r'
local Voice = require 'exp/voice'

local rengine = R.engine
local rutil = R.util
local rspecs = R.specs

local PSET = "jah/moln.pset"

local scroll = Scroll.new { screen_rows=5 }

local midi_device = midi.connect(1)

local POLYPHONY = 4
local note_downs = {}

engine.name = 'R'

-- TODO: refactor to utility table somewhere - util?
local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- utility function set one or more module parameters given a voice
local function voice_bulkset(bundle, voicenum)
  local arg = ""

  for i=1, #bundle, 2 do
    local moduleref, paramref = rutil.split_ref(bundle[i])
    local value = bundle[i+1]

    arg = arg .. moduleref .. voicenum .. "." .. paramref .. " " .. value

    if i ~= #bundle-1 then
      arg = arg .. " "
    end
  end

  engine.bulkset(arg)
end

-- utility function to add a control to both params and scroll
local function add_control(args)
  local control = Control.new(
    args.id,
    args.name,
    args.spec,
    args.formatter
  )
  control.action = args.action

  scroll:push(control)

  params:add { param = control }
end

-- utility function to add a control utilizing a macro having name == args.id to both params and scroll
local function add_macro_control(args)
  add_control {
    id=args.id,
    name=args.name,
    spec=args.spec,
    formatter=args.formatter,
    action=function (value)
      engine.macroset(args.id, value)
    end
  }
end

local function trig_voice(voicenum, note)
  local function to_hz(note)
    local exp = (note - 21) / 12
    return 27.5 * 2^exp
  end

  voice_bulkset(
    {
      "FreqGate.Gate", 1,
      "FreqGate.Frequency", to_hz(note)
    },
    voicenum
  )
end

local function release_voice(voicenum)
  voice_bulkset(
    { "FreqGate.Gate", 0 },
    voicenum
  )
end

local note_slots = {}

local function note_on(note, velocity)
  if not note_slots[note] then
    local slot = voice:get()
    local voicenum = slot.id
    trig_voice(voicenum, note)
    slot.on_release = function()
      release_voice(voicenum)
      note_slots[note] = nil
    end
    note_slots[note] = slot
    note_downs[voicenum] = true
    redraw()
  end
end

local function note_off(note)
  slot = note_slots[note]
  if slot then
    voice:release(slot)
    note_downs[slot.id] = false
    redraw()
  end
end

local function cc(ctl, value)
end

local function midi_event(data)
  indicate_midi_event = true
  local status = data[1]
  local data1 = data[2]
  local data2 = data[3]
  if status == 144 then
    --[[
    if data1 == 0 then
      return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
    end
    ]]
    if data2 ~= 0 then
      note_on(data1, data2)
    else
      note_off(data1)
    end
    redraw()
  elseif status == 128 then
    --[[
    if data1 == 0 then
      return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
    end
    ]]
    note_off(data1)
  elseif status == 176 then
    cc(data1, data2)
    redraw()
  end
end

midi_device.event = midi_event

local function create_modules()
  rengine.poly_new("FreqGate", "FreqGate", POLYPHONY)
  rengine.poly_new("LFO", "SineLFO", POLYPHONY)
  rengine.poly_new("Env", "ADSREnv", POLYPHONY)
  rengine.poly_new("OscA", "PulseOsc", POLYPHONY)
  rengine.poly_new("OscB", "PulseOsc", POLYPHONY)
  rengine.poly_new("Filter", "LPFilter", POLYPHONY)
  rengine.poly_new("Amp", "Amp", POLYPHONY)

  engine.new("SoundOut", "SoundOut")
end

local function connect_modules()
  rengine.poly_connect("FreqGate/Frequency", "OscA/FM", POLYPHONY)
  rengine.poly_connect("FreqGate/Frequency", "OscB/FM", POLYPHONY)
  rengine.poly_connect("FreqGate/Gate", "Env/Gate", POLYPHONY)
  rengine.poly_connect("LFO/Out", "OscA/PWM", POLYPHONY)
  rengine.poly_connect("LFO/Out", "OscB/PWM", POLYPHONY)
  rengine.poly_connect("Env/Out", "Amp/Lin", POLYPHONY)
  rengine.poly_connect("Env/Out", "Filter/FM", POLYPHONY)
  rengine.poly_connect("OscA/Out", "Filter/In", POLYPHONY)
  rengine.poly_connect("OscB/Out", "Filter/In", POLYPHONY)
  rengine.poly_connect("Filter/Out", "Amp/In", POLYPHONY)

  for voicenum=1, POLYPHONY do
    engine.connect("Amp"..voicenum.."/Out", "SoundOut/Left")
    engine.connect("Amp"..voicenum.."/Out", "SoundOut/Right")
  end
end

-- without macros engine commands get delayed when there is extensive modulation of parameters
local function create_macros()
  local function create_poly_macro(name, moduleparam)
    engine.newmacro(name, rutil.poly_expand(moduleparam, POLYPHONY))
  end

  create_poly_macro("osc_a_range", "OscA.Range")
  create_poly_macro("osc_a_pulsewidth", "OscA.PulseWidth")
  create_poly_macro("osc_b_range", "OscB.Range")
  create_poly_macro("osc_b_pulsewidth", "OscB.PulseWidth")
  create_poly_macro("osc_a_detune", "OscA.Tune")
  create_poly_macro("osc_b_detune", "OscB.Tune")
  create_poly_macro("lfo_frequency", "LFO.Frequency")
  create_poly_macro("osc_a_pwm", "OscA.PWM")
  create_poly_macro("osc_b_pwm", "OscB.PWM")
  create_poly_macro("filter_frequency", "Filter.Frequency")
  create_poly_macro("filter_resonance", "Filter.Resonance")
  create_poly_macro("env_to_filter_fm", "Filter.FM")
  create_poly_macro("env_attack", "Env.Attack")
  create_poly_macro("env_decay", "Env.Decay")
  create_poly_macro("env_sustain", "Env.Sustain")
  create_poly_macro("env_release", "Env.Release")
end

local function init_static_module_params()
  rengine.poly_set("Filter.AudioLevel", 1, POLYPHONY)
  rengine.poly_set("OscA.FM", 1, POLYPHONY)
  rengine.poly_set("OscB.FM", 1, POLYPHONY)
end

local function add_controls()
  add_macro_control {
    id="osc_a_range",
    name="Osc A Range",
    spec=rspecs.PulseOsc.Range,
    formatter=Formatters.round(1)
  }

  add_macro_control {
    id="osc_a_pulsewidth",
    name="Osc A PulseWidth",
    spec=rspecs.PulseOsc.PulseWidth,
    formatter=Formatters.percentage
  }

  add_macro_control {
    id="osc_b_range",
    name="Osc B Range",
    spec=rspecs.PulseOsc.Range,
    formatter=Formatters.round(1)
  }

  add_macro_control {
    id="osc_b_pulsewidth",
    name="Osc B PulseWidth",
    spec=rspecs.PulseOsc.PulseWidth,
    formatter=Formatters.percentage
  }

  add_control {
    id="osc_detune",
    name="Detune",
    spec=ControlSpec.UNIPOLAR,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_a_detune", -value*10)
      engine.macroset("osc_b_detune", value*10)
    end
  }

  add_macro_control {
    id="lfo_frequency",
    name="PWM Rate",
    spec=rspecs.MultiLFO.Frequency,
    formatter=Formatters.round(0.001)
  }

  add_control {
    id="lfo_to_osc_pwm",
    name="PWM Depth",
    spec=ControlSpec.UNIPOLAR,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_a_pwm", value*0.76)
      engine.macroset("osc_b_pwm", value*0.56)
    end
  }

  local filter_spec = rspecs.MMFilter.Frequency:copy()
  filter_spec.maxval = 10000
  add_macro_control {
    id="filter_frequency",
    name="Filter Frequency",
    spec=filter_spec
  }

  add_macro_control {
    id="filter_resonance",
    name="Filter Resonance",
    spec=rspecs.MMFilter.Resonance,
    formatter=Formatters.percentage
  }

  add_macro_control {
    id="env_to_filter_fm",
    name="Env > Filter Frequency",
    spec=rspecs.MMFilter.FM,
    formatter=Formatters.percentage
  }

  add_macro_control {
    id="env_attack",
    name="Env Attack",
    ref="Env.Attack",
    spec=rspecs.ADSREnv.Attack
  }

  add_macro_control {
    id="env_decay",
    name="Env Decay",
    ref="Env.Decay",
    spec=rspecs.ADSREnv.Decay
  }

  add_macro_control {
    id="env_sustain",
    name="Env Sustain",
    ref="Env.Sustain",
    spec=rspecs.ADSREnv.Sustain,
    formatter=Formatters.percentage
  }

  add_macro_control {
    id="env_release",
    name="Env Release",
    ref="Env.Release",
    spec=rspecs.ADSREnv.Release
  }
end

local function set_default_script_params()
  params:set("osc_a_range", 0)
  params:set("osc_a_pulsewidth", 0.88)
  params:set("osc_b_range", 0)
  params:set("osc_b_pulsewidth", 0.61)
  params:set("osc_detune", 0.36)
  params:set("lfo_frequency", 0.125)
  params:set("lfo_to_osc_pwm", 0.46)
  params:set("filter_frequency", 500)
  params:set("filter_resonance", 0.2)
  params:set("env_to_filter_fm", 0.35)
  params:set("env_attack", 1)
  params:set("env_decay", 200)
  params:set("env_sustain", 0.5)
  params:set("env_release", 500)
end

local function add_debug_option()
  scroll:push("Debugging SC (temporary)")
  scroll:push("")

  local trace_option = Option.new("sc_trace", "SC Trace", {"Disabled", "Enabled"})
  trace_option.action = function (value)
    if value == 1 then
      engine.trace(0)
    else
      engine.trace(1)
    end
  end
  scroll:push(trace_option)
  params:add { param = trace_option }
end

function init()
  create_modules()
  connect_modules()
  create_macros()
  init_static_module_params()

  scroll:push("MOLN")
  scroll:push("")

  add_controls()

  scroll:push("")

  add_debug_option()

  scroll:push("") -- TODO: scroll bug

  if file_exists(data_dir.."/"..PSET) then
    params:read(PSET)
  else
    set_default_script_params()
  end

  params:bang()

  voice = Voice.new(POLYPHONY)
end

function cleanup()
  params:write(PSET)
end

local function update_voice_indicators()
  screen.move(110, 62)
  screen.font_size(8)
  for voicenum=1, POLYPHONY do
    if note_downs[voicenum] then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.text(voicenum)
  end
end

function redraw()
  screen.clear()
  update_voice_indicators()
  scroll:draw(screen)
  screen.update()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    scroll:navigate(util.clamp(delta, -1, 1)) -- TODO: hack
    redraw()
  elseif n == 3 then
    if scroll.selected_param then
      scroll.selected_param:delta(delta)
      redraw()
    end
  end
end

function key(n, z)
  if n == 3 then
    if z == 1 then
      lastkeynote = math.random(60) + 20
      note_on(lastkeynote, 100)
    else
      note_off(lastkeynote)
    end
  end
end
