-- quick textentry
-- hit key to enter text
-- entry mode

engine.name = "TestSine"

thewords = "hit key 3"

init = function()
end


txtcallback = function(txt)
  if txt then thewords = txt
  else thewords = "(cancel)" end
  redraw()
end

key = function(n,z)
  if z == 1 then
    textentry.enter(txtcallback)
  end
end

enc = function(n,d)
end

redraw = function()
  screen.clear()
  screen.move(0,10)
  screen.text(thewords)
  screen.update()
end
