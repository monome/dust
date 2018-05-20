-- for syrinx,
-- 'ten tinted silences'
-- 
-- input, spectralized, frozen
--
-- grid control: 8 columns
-- row 1: gate output
-- row 2: freeze magnitudes
-- row 8: select voice
--
-- enc 2: shift selected
-- enc 3: scale selected

engine.name = 'Vocer'

local tog_param_state = {}
local tog_param_names = {'gate', 'freeze'}

local num_tog_params = 2
local num_voices = 8

local selected = 1

-- fixme: should be per voice
local shift = 0
local scale = 1
--local wipe = 0

for k,v in ipairs(tog_param_names) do   
   local state = {}
   for i=1,num_voices do
      state[i] = 0
   end
   tog_param_state[v] = state
end

function toggle_param(name, i)
   print("toggle", name, i)
   local z = tog_param_state[name][i]
   if z > 0 then
      z = 0
   else
      if name == "diffuse_rate" then z = hz
      else z = 1 end
   end   
   engine[name](i, z)
   tog_param_state[name][i] = z
end

key = function(n, z)
end

enc = function(n, z)
   if n == 2 then inc_shift(z) end
   --   if n == 3 then inc_wipe(z) end
   if n == 3 then inc_scale(z) end
end


function inc_shift(z)
   shift = shift + z
   engine.shift(selected, shift)
end

--[[
function inc_wipe(z)
   wipe = wipe + z*0.001
   engine.wipe(selected, wipe)
end
--]]

function inc_scale(z)
   scale = scale + z*0.005
   engine.scale(selected, scale)
end


gridredraw = function()
   if not g then return end
   local z, pname
   for i=1,num_voices do
      for j=1,num_tog_params do
	 pname = tog_param_names[j]
	 if tog_param_state[pname][i] > 0 then
	    g:led(i, j, 12)
	 else
	    g:led(i, j, 1)
	 end
      end
      if i == selected then z = 12 else z = 0 end
      g:led(i, 8, z)
   end
   g:refresh()
end

function select_voice(v)
   selected = v
   if selected < 1 then selected = 1
   elseif selected > num_voices then selected = num_voices
   end
end

gridkey = function(x, y, z)
   if z == 0 then return end
   
   if x <= num_voices then
      if y == 8 then
	 select_voice(x)
      else
	 local name = tog_param_names[y]
	 if name then toggle_param(name, x) 
	 end
      end
      gridredraw()
   end
end

init = function()
   for i=1, num_voices do
      engine.atk(i, 2.0)
      engine.rel(i, 4.0)
   end
   
   if g then
      g:all(0)
      gridredraw()
   end
end
