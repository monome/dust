--- Passersby lib
-- Engine params and functions.
--
-- @module Passersby
-- @release v1.0.0
-- @author Mark Eats

local ControlSpec = require "controlspec"

local Passersby = {}

Passersby.LFO_DESTINATIONS = {"None", "Frequency", "Wave Shape", "Wave Folds", "FM Low", "FM High", "LPG Peak", "LPG Decay", "Reverb Mix"}

local specs = {}

specs.WAVE_SHAPE = ControlSpec.UNIPOLAR
specs.WAVE_FOLDS = ControlSpec.new(0.0, 3.0, "lin", 0, 0)
specs.FM_LOW_AMOUNT = ControlSpec.UNIPOLAR
specs.FM_HIGH_AMOUNT = ControlSpec.UNIPOLAR
specs.LPG_PEAK = ControlSpec.new(100, 10000, "exp", 0, 10000, "Hz")
specs.LPG_DECAY = ControlSpec.new(0.1, 8.0, "exp", 0, 2, "s")
specs.REVERB_MIX = ControlSpec.UNIPOLAR
specs.LFO_FREQ = ControlSpec.new(0.001, 10.0, "exp", 0, 0.5, "Hz")
specs.LFO_AMOUNT = ControlSpec.new(0, 1, "lin", 0, 0.5, "")
specs.DRIFT = ControlSpec.UNIPOLAR
specs.RANDOMIZE = ControlSpec.new(0, 1, "lin", 1, 0, "") -- Bit of a hack to get a trigger param

Passersby.specs = specs


local function format_freq(param)
  local freq = param:get()
  if freq < 0.1 then
    freq = util.round(freq, 0.001) .. " Hz"
  elseif freq < 100 then
    freq = util.round(freq, 0.01) .. " Hz"
  elseif util.round(freq, 1) < 1000 then
    freq = util.round(freq, 1) .. " Hz"
  else
    freq = util.round(freq / 1000, 0.01) .. " kHz"
  end
  return freq
end

local function format_secs(param)
  local secs = param:get()
  if util.round(secs, 0.01) >= 1 then
    secs = util.round(secs, 0.1)
  else
    secs = util.round(secs, 0.01)
    if string.len(secs) < 4 then secs = secs .. "0" end
  end
  return secs .. " s"
end


function Passersby.add_params()
  
  params:add_control("Wave Shape", specs.WAVE_SHAPE)
  params:set_action("Wave Shape", engine.waveShape)
  
  params:add_control("Wave Folds", specs.WAVE_FOLDS)
  params:set_action("Wave Folds", engine.waveFolds)
  
  params:add_control("FM Low Amount", specs.FM_LOW_AMOUNT)
  params:set_action("FM Low Amount", engine.fm1Amount)
  
  params:add_control("FM High Amount", specs.FM_HIGH_AMOUNT)
  params:set_action("FM High Amount", engine.fm2Amount)
  
  params:add_control("LPG Peak", specs.LPG_PEAK, format_freq)
  params:set_action("LPG Peak", engine.lpgPeak)
  
  params:add_control("LPG Decay", specs.LPG_DECAY, format_secs)
  params:set_action("LPG Decay", engine.lpgDecay)
  
  params:add_control("Reverb Mix", specs.REVERB_MIX)
  params:set_action("Reverb Mix", engine.reverbMix)
  
  params:add_control("LFO Frequency", specs.LFO_FREQ, format_freq)
  params:set_action("LFO Frequency", engine.lfoFreq)
  
  params:add_control("LFO Amount", specs.LFO_AMOUNT)
  params:set_action("LFO Amount", engine.lfoAmount)

  for i = 1, 2 do
    params:add_option("LFO Destination " .. i, Passersby.LFO_DESTINATIONS)
    params:set_action("LFO Destination " .. i, function(value)
      engine.lfoDest(i - 1, value - 1)
    end)
  end
  
  params:add_control("Drift", specs.DRIFT)
  params:set_action("Drift", engine.drift)
  
  params:bang()
  
  params:add_control("Randomize", specs.RANDOMIZE, function() return "" end)
  params:set_action("Randomize", Passersby.randomize_params)
  
end

function Passersby.randomize_params()
  params:set("Wave Shape", math.random())
  params:set("Wave Folds", util.linlin(0, 1, Passersby.specs.WAVE_FOLDS.minval, Passersby.specs.WAVE_FOLDS.maxval, math.pow(math.random(), 2)))
  params:set("FM Low Amount", math.pow(math.random(), 4))
  params:set("FM High Amount", math.pow(math.random(), 4))
  params:set("LPG Peak", util.linlin(0, 1, Passersby.specs.LPG_PEAK.minval, Passersby.specs.LPG_PEAK.maxval, math.random()))
  params:set("LPG Decay", util.linlin(0, 1, Passersby.specs.LPG_DECAY.minval, Passersby.specs.LPG_DECAY.maxval, math.pow(math.random(), 2)))
  params:set("Reverb Mix", math.random())
  params:set("LFO Frequency", util.linlin(0, 1, Passersby.specs.LFO_FREQ.minval, Passersby.specs.LFO_FREQ.maxval, math.random()))
  params:set("LFO Amount", math.random())
  for i = 1, 2 do
    if math.random() > 0.4 then params:set("LFO Destination " .. i, util.round(util.linlin(0, 1, 1, #Passersby.LFO_DESTINATIONS, math.random())))
    else params:set("LFO Destination " .. i, 0) end
  end
  params:set("Randomize", 0)
end

return Passersby
