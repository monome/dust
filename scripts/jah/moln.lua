-- MOLN
--
-- 4 voice polyphonic
-- subtractive synthesizer
--

local ControlSpec = require 'controlspec'
local Control = require 'params/control'
local Formatters = require 'jah/formatters'
local Scroll = require 'jah/scroll'
local R = require 'jah/r'
local Voice = require 'exp/voice'

-- local Metro = require 'metro' -- TODO: tmp - lag issue

local DATA_DIR = "/home/we/dust/data"
local PSET = "jah/moln.pset"

local scroll = Scroll.new { screen_rows=5 }

local midi_device = midi.connect(1)

local POLYPHONY = 4
local note_downs = {}

engine.name = 'R'

-- TODO: refactor to utility table somewhere
local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local function split_ref(ref)
  local words = {}
  for word in ref:gmatch("[a-zA-Z0-9]+") do table.insert(words, word) end
  return words[1], words[2]
end

local function poly_new(name, kind)
  for voicenum=1, POLYPHONY do
    engine.new(name..voicenum, kind)
  end
end

local function poly_connect(output, input)
  local sourcemodule, outputref = split_ref(output)
  local destmodule, inputref = split_ref(input)
  for voicenum=1, POLYPHONY do
    engine.connect(sourcemodule..voicenum.."/"..outputref, destmodule..voicenum.."/"..inputref)
  end
end

local function voice_set(bundle, voicenum)
  local arg = ""

  for i=1, #bundle, 2 do
    local moduleref, paramref = split_ref(bundle[i])
    local value = bundle[i+1]

    arg = arg .. moduleref .. voicenum .. "." .. paramref .. " " .. value

    if i ~= #bundle-1 then
      arg = arg .. " "
    end
  end

  engine.bulkset(arg)
end

local function poly_set(bundle)
  local arg = ""

  for i=1, #bundle, 2 do
    local moduleref, paramref = split_ref(bundle[i])
    local value = bundle[i+1]

    for voicenum=1, POLYPHONY do
      arg = arg .. moduleref .. voicenum .. "." .. paramref .. " " .. value
      if voicenum ~= POLYPHONY then
        arg = arg .. " "
      end
    end

    if i ~= #bundle-1 then
      arg = arg .. " "
    end
  end

  engine.bulkset(arg)
end

local function add_rcontrol(args)
  local spec = args.spec
  local formatter = args.formatter
  local action = args.action

  local control = Control.new(args.id, args.name, spec, formatter)

  scroll:push(control)

  params:add {
    param = control,
    action = action
  }
end

local function add_poly_rcontrol(args)
  add_rcontrol {
    id=args.id,
    name=args.name,
    ref=args.ref,
    spec=args.spec,
    formatter=args.formatter,
    action = function (value)
      poly_set { args.ref or args.name, value }
    end
  }
end

local function to_hz(note)
  local exp = (note - 21) / 12
  return 27.5 * 2^exp
end

local function trig_voice(voicenum, note)
  voice_set(
    {
      "FreqGate.Gate", 1,
      "FreqGate.Frequency", to_hz(note)
    },
    voicenum
  )
end

