-- strides
--
-- 4 track finger drum pattern
-- recorder/looper.
--
-- requires a grid.
--
-- load samples via
-- parameters menu.
-- ----------
--
-- key1 = hold to access
-- secondary encoder functions.
-- key2 = half time
-- key3 = double time
--
-- enc1 = output vol/distortion
-- enc2 = delay time/ level
-- enc3 = delay feedback/ send
-- ----------
--
-- grid layout
--
-- the 4 buttons in column
-- 1 are the track selection
-- buttons.
--
-- the 2x4 grid of buttons
-- launches samples.
--
-- the 2 buttons above
-- the sample pads are
-- transport controls.
-- x = 3, y = 2 is record,
-- and x = 4, y = 2 start/stop.
--
-- the remaining button is the
-- alt button.
--
-- alt + start/stop = stop all
-- tracks
--
-- alt + rec =  clear all tracks
--
-- alt + track select = stop
-- selected track.
--
-- while holding alt, the right
-- side of the grid will light
-- up with time and playback
-- speed controls.
--
-- the column to the right of alt
-- arms/disarms pattern
-- linearizing.
--
-- the 4 button diamond controls
-- pattern time, via the left and
-- right buttons, and sample
-- playback speed, via up and
-- down.
--
-- remaining are buttons for
-- restoring pattern timing,
-- on the left, and sample play-
-- back speed, on the right.
-- ----------
--
-- note: arming a track for
-- recording will clear any
-- patterns previously
-- recorded on that track.
--
-- ----------
--
-- TODO
--
-- gamepad support.
--
-- v1.0 by @justmat

engine.name = "Ack"

local ack = require 'jah/ack'
local pattern_time = require 'pattern_time'

local g = grid.connect(1)

local current_pat = 1
local sample_playback_speed = 1
local alt = 0
local key1 = 0
local speed_changed = false
local last_enc = nil
local time_last = 0
local time_last_enc = 0

local is_linearized = {}
for i = 1, 4 do
  is_linearized[i] = 0
end

local lit = {}
local base_time = {}
local lin_time = {}
local pattern = {}

-- helper functions --

local function get_pat()
  return pattern[current_pat]
end


local function clear_all_pat()
  for i = 1, 4 do
    pattern[i]:clear()
  end
  current_pat = 1
end


local function stop_all_pat()
  for i = 1, 4 do
    pattern[i]:stop()
  end
end


local function set_base_time()
  -- stores a copy of pattern[].time for recall.
  for i = 1, 4 do
    base_time[i] = {}
    for j = 1, #pattern[i].time do
      base_time[i][j] = pattern[i].time[j]
    end
  end
end


local function set_lin_time()
  -- stores a linearized pattern.time for recall later.
  for i = 1, 4 do
    lin_time[i] = {}
    for j = 1, #pattern[i].time do
      lin_time[i][j] = pattern[i].time[j]
    end
  end
end


local function set_playback_speed()
  for i = 1, 8 do
    params:set(i .."_speed", sample_playback_speed)
  end
end


local function speed_up_time()
  -- doubles the speed of pattern playback
  for i = 1, 4 do
    for j = 1, #pattern[i].time do
      pattern[i].time[j] = util.clamp(pattern[i].time[j] * .5, .01, 1)
    end
  end
end


local function speed_up_playback()
  -- doubles the speed of sample playback
  sample_playback_speed = util.clamp(sample_playback_speed + sample_playback_speed, 0.25, 5)
  speed_changed = true
end


local function slow_down_time()
  -- halfs speed of pattern playback
  for i = 1, 4 do
    if pattern[i].count > 0 then
      for j = 1, #pattern[i].time do
        pattern[i].time[j] = pattern[i].time[j] / .5
      end
    end
  end
end


local function slow_down_playback()
  -- halfs speed of sample playback
  sample_playback_speed = util.clamp(sample_playback_speed * .5, 0.25, 5)
  speed_changed = true
end
  

