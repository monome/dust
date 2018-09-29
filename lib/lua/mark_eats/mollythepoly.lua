--- Molly the Poly lib
-- Engine params and functions.
--
-- @module MollyThePoly
-- @release v1.0.0
-- @author Mark Eats

local ControlSpec = require "controlspec"
local MEFormatters = require "mark_eats/formatters"

local MollyThePoly = {}

local specs = {}
local options = {}

options.OSC_WAVE_SHAPE = {"Triangle", "Saw", "Pulse"}
specs.PW_MOD = ControlSpec.new(0, 1, "lin", 0, 0.2, "")
options.PW_MOD_SRC = {"LFO", "Env 1", "Manual"}

specs.FREQ_MOD_LFO = ControlSpec.UNIPOLAR
specs.FREQ_MOD_ENV = ControlSpec.BIPOLAR
specs.GLIDE = ControlSpec.new(0, 5, "lin", 0, 0, "s")

specs.MAIN_OSC_LEVEL = ControlSpec.new(0, 1, "lin", 0, 1, "")
specs.SUB_OSC_LEVEL = ControlSpec.UNIPOLAR
specs.SUB_OSC_DETUNE = ControlSpec.new(-5, 5, "lin", 0, 0, "ST")
specs.NOISE_LEVEL = ControlSpec.new(0, 1, "lin", 0, 0.1, "")

specs.HP_FILTER_CUTOFF = ControlSpec.new(10, 20000, "exp", 0, 10, "Hz")
specs.LP_FILTER_CUTOFF = ControlSpec.new(20, 20000, "exp", 0, 300, "Hz")
specs.LP_FILTER_RESONANCE = ControlSpec.new(0, 1, "lin", 0, 0.1, "")
options.LP_FILTER_TYPE = {"-12 dB/oct", "-24 dB/oct"}
options.LP_FILTER_ENV = {"Env-1", "Env-2"}
specs.LP_FILTER_CUTOFF_MOD_ENV = ControlSpec.new(-1, 1, "lin", 0, 0.25, "")
specs.LP_FILTER_CUTOFF_MOD_LFO = ControlSpec.UNIPOLAR
specs.LP_FILTER_TRACKING = ControlSpec.new(0, 2, "lin", 0, 1, ":1")

specs.LFO_FREQ = ControlSpec.new(0.05, 20, "exp", 0, 5, "Hz")
options.LFO_WAVE_SHAPE = {"Sine", "Triangle", "Saw", "Square", "Random"}
specs.LFO_FADE = ControlSpec.new(-15, 15, "lin", 0, 0, "s")

specs.ENV_ATTACK = ControlSpec.new(0.002, 5, "lin", 0, 0.01, "s")
specs.ENV_DECAY = ControlSpec.new(0.002, 10, "lin", 0, 0.3, "s")
specs.ENV_SUSTAIN = ControlSpec.new(0, 1, "lin", 0, 0.5, "")
specs.ENV_RELEASE = ControlSpec.new(0.002, 10, "lin", 0, 0.5, "s")

specs.AMP = ControlSpec.new(0, 11, "lin", 0, 0.5, "")
specs.AMP_MOD = ControlSpec.UNIPOLAR

specs.RING_MOD_FREQ = ControlSpec.new(10, 300, "exp", 0, 50, "Hz")
specs.RING_MOD_FADE = ControlSpec.new(-15, 15, "lin", 0, 0, "s")
specs.RING_MOD_MIX = ControlSpec.UNIPOLAR

specs.CHORUS_MIX = ControlSpec.new(0, 1, "lin", 0, 0.8, "")

MollyThePoly.specs = specs


local function format_ratio_to_one(param)
  return util.round(param:get(), 0.01) .. ":1"
end

local function format_fade(param)
  local secs = util.round(param:get(), 0.01)
  local suffix = " in"
  if secs < 0 then
    secs = secs - specs.LFO_FADE.minval
    suffix = " out"
  end
  return math.abs(secs) .. " s" .. suffix
end

