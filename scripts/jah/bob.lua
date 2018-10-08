-- BOB
--
-- Moog lowpass filter
--

engine.name = 'R'

local R = require 'jah/r'
local Control = require 'params/control'
local Scroll = require 'jah/scroll'
local Formatters = require 'jah/formatters'
local scroll = Scroll.new()

local DATA_DIR = "/home/we/dust/data"
local PSET = "jah/bob.pset"

-- TODO: refactor to utility table somewhere
local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("FilterL", "LPLadder")
  engine.new("FilterR", "LPLadder")
  engine.new("SoundOut", "SoundOut")
end

local function connect_modules()
  engine.connect("LFO/Sine", "FilterL/FM")
  engine.connect("LFO/Sine", "FilterR/FM")

  engine.connect("SoundIn/Left", "FilterL/In")
  engine.connect("SoundIn/Right", "FilterR/In")
  engine.connect("FilterL/Out", "SoundOut/Left")
  engine.connect("FilterR/Out", "SoundOut/Right")
end

local function add_rcontrol(args)
  local control = Control.new(args.id, args.name, args.spec, args.formatter)
  scroll:push(control)
  params:add {
    param=control,
    action=args.action or function(value) engine.set(args.ref or args.name, value) end
  }
end

local function add_rcontrols()
  local filter_spec = R.specs.LPLadder.Frequency:copy()
  filter_spec.maxval = 10000
  add_rcontrol {
    id="cutoff",
    name="Cutoff",
    spec=filter_spec,
    action=function (value)
      engine.set("FilterL.Frequency", value)
      engine.set("FilterR.Frequency", value)
    end
  }

  add_rcontrol {
    id="resonance",
    name="Resonance",
    spec=R.specs.LPLadder.Resonance,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("FilterL.Resonance", value)
      engine.set("FilterR.Resonance", value)
    end
  }

  add_rcontrol {
    id="lfo_rate",
    name="LFO Rate",
    ref="LFO.Frequency",
    formatter=Formatters.round(0.001),
    spec=R.specs.MultiLFO.Frequency
  }

  add_rcontrol {
    id="lfo_to_cutoff",
    name="LFO > Cutoff",
    formatter=Formatters.percentage,
    spec=R.specs.LPLadder.FM,
    action=function (value)
      engine.set("FilterL.FM", value)
      engine.set("FilterR.FM", value)
    end
  }
end

local function set_default_script_params()
  params:set("cutoff", 1000)
  params:set("resonance", 0.5)
  params:set("lfo_rate", 0.5)
  params:set("lfo_to_cutoff", 0.1)
end

function init()
  create_modules()
  connect_modules()

  scroll:push("BOB")
  scroll:push("")

  add_rcontrols()

  scroll:push("") -- TODO

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
