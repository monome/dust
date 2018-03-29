-- @name knaster
-- @version 0.1.0
-- @author jah
-- @txt a very basic example

Helper = require 'lua/jah/_helper'

engine = 'Knaster'

local SCREEN_WIDTH = 128
local SCREEN_HEIGHT = 64

local vu = 0

init = function()
  e.volume(0)
  s.line_width(1) 

  if g then
    g:all(0)
    g:refresh()
  end
  start_amp_poll()
end

enc = function(n, delta)
  if n == 1 then
    Helper.adjust_audio_output_level(delta)
  end
end

redraw = function()
  s.clear()
  s.aa(0)
  s.move(0,7*8-1)
  s.font_size(30)
  s.text("knaster")
  s.update()
end 

bang = function()
  local level = vu/50*15
  if level > 5 then
    level = (level - 5)
    local x = math.random(SCREEN_WIDTH)
    local y = math.random(SCREEN_HEIGHT)
    s.level(level*1)
    s.rect(x, y, level, level)
    s.fill()
    -- print("vu: "..level)
    if g then
      g:led(x / SCREEN_WIDTH * 16, y / SCREEN_HEIGHT * 9, level*4)
      g:refresh()
    end
  end
end 

local function calc_meter(amp, n, floor)
  n = n or 64
  floor = floor or -72
  local db = 20.0 * math.log10(amp)
  local norm = 1.0 - (db / floor)
  vu = norm * n
  bang()
end

local amp_callback = function(amp) calc_meter(amp, 64, -72) end

p = nil

start_amp_poll = function()
  p = poll.set('amp_out_l', amp_callback)
  p.time = 0.01;
  p:start()
end 

cleanup = function()
  if p then p:stop() end
end 
