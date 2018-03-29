-- TODO: something like this should probably be in, or already exists in norns lua core
--
local Helper = {}

function Helper.adjust_audio_output_level(delta)
  print("pre norns.state.out: "..norns.state.out)
  local l = util.clamp(norns.state.out + delta,0,64)
  if l ~= norns.state.out then
    norns.state.out = l
    audio_output_level(l / 64.0)
  end
  print("post norns.state.out: "..norns.state.out)
end

return Helper
