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

-- round to multiple of quant
local function round(number, quant)
  if quant == 0 then
    return number
  else
    return math.floor(number/quant + 0.5) * quant
  end
end

-- round up to a multiple of quant
local function round_up(number, quant)
  if quant == 0 then
    return number
  else
    return math.ceil(number/quant + 0.5) * quant
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
    else -- TODO: anything other than 'exp' is 'lin'
      s.warp = ControlSpec.WARP_LIN
    end
  else -- TODO: here number is assumed
    s.warp = warp
  end
  s.step = step
  s.default = default
  s.units = units or ""
  return s
end

function ControlSpec:map(value)
  if self.warp == ControlSpec.WARP_LIN then
    return linlin(0, 1, self.minval, self.maxval, value)
  elseif self.warp == ControlSpec.WARP_EXP then
    return linexp(0, 1, self.minval, self.maxval, value)
  end
end

function ControlSpec:unmap(value)
  if self.warp == ControlSpec.WARP_LIN then
    return linlin(self.minval, self.maxval, 0, 1, value)
  elseif self.warp == ControlSpec.WARP_EXP then
    return explin(self.minval, self.maxval, 0, 1, value)
  end
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

return ControlSpec
