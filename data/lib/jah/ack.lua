local ControlSpec = require 'controlspec'
local Formatters = require 'jah/formatters'
local Ack = {}

local send_spec = ControlSpec.DB:copy()
send_spec.default = -60

--[[
TODO: looping
local loop_start_spec = ControlSpec.UNIPOLAR
local end_spec = ControlSpec.new(0, 1, 'lin', 0, 1, "")
local loop_point_spec = ControlSpec.UNIPOLAR
]]
local speed_spec = ControlSpec.new(0.05, 5, 'lin', 0, 1, "")
-- local slew_spec = ControlSpec.new(0, 5, 'lin', 0, 0, "") -- TODO: enable slews
local volume_spec = ControlSpec.DB:copy()
volume_spec.default = -10
local volume_env_attack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
local volume_env_release_spec = ControlSpec.new(0, 3, 'lin', 0, 3, "secs")
local filter_env_attack_spec = ControlSpec.new(0, 1, 'lin', 0, 0.001, "secs")
local filter_env_release_spec = ControlSpec.new(0, 3, 'lin', 0, 0.25, "secs")
local filter_cutoff_spec = ControlSpec.FREQ:copy()
filter_cutoff_spec.default = 20000
local filter_res_spec = ControlSpec.UNIPOLAR
local filter_mode_spec = ControlSpec.new(0, 1, 'lin', 1, 0)
local filter_env_mod_spec = ControlSpec.UNIPOLAR

local delay_time_spec = ControlSpec.new(0.0001, 5, 'exp', 0, 0.1, "secs")
local delay_feedback_spec = ControlSpec.new(0, 1.25, 'lin', 0, 0.5, "")
local reverb_room_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")
local reverb_damp_spec = ControlSpec.new(0, 1, 'lin', 0, 0.5, "")

Ack.SEND_SPEC = send_spec
Ack.FILTER_CUTOFF_SPEC = filter_cutoff_spec
Ack.FILTER_RES_SPEC = filter_res_spec

function Ack.add_params()
  for i=1,8 do
    params:add_file(i..": sample")
    params:set_action(i..": sample", function(value)
      if value ~= "-" then
        engine.loadSample(i-1, value)
      end
    end)
  --[[
  TODO: looping
    params:add_control(i..": start", start_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": start", function(value) engine.start(i-1, value) end)
    params:add_control(i..": end", end_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": end", function(value) engine.end(i-1, value) end)
    params:add_control(i..": loop point", loop_point_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": loop point", function(value) engine.loopPoint(i-1, value) end)
    params:add_option(i..": loop", {"off", "on"})
    params:set_action(i..": loop", function(value) engine.loop(i-1, value) end)
  ]]
    params:add_control(i..": speed", speed_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": speed", function(value) engine.speed(i-1, value) end)
    params:add_control(i..": vol", volume_spec, Formatters.std)
    params:set_action(i..": vol", function(value) engine.volume(i-1, value) end)
    params:add_control(i..": vol env atk", volume_env_attack_spec, Formatters.secs_as_ms)
    params:set_action(i..": vol env atk", function(value) engine.volumeEnvAttack(i-1, value) end)
    params:add_control(i..": vol env rel", volume_env_release_spec, Formatters.secs_as_ms)
    params:set_action(i..": vol env rel", function(value) engine.volumeEnvRelease(i-1, value) end)
    params:add_control(i..": pan", ControlSpec.PAN, Formatters.bipolar_as_pan_widget)
    params:set_action(i..": pan", function(value) engine.pan(i-1, value) end)
    params:add_control(i..": filter cutoff", filter_cutoff_spec, Formatters.round(0.001))
    params:set_action(i..": filter cutoff", function(value) engine.filterCutoff(i-1, value) end)
    params:add_control(i..": filter res", filter_res_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": filter res", function(value) engine.filterRes(i-1, value) end)
    --[[
    params:add_control(i..": filter mode", filter_mode_spec, Formatters.std)
    params:set_action(function(value) engine.filterMode(i-1, value) end)
    ]]
    params:add_control(i..": filter env atk", filter_env_attack_spec, Formatters.secs_as_ms)
    params:set_action(i..": filter env atk", function(value) engine.filterEnvAttack(i-1, value) end)
    params:add_control(i..": filter env rel", filter_env_release_spec, Formatters.secs_as_ms)
    params:set_action(i..": filter env rel", function(value) engine.filterEnvRelease(i-1, value) end)
    params:add_control(i..": filter env mod", filter_env_mod_spec, Formatters.unipolar_as_percentage)
    params:set_action(i..": filter env mod", function(value) engine.filterEnvMod(i-1, value) end)
    params:add_control(i..": delay send", send_spec, Formatters.std)
    params:set_action(i..": delay send", function(value) engine.delaySend(i-1, value) end)
    params:add_control(i..": reverb send", send_spec, Formatters.std)
    params:set_action(i..": reverb send", function(value) engine.reverbSend(i-1, value) end)
    --[[
    TODO: enable slews
    params:add_control(i..": speed slew", slew_spec, Formatters.std)
    params:set_action(i..": speed slew", function(value) engine.speedSlew(i-1, value) end)
    params:add_control(i..": vol slew", slew_spec, Formatters.std)
    params:set_action(i..": vol slew", function(value) engine.volumeSlew(i-1, value) end)
    params:add_control(i..": pan slew", slew_spec, Formatters.std)
    params:set_action(i..": pan slew", function(value) engine.panSlew(i-1, value) end)
    params:add_control(i..": filter cutoff slew", slew_spec, Formatters.std)
    params:set_action(i..": filter cutoff slew", function(value) engine.filterCutoffSlew(i-1, value) end)
    params:add_control(i..": filter res slew", slew_spec, Formatters.std)
    params:set_action(i..": filter res slew", function(value) engine.filterResSlew(i-1, value) end)
    ]]
  end

  params:add_control("delay time", delay_time_spec, Formatters.secs_as_ms)
  params:set_action("delay time", engine.delayTime)
  params:add_control("delay feedback", delay_feedback_spec, Formatters.unipolar_as_percentage)
  params:set_action("delay feedback", engine.delayFeedback)
  params:add_control("reverb room", reverb_room_spec, Formatters.unipolar_as_percentage)
  params:set_action("reverb room", engine.reverbRoom)
  params:add_control("reverb damp", reverb_damp_spec, Formatters.unipolar_as_percentage)
  params:set_action("reverb damp", engine.reverbRoom)
end

return Ack
