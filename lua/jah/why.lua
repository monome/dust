-- @name why
-- @version 1.0
-- @author jmcc

Helper = require '_helper'

engine = 'Why'

init = function()
  redraw()
end

enc = function(n, delta)
  if n == 1 then
    Helper.adjust_audio_output_level(delta)
  end
end

redraw = function()
  s.clear()
  s.level(15)
  s.move(0, 8)
  s.text("Why?")
  s.update()
end
