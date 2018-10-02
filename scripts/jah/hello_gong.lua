-- hello gong.
-- 6 voice polyphonic fm synth
-- controlled by midi or grid
--
-- enc2: timbre macro control
-- enc3: time macro control
-- key2: trig random note
--
-- midi notes/grid: play notes
--
-- synth parameters in
-- menu > parameters
--

local ControlSpec = require 'controlspec'
local Voice = require 'exp/voice'
local Gong = require 'jah/gong'
local midi = require 'midi'
local grid = require 'grid'
local Metro = require 'metro'

engine.name = 'Gong'

local midi_device = midi.connect(1)
local midi_device_is_connected = false

local grid_device = grid.connect(1)
local grid_device_is_connected = false

local indicate_midi_event
local indicate_gridkey_event

local midi_cc_spec = ControlSpec.new(0, 127, 'lin', 1, 0, '')
local POLYPHONY = 6
local note_downs = {}

local function update_voice_indicators()
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

local function update_device_indicators()
  screen.move(0,60)
  screen.font_size(8)
  if midi_device_is_connected then
    if indicate_midi_event then
      screen.level(8)
    else
      screen.level(15)
    end
    screen.text("midi")
  end
  screen.level(15)
  if midi_device_is_connected and grid_device_is_connected then
    screen.text("+")
  end
  if grid_device_is_connected then
    if indicate_gridkey_event then
      screen.level(8)
    else
      screen.level(15)
    end
    screen.text("grid")
  end
  if midi_device_is_connected == false and grid_device_is_connected == false then
    screen.level(3)
    screen.text("no midi / grid")
  end
end

local function trig_voice(voicenum, note)
  engine.noteOn(voicenum-1, note)
end

local function release_voice(voicenum)
  engine.off(voicenum-1)
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

local function cc_set_control(name, controlspec, value)
  params:set(name, controlspec:map(midi_cc_spec:unmap(value)))
end

local function cc_delta_control(name, controlspec, value)
  local delta
  if value > 0 and value < 64 then
    delta = value
  else
    delta = value - 128
  end
  local value = params:get(name)
  local value_unmapped = controlspec:unmap(value)
  local new_unmapped_value = value_unmapped + delta/100
  params:set(name, controlspec:map(new_unmapped_value))
end

local function cc(ctl, value)
  local param_name
  local spec
  if ctl == params:get("filter cutoff cc") then
    param_name = "filter cutoff"
    spec = Gong.specs.filtercutoff
    abs = params:get("filter cutoff cc type") == 1
  elseif ctl == params:get("filter resonance cc") then
    param_name = "filter resonance"
    spec = Gong.specs.filterres
    abs = params:get("filter resonance cc type") == 1
  elseif ctl == params:get("timbre cc") then
    param_name = "timbre"
    spec = Gong.specs.timbre
    abs = params:get("timbre cc type") == 1
  elseif ctl == params:get("timemod cc") then
    param_name = "timemod"
    spec = Gong.specs.timemod
    abs = params:get("timemod cc type") == 1
  end
  if param_name then
    if abs then
      cc_set_control(param_name, spec, value)
    else
      cc_delta_control(param_name, spec, value)
    end
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
  params:set("osc1_to_osc3freq", 1)
  params:set("osc1partial", 2)
  params:set("osc3gain", 1)
  params:set("osc3index", 5)
  params:set("osc3outlevel", 0.1)
  params:set("env_to_osc1gain", 0.5)
  params:set("env_to_ampgain", 1)
  --[[
  params:set("delay send", -20)
  params:set("delay time left", 0.03)
  params:set("delay time right", 0.05)
  params:set("delay feedback", -30)
  ]]
end

local function gridkey_event(x, y, s)
  indicate_gridkey_event = true
  local note = x * 8 + y
  if s == 1 then
    note_on(note, 5)
    grid_device.led(x, y, 15)
  else
    note_off(note)
    grid_device.led(x, y, 0)
  end
  grid_device.refresh()
end

grid_device.event = gridkey_event

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

function midi.add(dev)
  if not midi_device_is_connected then
    dev.remove = function()
      midi_device_is_connected = false
    end
    midi_device_is_connected = true
  end
end

function grid.add(dev)
  if not grid_device_is_connected then
    dev.remove = function()
      grid_device_is_connected = false
    end
    grid_device_is_connected = true
  end
end

local function add_midi_cc_params()
  local midi_cc_note_list = {}
  for i=0,127 do
    midi_cc_note_list[i] = i
  end
  cc_type = {"abs", "rel"}
  params:add_option("filter_cutoff_cc", "filter cutoff cc", midi_cc_note_list, 1)
  params:add_option("filter_cutoff_cc_type", "filter cutoff cc type", cc_type)
  params:add_option("filter_resonance_cc", "filter resonance cc", midi_cc_note_list, 2)
  params:add_option("filter_resonance_cc_type", "filter resonance cc type", cc_type)
  params:add_option("timbre_cc", "timbre cc", midi_cc_note_list, 3)
  params:add_option("timbre_cc_type", "timbre cc type", cc_type)
  params:add_option("timemod_cc", "timemod cc", midi_cc_note_list, 4)
  params:add_option("timemod_cc_type", "timemod cc type", cc_type)
end

function init()
  add_midi_cc_params()
  params:add_separator()
  Gong.add_params()

  voice = Voice.new(POLYPHONY)

  params:read("jah/hello_gong.pset")

  refresh_screen_metro = Metro.alloc(
    function(stage)
      redraw()
      if indicate_midi_event then
        indicate_midi_event = false
      end
      if indicate_gridkey_event then
        indicate_gridkey_event = false
      end
    end,
    1 / 20
  )
  refresh_screen_metro:start()

  default_patch()
  screen.line_width(1.0)
end

function cleanup()
  params:write("jah/hello_gong.pset")
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("hello gong")
  update_voice_indicators()

  screen.level(15)
  screen.move(0, 32)
  screen.text("timbre: "..params:string("timbre"))
  screen.move(0, 40)
  screen.text("timemod: "..params:string("timemod"))

  update_device_indicators()
  screen.update()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    params:delta("timbre", delta)
    redraw()
  elseif n == 3 then
    params:delta("timemod", delta)
    redraw()
  end
end

local lastkeynote

function key(n, z)
  if n == 2 and z == 1 then
    lastkeynote = math.random(60) + 20
    note_on(lastkeynote, 100)
  elseif n == 2 and z == 0 then
    note_off(lastkeynote)
  end
end

