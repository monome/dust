-- @name knaster
-- @version 0.1.0
-- @author jah
-- @txt a very basic example

engine.name = 'Knaster'

local SCREEN_WIDTH = 128
local SCREEN_HEIGHT = 64

local vu = 0

init = function()
  engine.volume(0)
  screen.line_width(1)

  if g then
    g:all(0)
    g:refresh()
  end
  start_amp_poll()
end

enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
  end
end

redraw = function()
  screen.clear()
  screen.aa(0)
  screen.move(0,7*8-1)
  screen.font_size(30)
  screen.text("knaster")
  screen.update()
end

bang = function()
  local level = vu/50*15
  if level > 5 then
    level = (level - 5)
    local x = math.random(SCREEN_WIDTH)
    local y = math.random(SCREEN_HEIGHT)
    screen.level(level*1)
    screen.rect(x, y, level, level)
    screen.fill()
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
