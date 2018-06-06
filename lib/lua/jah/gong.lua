local ControlSpec = require 'controlspec'
local Formatters = require 'jah/formatters'
local Gong = {}

Gong.specs = {}

Gong.specs.send = ControlSpec.DB:copy()
Gong.specs.send.default = -60

Gong.specs.sample_start = ControlSpec.UNIPOLAR
Gong.specs.sample_end = ControlSpec.new(0, 1, 'lin', 0, 1, "")
Gong.specs.loop_point = ControlSpec.UNIPOLAR

Gong.specs.speed = ControlSpec.new(0.05, 5, 'lin', 0, 1, "")
-- Gong.specs.slew = ControlSpec.new(0, 5, 'lin', 0, 0, "") -- TODO: slews

Gong.specs.volume = ControlSpec.DB:copy()
Gong.specs.volume.default = -10

Gong.specs.volume_env_attack = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
Gong.specs.volume_env_release = ControlSpec.new(0, 3, 'lin', 0, 3, "secs")
Gong.specs.filter_env_attack = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
Gong.specs_filter_env_release = ControlSpec.new(0, 3, 'lin', 0, 0.25, "secs")

Gong.specs.filter_cutoff = ControlSpec.FREQ:copy()
Gong.specs.filter_cutoff.default = 20000

Gong.specs.filter_res = ControlSpec.UNIPOLAR
Gong.specs.filter_env_mod = ControlSpec.BIPOLAR

Gong.specs.delay_time = ControlSpec.new(0.0001, 5, 'exp', 0, 0.1, "secs")
Gong.specs.delay_feedback = ControlSpec.new(0, 1.25, 'lin', 0, 0.5, "")
Gong.specs.delay_level = ControlSpec.DB:copy()
Gong.specs.delay_level.default = -10

Gong.specs.reverb_room = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
Gong.specs.reverb_damp = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
Gong.specs.reverb_level = ControlSpec.DB:copy()
Gong.specs.reverb_level.default = -10

function Gong.add_channel_sample_param(channel)
  params:add_file(channel..": sample")
  params:set_action(channel..": sample", function(value)
    if value ~= "-" then
      engine.loadSample(channel-1, value)
    end
  end)
end

function Gong.add_start_pos_param(channel)
  params:add_control(channel..": start pos", Gong.specs.sample_start, Formatters.unipolar_as_percentage)
  params:set_action(channel..": start pos", function(value) engine.sampleStart(channel-1, value) end)
end

function Gong.add_end_pos_param(channel)
  params:add_control(channel..": end pos", GonGong.specs.sample_end, Formatters.unipolar_as_percentage)
  params:set_action(channel..": end pos", function(value) engine.sampleEnd(channel-1, value) end)
end

function Gong.add_loop_param(channel)
  params:add_option(channel..": loop", {"off", "on"})
  params:set_action(channel..": loop", function(value)
    if value == 2 then
      engine.enableLoop(channel-1)
    else
      engine.disableLoop(channel-1)
    end
  end)
end

function Gong.add_loop_point_param(channel)
  params:add_control(channel..": loop point", Gong.specs.loop_point, Formatters.unipolar_as_percentage)
  params:set_action(channel..": loop point", function(value) engine.loopPoint(channel-1, value) end)
end

function Gong.add_speed_param(channel)
  params:add_control(channel..": speed", Gong.specs.speed, Formatters.unipolar_as_percentage)
  params:set_action(channel..": speed", function(value) engine.speed(channel-1, value) end)
end

function Gong.add_vol_param(channel)
  params:add_control(channel..": vol", GonGong.specs.volume, Formatters.default)
  params:set_action(channel..": vol", function(value) engine.volume(channel-1, value) end)
end

function Gong.add_vol_env_atk_param(channel)
  params:add_control(channel..": vol env atk", Gong.specs.volume_env_attack, Formatters.secs_as_ms)
  params:set_action(channel..": vol env atk", function(value) engine.volumeEnvAttack(channel-1, value) end)
end

function Gong.add_vol_env_rel_param(channel)
  params:add_control(channel..": vol env rel", Gong.specs.volume_env_release, Formatters.secs_as_ms)
  params:set_action(channel..": vol env rel", function(value) engine.volumeEnvRelease(channel-1, value) end)
end

function Gong.add_pan_param(channel)
  params:add_control(channel..": pan", ControlSpec.PAN, Formatters.bipolar_as_pan_widget)
  params:set_action(channel..": pan", function(value) engine.pan(channel-1, value) end)
end