local function release_voice(voicenum)
  voice_set(
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
  poly_new("FreqGate", "FreqGate")
  poly_new("LFO", "MultiLFO2")
  poly_new("Env", "ADSREnv")
  poly_new("OscA", "SquareOsc")
  poly_new("OscB", "SquareOsc")
  poly_new("Filter", "LPFilter")
  poly_new("Amp", "Amp")

  engine.new("SoundOut", "SoundOut")
end

local function connect_modules()
  poly_connect("FreqGate/Frequency", "OscA/FM")
  poly_connect("FreqGate/Frequency", "OscB/FM")
  poly_connect("FreqGate/Gate", "Env/Gate")
  poly_connect("LFO/Sine", "OscA/PWM")
  poly_connect("LFO/Sine", "OscB/PWM")
  poly_connect("Env/Out", "Amp/Lin")
  poly_connect("Env/Out", "Filter/FM")
  poly_connect("OscA/Out", "Filter/In")
  poly_connect("OscB/Out", "Filter/In")
  poly_connect("Filter/Out", "Amp/In")

  for voicenum=1, POLYPHONY do
    engine.connect("Amp"..voicenum.."/Out", "SoundOut/Left")
    engine.connect("Amp"..voicenum.."/Out", "SoundOut/Right")
  end
end

local function init_static_module_params()
  poly_set {
    "Filter.AudioLevel", 1,
    "OscA.FM", 1,
    "OscB.FM", 1
  }
end

local function add_rcontrols()
  add_poly_rcontrol {
    id="osc_a_range",
    name="Osc A Range",
    ref="OscA.Range",
    spec=R.specs.SquareOsc.Range,
    formatter=Formatters.round(1)
  }

  add_poly_rcontrol {
    id="osc_a_pulsewidth",
    name="Osc A PulseWidth",
    ref="OscA.PulseWidth",
    spec=R.specs.SquareOsc.PulseWidth,
    formatter=Formatters.percentage
  }

  add_poly_rcontrol {
    id="osc_b_range",
    name="Osc B Range",
    ref="OscB.Range",
    spec=R.specs.SquareOsc.Range,
    formatter=Formatters.round(1)
  }

  add_poly_rcontrol {
    id="osc_b_pulsewidth",
    name="Osc B PulseWidth",
    ref="OscB.PulseWidth",
    spec=R.specs.SquareOsc.PulseWidth,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="osc_detune",
    name="Osc A-B Detune",
    spec=ControlSpec.UNIPOLAR,
    formatter=Formatters.percentage,
    action=function (value)
      poly_set {
        "OscA.Tune", -value*10,
        "OscB.Tune", value*10
      }
    end
  }

  add_poly_rcontrol {
    id="lfo_frequency",
    name="LFO Frequency",
    ref="LFO.Frequency",
    spec=R.specs.MultiLFO2.Frequency,
    formatter=Formatters.round(0.001)
  }

  add_rcontrol {
    id="lfo_to_osc_pwm",
    name="LFO > Osc A-B PWM",
    spec=ControlSpec.UNIPOLAR,
    formatter=Formatters.percentage,
    action=function (value)
      poly_set {
        "OscA.PWM", value*0.76,
        "OscB.PWM", value*0.56
      }
    end
  }

  local filter_spec = R.specs.MMFilter.Frequency:copy()
  filter_spec.maxval = 10000
  add_poly_rcontrol {
    id="filter_frequency",
    name="Filter Frequency",
    ref="Filter.Frequency",
    spec=filter_spec
  }

  add_poly_rcontrol {
    id="filter_resonance",
    name="Filter Resonance",
    ref="Filter.Resonance",
    spec=R.specs.MMFilter.Resonance,
    formatter=Formatters.percentage
  }

  add_poly_rcontrol {
    id="env_to_filter_fm",
    name="Env > Filter FM",
    ref="Filter.FM",
    spec=R.specs.MMFilter.FM,
    formatter=Formatters.percentage
  }

  add_poly_rcontrol {
    id="env_attack",
    name="Env Attack",
    ref="Env.Attack",
    spec=R.specs.ADSREnv.Attack
  }

  add_poly_rcontrol {
    id="env_decay",
    name="Env Decay",
    ref="Env.Decay",
    spec=R.specs.ADSREnv.Decay
  }

  add_poly_rcontrol {
    id="env_sustain",
    name="Env Sustain",
    ref="Env.Sustain",
    spec=R.specs.ADSREnv.Sustain
  }

  add_poly_rcontrol {
    id="env_release",
    name="Env Release",
    ref="Env.Release",
    spec=R.specs.ADSREnv.Release
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

-- TODO: temporary, lag issue
--[[
local odd = false
local function tick()
  odd = not odd
  if odd then
    key(3, 1)
  else
    key(3, 0)
  end
end
]]

function init()
  create_modules()
  connect_modules()
  init_static_module_params()

  params:add {
    type = "option",
    id = "sc_trace",
    name = "SC Trace",
    options = {"Disabled", "Enabled"},
    action = function (value)
      if value == 1 then
        engine.trace(0)
      else
        engine.trace(1)
      end
    end
  }

  params:add_separator()

  -- TODO: temporary, lag issue
  --[[
  timer = Metro.alloc()
  timer.callback = tick

  params:add_option("TestSeq / Run", {"no", "yes"})
  params:set_action("TestSeq / Run", function (value)
    if value == 1 then
      timer:stop()
    else
      timer:start()
    end
  end)

  params:add_option("TestSeq / Run", {"no", "yes"})
  params:add_number("TestSeq / BPM", 1, 300, 60)
  params:set_action("TestSeq / BPM", function (value)
    timer.time = 60/value/2
  end)
  ]]

  scroll:push("MOLN")
  scroll:push("")

  add_rcontrols()

  scroll:push("") -- TODO: scroll bug

  if file_exists(DATA_DIR.."/"..PSET) then
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
      local param = scroll.selected_param
      param:delta(delta)
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
