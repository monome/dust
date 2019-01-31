-- RYMD
--
-- Delay
--

local R = require 'jah/r'
local Control = require 'params/control'
local ControlSpec = require 'controlspec'
local Scroll = require 'jah/scroll'
local Formatters = require 'jah/formatters'

local scroll = Scroll.new()

local DATA_DIR = "/home/we/dust/data"
local PSET = "jah/rymd.pset"

engine.name = 'R'

-- TODO: refactor to utility table somewhere
local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("Direct", "SGain")
  engine.new("FXSend", "SGain")
  engine.new("Delay1", "Delay")
  engine.new("Delay2", "Delay")
  engine.new("Filter1", "MMFilter")
  engine.new("Filter2", "MMFilter")
  engine.new("Feedback", "SGain")
  engine.new("SoundOut", "SoundOut")
end

local function connect_modules()
  engine.connect("LFO/Sine", "Delay1/DelayTimeModulation")
  engine.connect("LFO/Sine", "Delay2/DelayTimeModulation")
  engine.connect("SoundIn/Left", "Direct/Left")
  engine.connect("SoundIn/Right", "Direct/Right")
  engine.connect("Direct/Left", "SoundOut/Left")
  engine.connect("Direct/Right", "SoundOut/Right")

  engine.connect("SoundIn/Left", "FXSend/Left")
  engine.connect("SoundIn/Right", "FXSend/Right")
  engine.connect("FXSend/Left", "Delay1/In")
  engine.connect("FXSend/Right", "Delay2/In")
  engine.connect("Delay1/Out", "Filter1/In")
  engine.connect("Delay2/Out", "Filter2/In")
  engine.connect("Filter1/Lowpass", "Feedback/Left")
  engine.connect("Filter2/Lowpass", "Feedback/Right")
  engine.connect("Feedback/Left", "Delay2/In")
  engine.connect("Feedback/Right", "Delay1/In")
  engine.connect("Filter1/Lowpass", "SoundOut/Left")
  engine.connect("Filter2/Lowpass", "SoundOut/Right")
end

local function add_rcontrol(args)
  local control = Control.new(args.id or args.name, args.name, args.spec, args.formatter)
  scroll:push(control)
  params:add {
    param=control,
    action=args.action or function(value) engine.set(args.ref or args.name, value) end
  }
end

local function add_rcontrols()
  add_rcontrol {
    name="Direct",
    id="direct",
    ref="Direct.Gain",
    spec=R.specs.SGain.Gain
  }

  add_rcontrol {
    name="Delay Send",
    id="delay_send",
    ref="FXSend.Gain",
    spec=R.specs.SGain.Gain
  }

  add_rcontrol {
    name="Delay Time Left",
    id="delay_time_left",
    ref="Delay1.DelayTime",
    spec=R.specs.Delay.DelayTime
  }

  add_rcontrol {
    name="Delay Time Right",
    id="delay_time_right",
    ref="Delay2.DelayTime",
    spec=R.specs.Delay.DelayTime
  }

  local filter_spec = R.specs.MMFilter.Frequency:copy()
  filter_spec.maxval = 10000
  add_rcontrol {
    name="Damping",
    id="damping",
    spec=filter_spec,
    action=function(value)
      engine.set("Filter1.Frequency", value)
      engine.set("Filter2.Frequency", value)
    end
  }

  local feedback_spec = R.specs.SGain.Gain:copy()
  feedback_spec.maxval = 0
  add_rcontrol {
    name="Feedback",
    id="feedback",
    ref="Feedback.Gain",
    spec=feedback_spec
  }

  add_rcontrol {
    name="Mod Rate",
    id="mod_rate",
    ref="LFO.Frequency",
    spec=R.specs.MultiLFO.Frequency,
    formatter=Formatters.round(0.001)
  }

  add_rcontrol {
    name="Delay Time Mod Depth",
    id="delay_time_mod_depth",
    spec=ControlSpec.UNIPOLAR,
    formatter=Formatters.percentage,
    action=function(value)
      engine.set("Delay1.DelayTimeModulation", value)
      engine.set("Delay2.DelayTimeModulation", value)
    end
  }
end

local function set_default_script_params()
  params:set("delay_send", -10)
  params:set("delay_time_left", 400)
  params:set("delay_time_right", 300)
  params:set("damping", 4000)
  params:set("feedback", -10)
end

function init()
  create_modules()
  connect_modules()

  scroll:push("RYMD")
  scroll:push("")

  add_rcontrols()

  scroll:push("") -- TODO

  engine.set("Filter1.Resonance", 0.1)
  engine.set("Filter2.Resonance", 0.1)

  if file_exists(DATA_DIR.."/"..PSET) then
    params:read(PSET)
  else
    set_default_script_params()
  end

  params:bang()
end

function cleanup()
  params:write(PSET)
end

function redraw()
  screen.clear()
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
