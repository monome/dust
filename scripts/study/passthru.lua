-- PassThru Test

engine.name = 'SimplePassThru'

local audio = require 'audio'

function init()
   print("Simple Pass Thru Test")
   audio.monitor_off()
end

function key(n,z)
   if n == 2 then
      if z == 1 then
	 screen.move(10, 10)
	 screen.text("Listen")
	 screen.update()
	 engine.amp(1.0)
      elseif z == 0 then
	 screen.clear()
	 screen.update()
	 engine.amp(0.0)
      end
   end
end

function redraw()
  screen.clear()
  screen.update()
end

