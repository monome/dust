local MEFormatters = {}

function MEFormatters.format_freq(param)
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

function MEFormatters.format_secs(param)
  local secs = param:get()
  if util.round(secs, 0.01) >= 1 then
    secs = util.round(secs, 0.1)
  else
    secs = util.round(secs, 0.01)
    if string.len(secs) < 4 then secs = secs .. "0" end
  end
  return secs .. " s"
end

return MEFormatters