local function restore_time(n)
  -- restores time. respects linearization.
  if is_linearized[n - 1] == 1 then
    for j = 1, #pattern[n - 1].time do
      pattern[n - 1].time[j] = lin_time[n - 1][j]
    end
  else
    for j = 1, #pattern[n - 1].time do
      pattern[n - 1].time[j] = base_time[n - 1][j]
    end
  end
end


local function restore_playback()
  -- restores sample playback speed.
  sample_playback_speed = 1
  speed_changed = true
end


local function linearize_pat(n)
  local total_time = 0
  
  for i = 1, #pattern[n - 1].time do
    total_time = total_time + pattern[n - 1].time[i]
  end
  
  local l_time = total_time / get_pat().count
  
  for i = 1, #pattern[n - 1].time do
    pattern[n - 1].time[i] = l_time
  end
  
  set_lin_time()
  is_linearized[n - 1] = 1
end


local function trig(e)
  if e.state > 0 then
    lit[e.id] = {}
    lit[e.id].state = 1
    lit[e.id].x = e.x
    lit[e.id].y = e.y
    
    if speed_changed then
      set_playback_speed()
      speed_changed = false
    end
    
    if e.y == 4 then
      engine.trig(e.x - 3)
    elseif e.y == 5 then
      engine.trig(e.x + 1)
    end
  else
    if lit[e.id].state == 1 then
      lit[e.id].state = 0
    end
  end
  gridredraw()
end


for i=1,4 do
  pattern[i] = pattern_time.new()
  pattern[i].process = trig
end


function init()
  -- add engine params
  for i = 1, 8 do
    ack.add_channel_params(i)
    params:add_separator()
  end
  ack.add_effects_params()
  -- screen refresh metro
  local screen_m = metro.alloc(function(stage) redraw() end, 1 / 15)
  screen_m:start()
  -- load the default paramset
  params:read("justmat/strides.pset")
  params:bang()
  -- draw grid
  if g then
    gridredraw()
  end
end


function key(n, z)
  if n == 1 then key1 = z end
  if n == 2 and z == 1 then
    slow_down_time()
    slow_down_playback()
  elseif n == 3 and z == 1 then
    speed_up_time()
    speed_up_playback()
  end
end


function enc(n, d)
  if n == 1 then
    if key1 == 1 then
      for i = 1, 8 do
        params:delta(i .. "_dist", d)
      end
    else
      mix:delta("output", d)
    end
    last_enc = 1
    time_last_enc = util.time()
    
  elseif n == 2 then
    if key1 == 1 then
      params:delta("delay_level", d)
    else
      params:delta("delay_time", d)
    end
    last_enc = 2
    time_last_enc = util.time()
    
  elseif n == 3 then
    if key1 == 1 then
      for i = 1, 8 do
        params:delta(i .. "_delay_send", d)
      end
    else
      params:delta("delay_feedback", d)
    end
    last_enc = 3
    time_last_enc = util.time()
  end
end


function g.event(x, y, state)
  if y == 2 and x == 3 then
    -- rec button. clears selected track/pattern.
    -- alt + rec clears all patterns.
    if state == 1  then
      if alt == 1 then
        clear_all_pat()
      elseif get_pat().rec == 0 then
        get_pat():stop()
        get_pat():clear()
        get_pat():rec_start()
      elseif get_pat().rec == 1 then
        get_pat():rec_stop()
        if get_pat().count > 0 then
          get_pat():start()
        end
      end
    end
  elseif y == 2 and x == 4 then
    -- start/stop button. if recording, starts playback.
    -- alt + stop/start stops all pattern playback.
    if state == 1 then
      if alt == 1 then
        stop_all_pat()
      elseif get_pat().play == 0 and get_pat().count > 0 then
        if get_pat().rec == 1 then
          get_pat():rec_stop()
        end
        get_pat():start()
        set_base_time()
      elseif get_pat().play == 1 then
        get_pat():stop()
      end
    end
  -- alt button
  elseif y == 2 and x == 6 then
    alt = state
  -- track select buttons
  -- alt + track select button stops track.
  elseif x == 1 and y >= 2 and y <= 5 then
    if state == 1 then
      if alt == 1 then
        if pattern[y -1].play == 1 then
          pattern[y - 1]:stop()
        else
          pattern[y - 1]:start()
        end
      else
        current_pat = y - 1
      end
    end
  elseif x >= 3 and x <= 6 then
    if y == 4 or y == 5 then
    -- this is the drum pad grid.
      local e = {}
      e.id = x * 8 + y
      e.x = x
      e.y = y
      e.state = state
      trig(e)
      if get_pat().rec == 1 then
        get_pat():watch(e)
      end
    end
  end
  if alt == 1 then
    -- timing and speed controls for grid
    if x == 9 and y >= 2 and y <= 5 then
      if state == 1 then
        if is_linearized[y - 1] == 1 then
          is_linearized[y - 1] = 0
          restore_time(y)
        else
          linearize_pat(y)
          is_linearized[y - 1] = 1
        end
      end
    elseif x == 13 and y == 2 then
      speed_up_playback()
    elseif x == 14 and y == 3 then
      speed_up_time()
    elseif x == 13 and y == 4 then
      slow_down_playback()
    elseif x == 12 and y == 3 then
      slow_down_time()
    elseif x == 11 and y == 5 then
      for i = 1, 4 do
        restore_time(i + 1)
      end
    elseif x == 15 and y == 5 then
      restore_playback()
    end
  end
