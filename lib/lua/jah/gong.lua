local ControlSpec = require 'controlspec'
local Formatters = require 'jah/formatters'
local Gong = {}

local specs = {}

specs.timbre = ControlSpec.new(0, 5, 'lin', nil, 1, "")
specs.timemod = ControlSpec.new(0, 5, 'lin', nil, 1, "")

specs.oscgain = ControlSpec.AMP
specs.oscfixed = ControlSpec.new(0, 1, 'lin', 1, 0, "")
specs.oscfixedfreq = ControlSpec.WIDE_FREQ
specs.oscpartial = ControlSpec.new(0.5, 12, 'lin', 0.5, 1, "")
specs.oscindex = ControlSpec.new(0, 24, 'lin', 0, 3, "")
specs.oscoutlevel = ControlSpec.AMP
specs.osc_to_oscfreq = ControlSpec.AMP
specs.lfo_to_oscfreq = ControlSpec.BIPOLAR
specs.env_to_oscfreq = ControlSpec.BIPOLAR

specs.lpfcutoff = ControlSpec.new(20, 10000, 'exp', 0, 10000, "Hz")
specs.lpfres = ControlSpec.UNIPOLAR
specs.hpfcutoff = ControlSpec.new(1, 10000, 'exp', 0, 1, "Hz")
specs.hpfres = ControlSpec.UNIPOLAR
specs.ampgain = ControlSpec.AMP
specs.lforate = ControlSpec.RATE
specs.lfo_to_lpfcutoff = ControlSpec.BIPOLAR
specs.lfo_to_lpfres = ControlSpec.AMP
specs.lfo_to_hpfcutoff = ControlSpec.AMP
specs.lfo_to_hpfres = ControlSpec.AMP
specs.lfo_to_ampgain = ControlSpec.BIPOLAR
specs.gate = ControlSpec.UNIPOLAR
specs.envattack = ControlSpec.new(0, 5000, 'lin', 0, 5, "ms")
specs.envdecay = ControlSpec.new(0, 5000, 'lin', 0, 30, "ms")
specs.envsustain = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
specs.envrelease = ControlSpec.new(0, 5000, 'lin', 0, 250, "ms")
specs.env_to_lpfcutoff = ControlSpec.BIPOLAR
specs.env_to_lpfres = ControlSpec.BIPOLAR
specs.env_to_hpfcutoff = ControlSpec.BIPOLAR
specs.env_to_hpfres = ControlSpec.BIPOLAR
specs.env_to_ampgain = ControlSpec.BIPOLAR

Gong.specs = specs

function Gong.add_reverb_send_param(channel)
  params:add_control(channel..": reverb send", GonGong.specs.send, Formatters.default)
  params:set_action(channel..": reverb send", function(value) engine.reverbSend(channel-1, value) end)
end

local function bind(paramname, id)
  params:add_control(paramname, specs[id])
  params:set_action(paramname, engine[id])
end

function Gong.add_params()
  local numoscs = 3

  for oscnum=1,numoscs do
    params:add_control("osc"..oscnum.." gain", specs.oscgain)
    -- params:set_action("osc"..oscnum.." gain", function(value) engine["osc"..oscnum.."gain"](value) end)
    params:set_action("osc"..oscnum.." gain", engine["osc"..oscnum.."gain"])

    params:add_option("osc"..oscnum.." type", {"partial", "fixed"})
    params:set_action("osc"..oscnum.." type", function(value)
      if value == 1 then
        engine["oscfixed"](0)
      else
        engine["oscfixed"](1)
      end
    end)

    params:add_control("osc"..oscnum.." partial no", specs.oscpartial)
    params:set_action("osc"..oscnum.." partial no", engine["osc"..oscnum.."partial"])

    params:add_control("osc"..oscnum.." fixed freq", specs.oscfixedfreq)
    params:set_action("osc"..oscnum.." fixed freq", engine["osc"..oscnum.."fixedfreq"])

    params:add_control("osc"..oscnum.." index", specs.oscindex)
    params:set_action("osc"..oscnum.." index", engine["osc"..oscnum.."index"])

    params:add_control("osc"..oscnum.." > out", specs.oscoutlevel)
    params:set_action("osc"..oscnum.." > out", engine["osc"..oscnum.."outlevel"])

    for src=1,numoscs do
      params:add_control("osc"..src.." > osc"..oscnum.." freq", specs.osc_to_oscfreq)
      params:set_action(
        "osc"..src.." > osc"..oscnum.." freq",
        engine["osc"..src.."_to_osc"..oscnum.."freq"]
      )
    end
  end

  -- params:add_control("env attack", specs.envattack)
  -- params:set_action("env attack", engine["envattack"])
  bind("env attack", "envattack")

  -- params:add_control("env decay", specs.envdecay)
  -- params:set_action("env decay", engine["envdecay"])
  bind("env decay", "envdecay")

  -- params:add_control("env sustain", specs.envsustain)
  -- params:set_action("env sustain", engine["envsustain"])
  bind("env sustain", "envsustain")

  bind("env release", "envrelease")

  for oscnum=1,numoscs do
    params:add_control("env > osc"..oscnum.." freq", specs.env_to_oscfreq)
    params:set_action("env > osc"..oscnum.." freq", engine["env_to_osc"..oscnum.."freq"])
    params:add_control("env > osc"..oscnum.." gain", specs.env_to_oscgain)
    params:set_action("env > osc"..oscnum.." gain", engine["env_to_osc"..oscnum.."freq"])
  end

  bind("lpf cutoff", "lpfcutoff")
  bind("lpf resonance", "lpfres")
  bind("hpf cutoff", "hpfcutoff")
  bind("hpf resonance", "hpfres")
  bind("amp gain", "ampgain")
  bind("lfo rate", "lforate")

  bind("lfo > lpf cutoff", "lfo_to_lpfcutoff")
  bind("lfo > lpf resonance", "lfo_to_lpfres")
  bind("lfo > hpf cutoff", "lfo_to_hpfcutoff")
  bind("lfo > hpf resonance", "lfo_to_hpfres")
  bind("lfo > amp gain", "lfo_to_ampgain")
  bind("env > amp gain", "env_to_ampgain")
  bind("env > lpf cutoff", "env_to_lpfcutoff")
  bind("env > lpf resonance", "env_to_lpfres")
  bind("env > hpf cutoff", "env_to_hpfcutoff")
  bind("env > hpf resonance", "env_to_hpfres")
end

return Gong
