--[[
  R lua side conventions:
  - module names are [a-zA-Z0-9]
  - Params for module parameters are assumed to be named "[modulename] [paramname]"
  - Params for module to module patches are assumed to be named "[modulename] > [paramname]" (presence of greater-than sign implies patch cord)
]]

local R = {}

local function split_param_name(param)
  words = {}
  for word in param.title:gmatch("[a-zA-Z0-9>]+") do table.insert(words, word) end
  return words
end

local function is_patch_param(param)
  return split_param_name(param)[2] == '>'
end

function R.send_r_param_value_to_engine(param)
  if is_patch_param(param) then
    module_gt_module = split_param_name(param)
    e.patch(module_gt_module[1], module_gt_module[3], param:mapped_value())
  else
    module_param = split_param_name(param)
    e.param(module_param[1], module_param[2], param:mapped_value())
  end
end

function R.send_r_param_values_to_engine(params)
  for i, param in ipairs(params) do
    R.send_r_param_value_to_engine(param)
  end
end

return R