gridredraw()
end


function gridredraw()
  g.all(0)
  -- rec button.
  if get_pat().rec == 1 then
    g.led(3, 2, 10)
  elseif get_pat().count > 0 then
    g.led(3, 2, 6)
  else
    g.led(3, 2, 3)
  end
  -- start/stop button
  if get_pat().play == 1 then
    g.led(4, 2, 6)
  else
    g.led(4, 2, 3)
  end
  -- alt
  if alt == 1 then
    g.led(6, 2, 6)
  else
    g.led(6, 2, 3)
  end
  -- tracks
  for i = 1, 4 do
    if current_pat == i then
      g.led(1, i + 1, 10)
    elseif pattern[i].count > 0 then
      g.led(1, i + 1, 6)
    else
      g.led(1, i + 1, 3)
    end
  end
  -- drum pads
  for i = 3, 6 do
    g.led(i, 4, 4)
    g.led(i, 5, 4)
  end
  for i, e in pairs(lit) do
    if e.state == 1 then
      g.led(e.x, e.y, 10)
    else
      g.led(e.x, e.y, 4)
    end
  end
  -- pattern linearize buttons
  if alt == 1 then
    for i = 2, 5 do
      if is_linearized[i - 1] == 1 then
        g.led(9, i, 8)
      else
        g.led(9, i, 4)
      end
    end
    -- time/ playback speed controls
    g.led(13, 2, 4)
    g.led(12, 3, 4)
    g.led(14, 3, 4)
    g.led(13, 4, 4)
    g.led(11, 5, 4)
    g.led(15, 5, 4)
  end
  g:refresh()
end


function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(64, 60)

  if last_enc == 1 then
    if util.time() - time_last_enc < .6 then
      if key1 == 1 then
        screen.text_center("distortion : " .. string.format("%.2f", params:get("1_dist")))
      else
        screen.text_center("vol : " .. string.format("%.2f", mix:get("output")))
      end
    end
    
  elseif last_enc == 2 then
    if util.time() - time_last_enc < .6 then
      if key1 == 1 then
        screen.text_center("delay level : " .. string.format("%.2f", params:get("delay_level")))
      else
        screen.text_center("delay time : " .. string.format("%.2f", params:get("delay_time")))
      end
    end
    
  elseif last_enc == 3 then
    if util.time() - time_last_enc < .6 then
      if key1 == 1 then
        screen.text_center("delay send : " .. string.format("%.2f", params:get("1_delay_send")))
      else
        screen.text_center("delay feedback : " .. string.format("%.2f", params:get("delay_feedback")))
      end
    end
  end
  screen.stroke()
  -- fuzzy screen stuff
  for i = 1, math.random(3, 15) do
    local x = math.random(1, 127)
    local y = math.random(1, 52)
    screen.pixel(x, y)
    screen.level(math.random(1, 10))
    screen.stroke()
  end
  screen.update()
end