function MollyThePoly.add_params()
  
  params:add_option("Osc Wave Shape", options.OSC_WAVE_SHAPE, 3)
  params:set_action("Osc Wave Shape", function(value) engine.oscWaveShape(value - 1) end)
  
  params:add_control("Pulse Width Mod", specs.PW_MOD)
  params:set_action("Pulse Width Mod", engine.pwMod)
  
  params:add_option("Pulse Width Mod Src", options.PW_MOD_SRC)
  params:set_action("Pulse Width Mod Src", function(value) engine.pwModSource(value - 1) end)
  
  params:add_control("Frequency Mod (LFO)", specs.FREQ_MOD_LFO)
  params:set_action("Frequency Mod (LFO)", engine.freqModLfo)
  
  params:add_control("Frequency Mod (Env-1)", specs.FREQ_MOD_ENV)
  params:set_action("Frequency Mod (Env-1)", engine.freqModEnv)
  
  params:add_control("Glide", specs.GLIDE, MEFormatters.format_secs)
  params:set_action("Glide", engine.glide)
  
  params:add_separator()
  
  params:add_control("Main Osc Level", specs.MAIN_OSC_LEVEL)
  params:set_action("Main Osc Level", engine.mainOscLevel)
  
  params:add_control("Sub Osc Level", specs.SUB_OSC_LEVEL)
  params:set_action("Sub Osc Level", engine.subOscLevel)
  
  params:add_control("Sub Osc Detune", specs.SUB_OSC_DETUNE)
  params:set_action("Sub Osc Detune", engine.subOscDetune)
  
  params:add_control("Noise Level", specs.NOISE_LEVEL)
  params:set_action("Noise Level", engine.noiseLevel)
  
  params:add_separator()
  
  params:add_control("HP Filter Cutoff", specs.HP_FILTER_CUTOFF, MEFormatters.format_freq)
  params:set_action("HP Filter Cutoff", engine.hpFilterCutoff)
  
  params:add_control("LP Filter Cutoff", specs.LP_FILTER_CUTOFF, MEFormatters.format_freq)
  params:set_action("LP Filter Cutoff", engine.lpFilterCutoff)
  
  params:add_control("LP Filter Resonance", specs.LP_FILTER_RESONANCE)
  params:set_action("LP Filter Resonance", engine.lpFilterResonance)
  
  params:add_option("LP Filter Type", options.LP_FILTER_TYPE, 2)
  params:set_action("LP Filter Type", function(value) engine.lpFilterType(value - 1) end)
  
  params:add_option("LP Filter Env", options.LP_FILTER_ENV)
  params:set_action("LP Filter Env", function(value) engine.lpFilterCutoffEnvSelect(value - 1) end)
  
  params:add_control("LP Filter Mod (Env)", specs.LP_FILTER_CUTOFF_MOD_ENV)
  params:set_action("LP Filter Mod (Env)", engine.lpFilterCutoffModEnv)
  
  params:add_control("LP Filter Mod (LFO)", specs.LP_FILTER_CUTOFF_MOD_LFO)
  params:set_action("LP Filter Mod (LFO)", engine.lpFilterCutoffModLfo)
  
  params:add_control("LP Filter Tracking", specs.LP_FILTER_TRACKING, format_ratio_to_one)
  params:set_action("LP Filter Tracking", engine.lpFilterTracking)
  
  params:add_separator()
  
  params:add_control("LFO Frequency", specs.LFO_FREQ, MEFormatters.format_freq)
  params:set_action("LFO Frequency", engine.lfoFreq)
  
  params:add_option("LFO Wave Shape", options.LFO_WAVE_SHAPE)
  params:set_action("LFO Wave Shape", function(value) engine.lfoWaveShape(value - 1) end)
  
  params:add_control("LFO Fade", specs.LFO_FADE, format_fade)
  params:set_action("LFO Fade", function(value)
    if value < 0 then
      value = specs.LFO_FADE.minval - 0.00001 + math.abs(value)
    end
    engine.lfoFade(value)
  end)
  
  params:add_separator()
  
  params:add_control("Env-1 Attack", specs.ENV_ATTACK, MEFormatters.format_secs)
  params:set_action("Env-1 Attack", engine.env1Attack)
  
  params:add_control("Env-1 Decay", specs.ENV_DECAY, MEFormatters.format_secs)
  params:set_action("Env-1 Decay", engine.env1Decay)
  
  params:add_control("Env-1 Sustain", specs.ENV_SUSTAIN)
  params:set_action("Env-1 Sustain", engine.env1Sustain)
  
  params:add_control("Env-1 Release", specs.ENV_RELEASE, MEFormatters.format_secs)
  params:set_action("Env-1 Release", engine.env1Release)
  
  params:add_separator()
  
  params:add_control("Env-2 Attack", specs.ENV_ATTACK, MEFormatters.format_secs)
  params:set_action("Env-2 Attack", engine.env2Attack)
  
  params:add_control("Env-2 Decay", specs.ENV_DECAY, MEFormatters.format_secs)
  params:set_action("Env-2 Decay", engine.env2Decay)
  
  params:add_control("Env-2 Sustain", specs.ENV_SUSTAIN)
  params:set_action("Env-2 Sustain", engine.env2Sustain)
  
  params:add_control("Env-2 Release", specs.ENV_RELEASE, MEFormatters.format_secs)
  params:set_action("Env-2 Release", engine.env2Release)
  
  params:add_separator()
  
  params:add_control("Amp", specs.AMP)
  params:set_action("Amp", engine.amp)
  
  params:add_control("Amp Mod (LFO)", specs.AMP_MOD)
  params:set_action("Amp Mod (LFO)", engine.ampMod)
  
  params:add_separator()
  
  params:add_control("Ring Mod Frequency", specs.RING_MOD_FREQ, MEFormatters.format_freq)
  params:set_action("Ring Mod Frequency", engine.ringModFreq)
  
  params:add_control("Ring Mod Fade", specs.RING_MOD_FADE, format_fade)
  params:set_action("Ring Mod Fade", function(value)
    if value < 0 then
      value = specs.RING_MOD_FADE.minval - 0.00001 + math.abs(value)
    end
    engine.ringModFade(value)
  end)
  
  params:add_control("Ring Mod Mix", specs.RING_MOD_MIX)
  params:set_action("Ring Mod Mix", engine.ringModMix)
  
  params:add_control("Chorus Mix", specs.CHORUS_MIX)
  params:set_action("Chorus Mix", engine.chorusMix)
  
  params:add_separator()
  
  params:bang()
  
  params:add_trigger("Create Lead")
  params:set_action("Create Lead", function() MollyThePoly.randomize_params("lead") end)
  
  params:add_trigger("Create Pad")
  params:set_action("Create Pad", function() MollyThePoly.randomize_params("pad") end)
  
  params:add_trigger("Create Percussion")
  params:set_action("Create Percussion", function() MollyThePoly.randomize_params("percussion") end)
  
