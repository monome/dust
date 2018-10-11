-- 1OSC
--
-- Dynamic re-patching example
--

local ControlSpec = require 'controlspec'
local Control = require 'params/control'
local Option = require 'params/option'
local Trigger = require 'params/trigger'
local Formatters = require 'jah/formatters'
local ParamSet = require 'paramset'
local Scroll = require 'jah/scroll'
local R = require 'jah/r'
local scroll = Scroll.new()

engine.name = 'R'

local function add_rcontrol(args)
  local control = Control.new(args.id, args.name, args.spec, args.formatter)
  scroll:push(control)
  params:add {
    param=control,
    action=args.action or function(value) engine.set(args.ref or args.name, value) end
  }
end

function init()
  engine.new("Base", "FreqGate")
  engine.new("LFO", "MultiLFO")
  engine.new("Osc", "MultiOsc")
  engine.new("Filter", "MMFilter")
  engine.new("SoundOut", "SoundOut")

  engine.connect("Base/Frequency", "Osc/FM")
  engine.set("Osc.FM", 1)

  scroll:push("Oscillator thru filter: pulse")
  scroll:push("width and filter cutoff is ")
  scroll:push("modulated by an LFO.")
  scroll:push("")

  local current_lfo_wave
  local lfo_wave_option = Option.new(
    "lfo_wave",
    "LFO/Wave",
    {"InvSaw", "Saw", "Sine", "Triangle", "Pulse"}
  )
  scroll:push(lfo_wave_option)
  params:add {
    param=lfo_wave_option,
    action=function(value)
      if current_lfo_wave then
        engine.disconnect("LFO/"..current_lfo_wave, "Osc/PWM")
        engine.disconnect("LFO/"..current_lfo_wave, "Filter/FM")
      end
      if not current_lfo_wave then
        current_lfo_wave = "InvSaw" -- default
      end
      current_lfo_wave = lfo_wave_option.options[value]
      engine.connect("LFO/"..current_lfo_wave, "Osc/PWM")
      engine.connect("LFO/"..current_lfo_wave, "Filter/FM")
    end
  }

  add_rcontrol {
    id="lfo_frequency",
    name="LFO Frequency",
    ref="LFO.Frequency",
    spec=R.specs.MultiLFO.Frequency,
    formatter=Formatters.round(0.001)
  }

  local reset_trigger = Trigger.new("lfo_reset", "LFO Reset")
  reset_trigger.action = function()
    engine.set("LFO.Reset", 1)
    engine.set("LFO.Reset", 0)
  end
  scroll:push(reset_trigger)
  params:add {
    param = reset_trigger
  }
    
  local current_osc_wave
  local osc_wave_option = Option.new(
    "osc_wave",
    "Osc/Wave",
    {"Sine", "Triangle", "Saw", "Pulse"},
    4
  )
  scroll:push(osc_wave_option)
  params:add {
    param=osc_wave_option,
    action=function(value)
      if current_osc_wave then
        engine.disconnect("Osc/"..current_osc_wave, "Filter/In")
      end
      if not current_osc_wave then
        current_osc_wave = "Pulse" -- default
      end
      current_osc_wave = osc_wave_option.options[value]
      engine.connect("Osc/"..current_osc_wave, "Filter/In")
    end
  }

  add_rcontrol {
    id="base_freq",
    name="Osc Frequency",
    ref="Base.Frequency",
    spec=R.specs.FreqGate.Frequency,
    formatter=Formatters.round(0.001)
  }

  add_rcontrol {
    id="osc_pulsewidth",
    name="Osc PulseWidth",
    ref="Osc.PulseWidth",
    spec=R.specs.MultiOsc.PulseWidth,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="lfo_to_osc_pwm",
    name="LFO > Osc PWM",
    ref="Osc.PWM",
    spec=R.specs.MultiOsc.PWM,
    formatter=Formatters.percentage
  }

  local current_filter_type
  local filter_type_option = Option.new(
    "filter_tyoe",
    "Filter/Type",
    {"Lowpass", "Highpass", "Bandpass", "Notch"}
  )
  scroll:push(filter_type_option)
  params:add {
    param=filter_type_option,
    action=function(value)
      if current_filter_type then
        engine.disconnect("Filter/"..current_filter_type, "SoundOut/Left")
        engine.disconnect("Filter/"..current_filter_type, "SoundOut/Right")
      end
      if not current_filter_type then
        current_filter_type = "Lowpass" -- default
      end
      current_filter_type = filter_type_option.options[value]
      engine.connect("Filter/"..current_filter_type, "SoundOut/Left")
      engine.connect("Filter/"..current_filter_type, "SoundOut/Right")
    end
  }

  add_rcontrol {
    id="filter_frequency",
    name="Filter Frequency",
    ref="Filter.Frequency",
    spec=R.specs.MMFilter.Frequency
  }

  add_rcontrol {
    id="filter_resonance",
    name="Filter Resonance",
    ref="Filter.Resonance",
    spec=R.specs.MMFilter.Resonance,
    formatter=Formatters.percentage
  }

  add_rcontrol {
    id="lfo_to_filter_fm",
    name="LFO > Filter FM",
    ref="Filter.FM",
    spec=R.specs.MMFilter.FM,
    formatter=Formatters.percentage
  }

  scroll:push("") -- TODO

  params:set("lfo_frequency", 0.2)
  params:set("lfo_to_osc_pwm", 0.2)
  params:set("filter_frequency", 2000)
  params:set("filter_resonance", 0.4)
  params:set("lfo_to_filter_fm", 0.1)

  params:bang()
end

function redraw()
  screen.clear()
  scroll:draw(screen)
  screen.update()
end

function key(n, s)
  if n == 3 and s == 1 then
    if scroll.selected_param then
      local param = scroll.selected_param
      if param.t == ParamSet.tTRIGGER then
        param:bang()
      else
        param:set_default()
        redraw()
      end
    end
  end
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
