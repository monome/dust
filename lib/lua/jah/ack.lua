local ControlSpec = require 'controlspec'
local Formatters = require 'jah/formatters'
local Ack = {}

Ack.specs = {}

Ack.specs.send = ControlSpec.DB:copy()
Ack.specs.send.default = -60

Ack.specs.sample_start = ControlSpec.UNIPOLAR
Ack.specs.sample_end = ControlSpec.new(0, 1, 'lin', 0, 1, "")
Ack.specs.loop_point = ControlSpec.UNIPOLAR

Ack.specs.speed = ControlSpec.new(0.05, 5, 'lin', 0, 1, "")
-- Ack.specs.slew = ControlSpec.new(0, 5, 'lin', 0, 0, "") -- TODO: slews

Ack.specs.volume = ControlSpec.DB:copy()
Ack.specs.volume.default = -10

Ack.specs.volume_env_attack = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
Ack.specs.volume_env_release = ControlSpec.new(0, 3, 'lin', 0, 3, "secs")
Ack.specs.filter_env_attack = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
Ack.specs_filter_env_release = ControlSpec.new(0, 3, 'lin', 0, 0.25, "secs")

Ack.specs.filter_cutoff = ControlSpec.FREQ:copy()
Ack.specs.filter_cutoff.default = 20000

Ack.specs.filter_res = ControlSpec.UNIPOLAR
Ack.specs.filter_env_mod = ControlSpec.UNIPOLAR

Ack.specs.delay_time = ControlSpec.new(0.0001, 5, 'exp', 0, 0.1, "secs")
Ack.specs.delay_feedback = ControlSpec.new(0, 1.25, 'lin', 0, 0.5, "")
Ack.specs.delay_level = ControlSpec.DB:copy()
Ack.specs.delay_level.default = -10

Ack.specs.reverb_room = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
Ack.specs.reverb_damp = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
Ack.specs.reverb_level = ControlSpec.DB:copy()
Ack.specs.reverb_level.default = -10

function Ack.add_params()
  for i=1,8 do
    params:add_file(i..": sample")
    params:set_action(i..": sample", function(value)
      if value ~= "-" then
        engine.loadSample(i-1, value)
      end
    end)
	--[[
    params:add_option(i..": loop", {"off", "on"})
    params:set_action(i..": loop", function(value)
      if value == 2 then
        engine.enableLoop(i-1)
      else
        engine.disableLoop(i-1)
      end
    end)
    params:add_control(i..": start pos", Ack.specs.sample_start, Formatters.unipolar_as_percentage)
    params:set_action(i..": start pos", function(value) engine.sampleStart(i-1, value) end)
    params:add_control(i..": end pos", Ack.specs.sample_end, Formatters.unipolar_as_percentage)
    params:set_action(i..": end pos", function(value) engine.sampleEnd(i-1, value) end)
    params:add_control(i..": loop point", Ack.specs.loop_point, Formatters.unipolar_as_percentage)
    params:set_action(i..": loop point", function(value) engine.loopPoint(i-1, value) end)
	]]
    params:add_control(i..": speed", Ack.specs.speed, Formatters.unipolar_as_percentage)
    params:set_action(i..": speed", function(value) engine.speed(i-1, value) end)
    params:add_control(i..": vol", Ack.specs.volume, Formatters.default)
    params:set_action(i..": vol", function(value) engine.volume(i-1, value) end)
    params:add_control(i..": vol env atk", Ack.specs.volume_env_attack, Formatters.secs_as_ms)
    params:set_action(i..": vol env atk", function(value) engine.volumeEnvAttack(i-1, value) end)
    params:add_control(i..": vol env rel", Ack.specs.volume_env_release, Formatters.secs_as_ms)
    params:set_action(i..": vol env rel", function(value) engine.volumeEnvRelease(i-1, value) end)
    params:add_control(i..": pan", ControlSpec.PAN, Formatters.bipolar_as_pan_widget)
    params:set_action(i..": pan", function(value) engine.pan(i-1, value) end)
    params:add_control(i..": filter cutoff", Ack.specs.filter_cutoff, Formatters.round(0.001))
    params:set_action(i..": filter cutoff", function(value) engine.filterCutoff(i-1, value) end)
    params:add_control(i..": filter res", Ack.specs.filter_res, Formatters.unipolar_as_percentage)
    params:set_action(i..": filter res", function(value) engine.filterRes(i-1, value) end)
    params:add_option(i..": filter mode", {"lowpass", "bandpass", "highpass", "notch", "peak"})
    params:set_action(i..": filter mode", function(value) engine.filterMode(i-1, value-1) end)
    params:add_control(i..": filter env atk", Ack.specs.filter_env_attack, Formatters.secs_as_ms)
    params:set_action(i..": filter env atk", function(value) engine.filterEnvAttack(i-1, value) end)
    params:add_control(i..": filter env rel", Ack.specs_filter_env_release, Formatters.secs_as_ms)
    params:set_action(i..": filter env rel", function(value) engine.filterEnvRelease(i-1, value) end)
    params:add_control(i..": filter env mod", Ack.specs.filter_env_mod, Formatters.unipolar_as_percentage)
    params:set_action(i..": filter env mod", function(value) engine.filterEnvMod(i-1, value) end)
    params:add_control(i..": delay send", Ack.specs.send, Formatters.default)
    params:set_action(i..": delay send", function(value) engine.delaySend(i-1, value) end)
    params:add_control(i..": reverb send", Ack.specs.send, Formatters.default)
    params:set_action(i..": reverb send", function(value) engine.reverbSend(i-1, value) end)
    --[[
    TODO: slews
    params:add_control(i..": speed slew", slew_spec, Formatters.default)
    params:set_action(i..": speed slew", function(value) engine.speedSlew(i-1, value) end)
    params:add_control(i..": vol slew", slew_spec, Formatters.default)
    params:set_action(i..": vol slew", function(value) engine.volumeSlew(i-1, value) end)
    params:add_control(i..": pan slew", slew_spec, Formatters.default)
    params:set_action(i..": pan slew", function(value) engine.panSlew(i-1, value) end)
    params:add_control(i..": filter cutoff slew", slew_spec, Formatters.default)
    params:set_action(i..": filter cutoff slew", function(value) engine.filterCutoffSlew(i-1, value) end)
    params:add_control(i..": filter res slew", slew_spec, Formatters.default)
    params:set_action(i..": filter res slew", function(value) engine.filterResSlew(i-1, value) end)
    ]]
  end

  params:add_control("delay time", Ack.specs.delay_time, Formatters.secs_as_ms)
  params:set_action("delay time", engine.delayTime)
  params:add_control("delay feedback", Ack.specs.delay_feedback, Formatters.unipolar_as_percentage)
  params:set_action("delay feedback", engine.delayFeedback)
  params:add_control("delay level", Ack.specs.delay_level, Formatters.default)
  params:set_action("delay level", engine.delayLevel)
  params:add_control("reverb room", Ack.specs.reverb_room, Formatters.unipolar_as_percentage)
  params:set_action("reverb room", engine.reverbRoom)
  params:add_control("reverb damp", Ack.specs.reverb_damp, Formatters.unipolar_as_percentage)
  params:set_action("reverb damp", engine.reverbRoom)
  params:add_control("reverb level", Ack.specs.reverb_level, Formatters.default)
  params:set_action("reverb level", engine.reverbLevel)
end

return Ack