end

function MollyThePoly.randomize_params(sound_type)
  
  params:set("Osc Wave Shape", math.random(#options.OSC_WAVE_SHAPE))
  params:set("Pulse Width Mod", math.random())
  params:set("Pulse Width Mod Src", math.random(#options.PW_MOD_SRC))
  
  params:set("LP Filter Type", math.random(#options.LP_FILTER_TYPE))
  params:set("LP Filter Env", math.random(#options.LP_FILTER_ENV))
  params:set("LP Filter Tracking", util.linlin(0, 1, specs.LP_FILTER_TRACKING.minval, specs.LP_FILTER_TRACKING.maxval, math.random()))
  
  params:set("LFO Frequency", util.linlin(0, 1, specs.LFO_FREQ.minval, specs.LFO_FREQ.maxval, math.random()))
  params:set("LFO Wave Shape", math.random(#options.LFO_WAVE_SHAPE))
  params:set("LFO Fade", util.linlin(0, 1, specs.LFO_FADE.minval, specs.LFO_FADE.maxval, math.random()))
  
  params:set("Env-1 Decay", util.linlin(0, 1, specs.ENV_DECAY.minval, specs.ENV_DECAY.maxval, math.random()))
  params:set("Env-1 Sustain", math.random())
  params:set("Env-1 Release", util.linlin(0, 1, specs.ENV_RELEASE.minval, specs.ENV_RELEASE.maxval, math.random()))
  
  params:set("Ring Mod Frequency", util.linlin(0, 1, specs.RING_MOD_FREQ.minval, specs.RING_MOD_FREQ.maxval, math.random()))
  params:set("Chorus Mix", math.random())
  
  
  if sound_type == "lead" then
    
    params:set("Frequency Mod (LFO)", util.linexp(0, 1, 0.0000001, 0.1, math.pow(math.random(), 2)))
    if math.random() > 0.95 then
      params:set("Frequency Mod (Env-1)", util.linlin(0, 1, -0.06, 0.06, math.random()))
    else
      params:set("Frequency Mod (Env-1)", 0)
    end
    
    params:set("Glide", util.linexp(0, 1, 0.0000001, 1, math.pow(math.random(), 2)))
    
    if math.random() > 0.8 then
      params:set("Main Osc Level", 1)
      params:set("Sub Osc Level", 0)
    else
      params:set("Main Osc Level", math.random())
      params:set("Sub Osc Level", math.random())
    end
    if math.random() > 0.9 then
      params:set("Sub Osc Detune", util.linlin(0, 1, specs.SUB_OSC_DETUNE.minval, specs.SUB_OSC_DETUNE.maxval, math.random()))
    else
      local detune = {0, 0, 0, 4, 5, -4, -5}
      params:set("Sub Osc Detune", detune[math.random(1, #detune)] + math.random() * 0.01)
    end
    params:set("Noise Level", util.linexp(0, 1, 0.0000001, 1, math.random()))
    
    if math.abs(params:get("Sub Osc Detune")) > 0.7 and params:get("Sub Osc Level") > params:get("Main Osc Level")  and params:get("Sub Osc Level") > params:get("Noise Level") then
      params:set("Main Osc Level", params:get("Sub Osc Level") + 0.2)
    end
    
    params:set("LP Filter Cutoff", util.linexp(0, 1, 100, specs.LP_FILTER_CUTOFF.maxval, math.pow(math.random(), 2)))
    params:set("LP Filter Resonance", math.random() * 0.9)
    params:set("LP Filter Mod (Env)", util.linlin(0, 1, math.random(-1, 0), 1, math.random()))
    params:set("LP Filter Mod (LFO)", math.random() * 0.2)
    
    params:set("Env-2 Attack", util.linexp(0, 1, specs.ENV_ATTACK.minval, 0.5, math.random()))
    params:set("Env-2 Decay", util.linlin(0, 1, specs.ENV_DECAY.minval, specs.ENV_DECAY.maxval, math.random()))
    params:set("Env-2 Sustain", math.random())
    params:set("Env-2 Release", util.linlin(0, 1, specs.ENV_RELEASE.minval, 3, math.random()))
    
    if(math.random() > 0.8) then
      params:set("Env-1 Attack", params:get("Env-2 Attack"))
    else
      params:set("Env-1 Attack", util.linlin(0, 1, specs.ENV_ATTACK.minval, 1, math.random()))
    end
    
    if params:get("Env-2 Decay") < 0.2 and params:get("Env-2 Sustain") < 0.15 then
      params:set("Env-2 Decay", util.linlin(0, 1, 0.2, specs.ENV_DECAY.maxval, math.random()))
    end
    
    local amp_max = 0.9
    if math.random() > 0.8 then amp_max = 11 end
    params:set("Amp", util.linlin(0, 1, 0.75, amp_max, math.random()))
    params:set("Amp Mod (LFO)", util.linlin(0, 1, 0, 0.5, math.random()))
    
    params:set("Ring Mod Fade", util.linlin(0, 1, specs.RING_MOD_FADE.minval * 0.8, specs.RING_MOD_FADE.maxval * 0.3, math.random()))
    if(math.random() > 0.8) then
      params:set("Ring Mod Mix", math.pow(math.random(), 2))
    else
      params:set("Ring Mod Mix", 0)
    end
    
    
  elseif sound_type == "pad" then
    
    params:set("Frequency Mod (LFO)", util.linexp(0, 1, 0.0000001, 0.2, math.pow(math.random(), 4)))
    if math.random() > 0.8 then
      params:set("Frequency Mod (Env-1)", util.linlin(0, 1, -0.1, 0.2, math.pow(math.random(), 4)))
    else
      params:set("Frequency Mod (Env-1)", 0)
    end
    
    params:set("Glide", util.linexp(0, 1, 0.0000001, specs.GLIDE.maxval, math.pow(math.random(), 2)))
    
    params:set("Main Osc Level", math.random())
    params:set("Sub Osc Level", math.random())
    if math.random() > 0.7 then
      params:set("Sub Osc Detune", util.linlin(0, 1, specs.SUB_OSC_DETUNE.minval, specs.SUB_OSC_DETUNE.maxval, math.random()))
    else
      params:set("Sub Osc Detune", math.random(specs.SUB_OSC_DETUNE.minval, specs.SUB_OSC_DETUNE.maxval) + math.random() * 0.01)
    end
    params:set("Noise Level", util.linexp(0, 1, 0.0000001, 1, math.random()))
    
    if math.abs(params:get("Sub Osc Detune")) > 0.7 and params:get("Sub Osc Level") > params:get("Main Osc Level")  and params:get("Sub Osc Level") > params:get("Noise Level") then
      params:set("Main Osc Level", params:get("Sub Osc Level") + 0.2)
    end
    
    params:set("LP Filter Cutoff", util.linexp(0, 1, 100, specs.LP_FILTER_CUTOFF.maxval, math.random()))
    params:set("LP Filter Resonance", math.random())
    params:set("LP Filter Mod (Env)", util.linlin(0, 1, -1, 1, math.random()))
    params:set("LP Filter Mod (LFO)", math.random())
    
    params:set("Env-1 Attack", util.linlin(0, 1, specs.ENV_ATTACK.minval, specs.ENV_ATTACK.maxval, math.random()))
    
    params:set("Env-2 Attack", util.linlin(0, 1, specs.ENV_ATTACK.minval, specs.ENV_ATTACK.maxval, math.random()))
    params:set("Env-2 Decay", util.linlin(0, 1, specs.ENV_DECAY.minval, specs.ENV_DECAY.maxval, math.random()))
    params:set("Env-2 Sustain", 0.1 + math.random() * 0.9)
    params:set("Env-2 Release", util.linlin(0, 1, 0.5, specs.ENV_RELEASE.maxval, math.random()))
    
    params:set("Amp", util.linlin(0, 1, 0.5, 0.8, math.random()))
    params:set("Amp Mod (LFO)", math.random())
    
    params:set("Ring Mod Fade", util.linlin(0, 1, specs.RING_MOD_FADE.minval, specs.RING_MOD_FADE.maxval, math.random()))
    if(math.random() > 0.8) then
      params:set("Ring Mod Mix", math.random())
    else
      params:set("Ring Mod Mix", 0)
    end
    
    
  else -- Perc
    
    params:set("Frequency Mod (LFO)", util.linexp(0, 1, 0.0000001, 1, math.pow(math.random(), 2)))
    params:set("Frequency Mod (Env-1)", util.linlin(0, 1, specs.FREQ_MOD_ENV.minval, specs.FREQ_MOD_ENV.maxval, math.pow(math.random(), 4)))
    
    params:set("Glide", util.linexp(0, 1, 0.0000001, specs.GLIDE.maxval, math.pow(math.random(), 2)))
    
    params:set("Main Osc Level", math.random())
    params:set("Sub Osc Level", math.random())
    params:set("Sub Osc Detune", util.linlin(0, 1, specs.SUB_OSC_DETUNE.minval, specs.SUB_OSC_DETUNE.maxval, math.random()))
    params:set("Noise Level", util.linlin(0, 1, 0.1, 1, math.random()))
    
    params:set("LP Filter Cutoff", util.linexp(0, 1, 100, 6000, math.random()))
    if math.random() > 0.6 then
      params:set("LP Filter Resonance", util.linlin(0, 1, 0.5, 1, math.random()))
    else
      params:set("LP Filter Resonance", math.random())
    end
    params:set("LP Filter Mod (Env)", util.linlin(0, 1, -0.3, 1, math.random()))
    params:set("LP Filter Mod (LFO)", math.random())
    
    params:set("Env-1 Attack", util.linlin(0, 1, specs.ENV_ATTACK.minval, specs.ENV_ATTACK.maxval, math.random()))
    
    params:set("Env-2 Attack", specs.ENV_ATTACK.minval)
    params:set("Env-2 Decay", util.linlin(0, 1, 0.008, 1.8, math.pow(math.random(), 4)))
    params:set("Env-2 Sustain", 0)
    params:set("Env-2 Release", params:get("Env-2 Decay"))
    
    if params:get("Env-2 Decay") < 0.15 and params:get("Env-1 Attack") > 1 then
      params:set("Env-1 Attack", params:get("Env-2 Decay"))
    end
    
    local amp_max = 1
    if math.random() > 0.7 then amp_max = 11 end
    params:set("Amp", util.linlin(0, 1, 0.75, amp_max, math.random()))
    params:set("Amp Mod (LFO)", util.linlin(0, 1, 0, 0.2, math.random()))
    
    params:set("Ring Mod Fade", util.linlin(0, 1, specs.RING_MOD_FADE.minval, 2, math.random()))
    if(math.random() > 0.4) then
      params:set("Ring Mod Mix", math.random())
    else
      params:set("Ring Mod Mix", 0)
    end
    
  end
  
  if params:get("Main Osc Level") < 0.6 and params:get("Sub Osc Level") < 0.6 and params:get("Noise Level") < 0.6 then
    params:set("Main Osc Level", util.linlin(0, 1, 0.6, 1, math.random()))
  end
  
  if params:get("LP Filter Cutoff") > 12000 and math.random() > 0.7 then
    params:set("HP Filter Cutoff", util.linexp(0, 1, specs.HP_FILTER_CUTOFF.minval, params:get("LP Filter Cutoff") * 0.05, math.random()))
  else
    params:set("HP Filter Cutoff", specs.HP_FILTER_CUTOFF.minval)
  end
  
  if params:get("LP Filter Cutoff") < 600 and params:get("LP Filter Mod (Env)") < 0 then
    params:set("LP Filter Mod (Env)", math.abs(params:get("LP Filter Mod (Env)")))
  end
  
end

return MollyThePoly
