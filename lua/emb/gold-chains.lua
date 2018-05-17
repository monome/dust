-- gold chains
--
-- may 18 2018
-- athens GA

local audio = require 'audio'

audio.monitor_off()

engine.name = 'Scapes'


local dt = 0.63 -- duration of quarter note
local bar = dt * 2
local form = bar * 6

local mvmt = "mvmt_1"

function mvmt_1()   
   engine.grain_amp(1, 0.5)
   engine.grain_delay(1, dt)
   engine.grain_pulse_rate(1, 4.0/dt)
   engine.grain_dur(1, dt / 4.0 * 0.8)
   engine.grain_rate(1, 1.0)
end

function mvmt_2()
   
   engine.grain_delay(1, bar * 6.25)
   engine.grain_pulse_rate(1, 1.5 / dt)
   engine.grain_dur(1, dt * 1.5 * 1.5)
   engine.grain_rate(1, 2.0)

   engine.grain_delay(2, bar)
   engine.grain_pulse_rate(2, 2.25 / dt)
   engine.grain_dur(2, dt / 2.25 * 1.5)
   engine.grain_rate(2, 1.0)

   engine.grain_delay(3, bar * 7)
   engine.grain_pulse_rate(3, 2.5 / dt)
   engine.grain_dur(3, dt / 2.5 * 1.5)
   engine.grain_rate(3, 1.5)

   engine.grain_delay(4, form)
   engine.grain_pulse_rate(4, 1/bar)
   engine.grain_dur(4, bar * 0.8)
   engine.grain_rate(4, 0.5)

   engine.grain_amp(1, 0.15)
   engine.grain_amp(2, 0.2)
   engine.grain_amp(3, 0.2)
   engine.grain_amp(4, 0.3)
   
   mvmt = "mvmt_2"
end



key = function(n, z)
   if (n == 2) and (z == 0) then
      if state == "mvmt_1" then
	 mvmt_2()
      elseif state == "mvmt_2" then
	 mvmt_1()
      end      
      redraw_screen()
   end
      
end

function redraw_screen()
   screen.clear()
   screen.level(15)
   screen.move(10, 10)
   if mvmt == "mvmt_1" then
      screen.text("GOLD")
   elseif mvmt == "mvmt_2" then
      screen.text("CHAIN")
   end
end


init = function()
   mvmt_1()
end
