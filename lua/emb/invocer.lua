engine.name = 'Vocer'


local param_state = {}
local param_names = {'gate', 'freeze', 'diffuse_rate'}
local num_params = 3
local num_voices = 8


local hz = 10000 -- diffusion rate

for k,v in ipairs(param_names) do   
   local state = {}
   for i=1,num_voices do
      state[i] = 0
   end
   param_state[v] = state
end

function toggle_param(name, i)
   print("toggle", name, i)
   local z = param_state[name][i]
   if z > 0 then
      z = 0
   else
      if name == "diffuse_rate" then z = hz
      else z = 1 end
   end   
   engine[name](i, z)
   param_state[name][i] = z
end

function gridredraw()
   if not g then return end
   local z, pname
   for i=1,num_voices do
      for j=1,num_params do
	 pname = param_names[j]
	 if param_state[pname][i] > 0 then
	    g:led(i, j, 12)
	 else
	    g:led(i, j, 1)
	 end
      end
   end
   g:refresh()
end


gridkey = function(x, y, z)
   if z == 0 then return end   
   if x <= num_voices then
      local name = param_names[y]
      if name then toggle_param(name, x) 
	 gridredraw()
      end
   end
end

init = function()
   if g then
      g:all(0)
      gridredraw()
   end
end
