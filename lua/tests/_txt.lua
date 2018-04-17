-- quick textentry test

te = require 'textentry'

thewords = "hit key 3"

txtcallback = function(txt)
  if txt then thewords = txt
  else thewords = "(cancel)" end
  redraw()
end

key = function(n,z)
  if z == 1 then
    te.enter(txtcallback)
  end
end

redraw = function()
  screen.clear()
  screen.move(0,10)
  screen.text(thewords)
  screen.update()
end
