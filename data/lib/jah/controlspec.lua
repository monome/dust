-- TODO: refactor linexp/linlin/explin/expexp to utility module somewhere

-- linlin, linexp, explin, expexp ripped from SC source code
-- https://github.com/supercollider/supercollider/blob/cca12ff02a774a9ea212e8883551d3565bb24a6f/lang/LangSource/MiscInlineMath.h
--
local function linexp(slo, shi, dlo, dhi, f)
  if f <= slo then
    return dlo
  elseif f >= shi then
    return dhi
  else
    return math.pow( dhi/dlo, (f-slo) / (shi-slo) ) * dlo
  end
end

local function linlin(slo, shi, dlo, dhi, f)
  if f <= slo then
    return dlo
  elseif f >= shi then
    return dhi
  else
    return (f-slo) / (shi-slo) * (dhi-dlo) + dlo
  end
end

local function explin(slo, shi, dlo, dhi, f)
  if f <= slo then
    return dlo
  elseif f >= shi then
    return dhi
  else
    return math.log(f/slo) / math.log(shi/slo) * (dhi-dlo) + dlo
  end
end

local function expexp(slo, shi, dlo, dhi, f)
  if f <= slo then
    return dlo
  elseif f >= shi then
    return dhi
  else
    return math.pow(dhi/dlo, math.log(f/slo)) / (math.log(shi/slo)) * dlo
  end
end

-- TODO: duplication, this is the same as Param.round? refactor
-- round to multiple of quant
local function round(number, quant)
  if quant == 0 then
    return number
  else
    return math.floor(number/quant + 0.5) * quant
  end
end

-- TODO: prune if not used anywhere
-- round up to a multiple of quant
local function round_up(number, quant)
  if quant == 0 then
    return number
  else
    return math.ceil(number/quant + 0.5) * quant
  end
end

local function map(warp, minval, maxval, value)
  if warp == ControlSpec.WARP_LIN then
    return linlin(0, 1, minval, maxval, value)
  elseif warp == ControlSpec.WARP_EXP then
    return linexp(0, 1, minval, maxval, value)
  end
end

local function unmap(warp, minval, maxval, value)
  if warp == ControlSpec.WARP_LIN then
    return linlin(minval, maxval, 0, 1, value)
  elseif warp == ControlSpec.WARP_EXP then
    return explin(minval, maxval, 0, 1, value)
  end
end

local ControlSpec = {}
ControlSpec.WARP_LIN = 1
ControlSpec.WARP_EXP = 2
ControlSpec.__index = ControlSpec

function ControlSpec.new(minval, maxval, warp, step, default, units)
  local s = setmetatable({}, ControlSpec)
  s.minval = minval
  s.maxval = maxval
  if type(warp) == "string" then
    if warp == 'exp' then
      s.warp = ControlSpec.WARP_EXP
    else
      s.warp = ControlSpec.WARP_LIN
    end
  elseif type(warp) == "number" then
    s.warp = warp -- TODO: assumes number is in [ControlSpec.WARP_LIN, ControlSpec.WARP_EXP]
  else
    s.warp = ControlSpec.WARP_LIN
  end
  s.step = step
  s.default = default or minval -- TODO: test to ensure minval fallback works
  s.units = units or ""
  return s
end

function ControlSpec:map(value)
  return map(self.warp, self.minval, self.maxval, value)
end

function ControlSpec:unmap(value)
  return unmap(self.warp, self.minval, self.maxval, value)
end

function ControlSpec:constrain(value)
  return round(util.clamp(value, self.minval, self.maxval), self.step or 0)
end

function ControlSpec:print()
  for k,v in pairs(self) do
    print("ControlSpec:")
    print('>> ', k, v)
  end
end

--[[
TODO 1:
consider defining these default specs as global constants, ie. ControlSpec.UNIPOLAR, ControlSpec.BIPOLAR, ControlSpec.FREQ, etc (akin to how SuperCollider works) however, since afaik there's no way of freezing objects in lua either storing default specs this way as globals is error prone: if someone changes the properties of a ControlSpec.GLOBAL spec it would affect all usages (this is the root cause of weird unexpected errors in SuperCollider too)
TODO 2: naming consider removing _spec suffix
]]
function ControlSpec.unipolar_spec()
  return ControlSpec.new(0, 1, 'lin', 0, 0, "")
end

function ControlSpec.bipolar_spec()
  return ControlSpec.new(-1, 1, 'lin', 0, 0, "")
end

function ControlSpec.freq_spec()
  return ControlSpec.new(20, 20000, 'exp', 0, 440, "Hz")
end

function ControlSpec.lofreq_spec()
  return ControlSpec.new(0.1, 100, 'exp', 0, 6, "Hz")
end

function ControlSpec.midfreq_spec()
  return ControlSpec.new(25, 4200, 'exp', 0, 440, "Hz")
end

function ControlSpec.widefreq_spec()
  return ControlSpec.new(0.1, 20000, 'exp', 0, 440, "Hz")
end

function ControlSpec.phase_spec()
  return ControlSpec.new(0, math.pi, 'lin', 0, 0, "")
end

function ControlSpec.rq_spec()
  return ControlSpec.new(0.001, 2, 'exp', 0, 0.707, "")
end

function ControlSpec.midi_spec()
  return ControlSpec.new(0, 127, 'lin', 0, 64, "")
end

function ControlSpec.midinote_spec()
  return ControlSpec.new(0, 127, 'lin', 0, 60, "")
end

function ControlSpec.midivelocity_spec()
  return ControlSpec.new(1, 127, 'lin', 0, 64, "")
end

function ControlSpec.db_spec()
  return ControlSpec.new(-60, 0, 'lin', nil, nil, "dB") -- TODO: this uses DbFaderWarp in SuperCollider, would be good to have in lua too
end

function ControlSpec.amp_spec()
  return ControlSpec.new(0, 1, 'lin', 0, 0, "") -- TODO: this uses FaderWarp in SuperCollider, would be good to have in lua too
end

function ControlSpec.boostcut_spec()
  return ControlSpec.new(-20, 20, 'lin', 0, 0, "dB")
end

function ControlSpec.pan_spec()
  return ControlSpec.new(-1, 1, 'lin', 0, 0, "")
end

function ControlSpec.detune_spec()
  return ControlSpec.new(-20, 20, 'lin', 0, 0, "Hz")
end

function ControlSpec.rate_spec()
  return ControlSpec.new(0.125, 8, 'exp', 0, 1, "")
end

function ControlSpec.beats_spec()
  return ControlSpec.new(0, 20, 'lin', 0, 0, "Hz")
end

function ControlSpec.delay_spec()
  return ControlSpec.new(0.0001, 1, 'exp', 0, 0.3, "Hz")
end

return ControlSpec