function Gong.add_filter_cutoff_param(channel)
  params:add_control(channel..": filter cutoff", Gong.specs.filter_cutoff, Formatters.round(0.001))
  params:set_action(channel..": filter cutoff", function(value) engine.filterCutoff(channel-1, value) end)
end

function Gong.add_filter_res_param(channel)
  params:add_control(channel..": filter res", Gong.specs.filter_res, Formatters.unipolar_as_percentage)
  params:set_action(channel..": filter res", function(value) engine.filterRes(channel-1, value) end)
end

function Gong.add_filter_mode_param(channel)
  params:add_option(channel..": filter mode", {"lowpass", "bandpass", "highpass", "notch", "peak"})
  params:set_action(channel..": filter mode", function(value) engine.filterMode(channel-1, value-1) end)
end

function Gong.add_filter_env_atk_param(channel)
  params:add_control(channel..": filter env atk", Gong.specs.filter_env_attack, Formatters.secs_as_ms)
  params:set_action(channel..": filter env atk", function(value) engine.filterEnvAttack(channel-1, value) end)
end

function Gong.add_filter_env_rel_param(channel)
  params:add_control(channel..": filter env rel", Gong.specs_filter_env_release, Formatters.secs_as_ms)
  params:set_action(channel..": filter env rel", function(value) engine.filterEnvRelease(channel-1, value) end)
end

function Gong.add_filter_env_mod_param(channel)
  params:add_control(channel..": filter env mod", Gong.specs.filter_env_mod, Formatters.bipolar_as_percentage)
  params:set_action(channel..": filter env mod", function(value) engine.filterEnvMod(channel-1, value) end)
end

function Gong.add_delay_send_param(channel)
  params:add_control(channel..": delay send", Gong.specs.send, Formatters.default)
  params:set_action(channel..": delay send", function(value) engine.delaySend(channel-1, value) end)
end

function Gong.add_reverb_send_param(channel)
  params:add_control(channel..": reverb send", GonGong.specs.send, Formatters.default)
  params:set_action(channel..": reverb send", function(value) engine.reverbSend(channel-1, value) end)
end

function Gong.add_channel_params(channel)
  Gong.add_channel_sample_param(channel)
  Gong.add_start_pos_param(channel)
  Gong.add_end_pos_param(channel)
  Gong.add_loop_param(channel)
  Gong.add_loop_point_param(channel)
  Gong.add_speed_param(channel)
  Gong.add_vol_param(channel)
  Gong.add_vol_env_atk_param(channel)
  Gong.add_vol_env_rel_param(channel)
  Gong.add_pan_param(channel)
  Gong.add_filter_mode_param(channel)
  Gong.add_filter_cutoff_param(channel)
  Gong.add_filter_res_param(channel)
  Gong.add_filter_env_atk_param(channel)
  Gong.add_filter_env_rel_param(channel)
  Gong.add_filter_env_mod_param(channel)
  Gong.add_delay_send_param(channel)
  Gong.add_reverb_send_param(channel)

  -- TODO: refactor each param into a separate function
  --[[
  TODO: slews
  params:add_control(channel..": speed slew", slew_spec, Formatters.default)
  params:set_action(channel..": speed slew", function(value) engine.speedSlew(channel-1, value) end)
  params:add_control(channel..": vol slew", slew_spec, Formatters.default)
  params:set_action(channel..": vol slew", function(value) engine.volumeSlew(channel-1, value) end)
  params:add_control(channel..": pan slew", slew_spec, Formatters.default)
  params:set_action(channel..": pan slew", function(value) engine.panSlew(channel-1, value) end)
  params:add_control(channel..": filter cutoff slew", slew_spec, Formatters.default)
  params:set_action(channel..": filter cutoff slew", function(value) engine.filterCutoffSlew(channel-1, value) end)
  params:add_control(channel..": filter res slew", slew_spec, Formatters.default)
  params:set_action(channel..": filter res slew", function(value) engine.filterResSlew(channel-1, value) end)
  ]]
end

function Gong.add_params()
  local numoscs = 3
  local partial_spec = ControlSpec.new(0.5, 10, 'lin', 0.25, 1)
  local index_spec = ControlSpec.new(0, 24, 'lin', 0, 3, "")

  for oscnum=1,numoscs do
    params:add_control("osc"..oscnum.." gain", ControlSpec.AMP)
    params:set_action("osc"..oscnum.." gain", function(value) all_fm("osc"..oscnum.."gain", value) end)

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

    params:add_control("osc"..src.." > osc"..oscnum.." freq", ControlSpec.UNIPOLAR)
    params:set_action("osc"..src.." > osc"..oscnum.." freq", function(value)
      engine."osc"..oscnum.."_to_osc"..dest.."freq", value
    end)
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

return Gong
