--- engine utils
local engine_utils = {}

function engine_utils.param_index(name)
  for i = 1, params["count"] do
    if (params:get_name(i) == name) then
      return i
    end
  end
  return -1
end

function engine_utils.param_get(name)
  local index = engine_utils.param_index(name)
  return index < 1 and nil or params:get(index)
end

function engine_utils.param_set(name, x)
  local index = engine_utils.param_index(name)
  if (index >= 1) then
    params:set(index, x)
  end
end

function engine_utils.add_param_control(name, minval, maxval, step, default)
  params:add_control(name, controlspec.new(minval, maxval --[[warp--]], "lin", step, default --[[units--]], ""))
  params:set_action(name, engine[name])
end

function engine_utils.list_functions(mod)
  for fname, obj in pairs(mod) do
    if type(obj) == "function" then
      print(fname .. "()")
    end
  end
end

return engine_utils
