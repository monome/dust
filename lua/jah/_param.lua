local Param = {}
Param.__index = Param

local function round(number, quant)
  if quant == 0 then
    return number
  else
    return math.floor(number/quant + 0.5) * quant
  end
end

function Param.new(title, controlspec, value)
  local p = setmetatable({}, Param)
  p.title = title
  p.controlspec = controlspec

  if value then
    p.value = value
  elseif controlspec and controlspec.default then
    p.value = controlspec:unmap(controlspec.default)
  else
    p.value = 0
  end
  return p
end

function Param:print()
  for k,v in pairs(self) do
    print('>> ', k, v)
  end
end

function Param:string(quant)
  local v
  if quant then
    v = round(self.controlspec:map(self.value), quant)
  else
    v = self.controlspec:map(self.value)
  end
  return self.title..": "..v.." "..(self.controlspec.units)
end

function Param:set(value)
  self.value = util.clamp(value, 0, 1)
end

function Param:set_mapped_value(value)
  self:set(self.controlspec:unmap(value))
end

function Param:adjust(delta)
  self.value = util.clamp(self.value + delta, 0, 1)
end

function Param:adjust_wrap(delta) -- TODO
  self.value = util.clamp(self.value + delta, 0, 1)
end

function Param:mapped_value()
  return self.controlspec:map(self.value)
end

function Param:revert_to_default()
  if self.controlspec and self.controlspec.default then
    self.value = self.controlspec:unmap(self.controlspec.default)
  else
    self.value = 0
  end
end

return Param
