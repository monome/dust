-- strides
--
-- 8 tracks of finger drum
-- pattern recording/looping.
--
-- 8 tracks of encoder
-- recording/looping for
-- midi cc modulation.
--
-- requires a grid.
--
-- load samples and set
-- cc destinations via the
-- parameters menu.
-- ----------
--
-- alt_k = hold to access
-- secondary encoder functions.
--
-- alt_k + key3 = enter/exit
-- encoder recording mode.
--
-- key2 = half time
-- key3 = double time
--
-- enc1 = output vol/ distortion
-- enc2 = delay time/ level
-- enc3 = delay feedback/ send
-- ----------
--
-- encoder recording mode
--
-- key2 = arm record
-- key3 = start/stop playback
--
-- enc1 = select track
-- enc2 = increase/decrease
--        cc value
-- ----------
--
-- grid layout
--
-- column 1 holds the track
-- selection buttons.
--
-- the 2x4 grid of buttons
-- launches samples.
--
-- the 2 buttons above
-- the sample pads are
-- transport controls.
-- x = 3, y = 3 is record,
-- and x = 4, y = 3 start/stop.
--
-- the remaining button is the
-- alt_g button.
--
-- alt_g + start/stop = stop all
-- tracks
--
-- alt_g + rec =  clear all tracks
--
-- alt_g + track select = stop
-- selected track.
--
-- while holding alt_g, the right
-- side of the grid will light
-- up with time and playback
-- speed controls.
--
-- the column to the right of alt_g
-- arms/disarms grid_pattern
-- linearizing.
--
-- the 4 button diamond controls
-- grid_pattern time, via the
-- left and right buttons, and
-- sample playback speed,
-- via up and down.
--
-- remaining are buttons for
-- restoring grid_pattern timing,
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
--
--
-- v1.1 by @justmat

engine.name = "Ack"

local ack = require 'jah/ack'
local pattern_time = require 'pattern_time'

local g = grid.connect(1)
local m = midi.connect(1)

local current_g_pat = 1
local sample_playback_speed = 1
local alt_g = 0
local alt_k = 0
local speed_changed = false
local last_enc = nil
local time_last = 0
local time_last_enc = 0

local is_linearized = {}
for i = 1, 8 do
  is_linearized[i] = 0
end

local lit = {}
local base_time = {}
local lin_time = {}
local grid_pattern = {}
local enc_pattern = {}

local cc_val = {}
for i = 1, 8 do
  cc_val[i] = 0
end

local s_cc_val = {}
for i = 1, 8 do
  s_cc_val[i] = 0
end

local cc_page = 1
local mode = 0

-- helper functions for screen drawing --

local function check_time()
  if util.time() - time_last_enc < .6 then
    return true
  else
    return false
  end
end


local function screen_fuzz()
  for i = 1, math.random(3, 15) do
    local x = math.random(1, 127)
    local y = math.random(1, 52)
    screen.pixel(x, y)
    screen.level(math.random(1, 10))
    screen.stroke()
  end
end


local function draw_stop()
  -- stop icon
  screen.move(40, 2)
  screen.rect(40, 2, 10, 10)
  if enc_pattern[cc_page].play == 0 then
    screen.level(10)
  else
    screen.level(2)
  end
  screen.fill()
  screen.stroke()
end


local function draw_play()
  -- play icon
  screen.move(62, 2)
  screen.line_rel(0, 10)
  screen.line_rel(10, -5)
  screen.line_rel(0, 0)
  if enc_pattern[cc_page].play == 1 then
    screen.level(10)
  else
    screen.level(2)
  end
  screen.fill()
  screen.stroke()
end


local function draw_record()
  -- record icon
  screen.move(86, 7)
  screen.circle(84, 7, 5)
  if enc_pattern[cc_page].rec == 1 then
    screen.level(10)
  else
    screen.level(2)
  end
  screen.fill()
  screen.stroke()
end

-- helper functions for grid --

local function get_grid_pat()
  return grid_pattern[current_g_pat]
end


local function clear_all_grid_pat()
  for i = 1, 8 do
    grid_pattern[i]:clear()
    is_linearized[i] = 0
  end
  current_g_pat = 1
end


local function stop_all_pat()
  for i = 1, 8 do
    grid_pattern[i]:stop()
  end
end


local function set_base_time()
  -- stores a copy of grid_pattern[n].time for recall.
  for i = 1, 8 do
    base_time[i] = {}
    for j = 1, #grid_pattern[i].time do
      base_time[i][j] = grid_pattern[i].time[j]
    end
  end
end


local function set_lin_time()
  -- stores a linearized grid_pattern.time for recall later.
  for i = 1, 8 do
    lin_time[i] = {}
    for j = 1, #grid_pattern[i].time do
      lin_time[i][j] = grid_pattern[i].time[j]
    end
  end
end


local function set_playback_speed()
  for i = 1, 8 do
    params:set(i .."_speed", sample_playback_speed)
  end
end


local function speed_up_time()
  -- doubles the speed of grid_pattern playback
  for i = 1, 8 do
    for j = 1, #grid_pattern[i].time do
      grid_pattern[i].time[j] = util.clamp(grid_pattern[i].time[j] * .5, .01, 1)
    end
  end
end


local function speed_up_playback()
  -- doubles the speed of sample playback
  sample_playback_speed = util.clamp(sample_playback_speed + sample_playback_speed, 0.25, 5)
  speed_changed = true
end


local function slow_down_time()
  -- halfs speed of grid_pattern playback
  for i = 1, 8 do
    if grid_pattern[i].count > 0 then
      for j = 1, #grid_pattern[i].time do
        grid_pattern[i].time[j] = grid_pattern[i].time[j] / .5
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
  if is_linearized[n] == 1 then
    for j = 1, #grid_pattern[n].time do
      grid_pattern[n].time[j] = lin_time[n][j]
    end
  else
    for j = 1, #grid_pattern[n].time do
      grid_pattern[n].time[j] = base_time[n][j]
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

  for i = 1, #grid_pattern[n].time do
    total_time = total_time + grid_pattern[n].time[i]
  end

  local l_time = total_time / get_grid_pat().count

  for i = 1, #grid_pattern[n].time do
    grid_pattern[n].time[i] = l_time
  end

  set_lin_time()
  is_linearized[n] = 1
end

-- pattern processing --

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

    if e.y == 5 then
      engine.trig(e.x - 3)
    elseif e.y == 6 then
      engine.trig(e.x + 1)
    end
  else
    if lit[e.id].state == 1 then
      lit[e.id].state = 0
    end
  end
  gridredraw()
end


local function enc_process(e)
  cc_val[e.id] = util.clamp(cc_val[e.id] + e.d, 0, 127)
  if enc_pattern[e.id].step == 1 then
    cc_val[e.id] = s_cc_val[cc_page]
  end
  m.cc(e.id, cc_val[e.id], params:get("midi_chan"))
end


function init()
  -- set up patterns for grid
  for i=1,8 do
    grid_pattern[i] = pattern_time.new()
    grid_pattern[i].process = trig
  end
  -- set up patterns for knobs
  for i = 1, 8 do
    enc_pattern[i] = pattern_time.new()
    enc_pattern[i].process = enc_process
  end
  -- add engine params
  for i = 1, 8 do
    ack.add_channel_params(i)
    params:add_separator()
  end
  -- set up midi channel and cc nums
  params:add_number("midi_chan", "midi chan", 1, 16, 1)
  for i = 1, 8 do
    params:add_number("cc_num" .. i, "cc num " .. i, 0, 127, i)
  end
  params:add_separator()
  -- engine fx
  ack.add_effects_params()
  params:add_separator()
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
  -- key1 is alt
  if n == 1 then alt_k = z end
  -- alt + key3 changes modes
  if alt_k == 1 and n == 3 and z == 1 then
    if mode == 0 then
      mode = 1
    else
      mode = 0
    end
  end
  -- mode 0 is grid mode
  if mode == 0 then
    if n == 2 and z == 1 then
      slow_down_time()
      slow_down_playback()
    elseif n == 3 and z == 1 then
      if alt_k == 0 then
        speed_up_time()
        speed_up_playback()
      end
    end
  else
  -- mode 1 is encoder mode
  -- key2 and key3 function like record and stop/start on grid
    if alt_k == 0 then
      if n == 2 and z == 1 then
        if enc_pattern[cc_page].rec == 0 then
          enc_pattern[cc_page]:stop()
          enc_pattern[cc_page]:clear()
          s_cc_val[cc_page] = cc_val[cc_page]
          enc_pattern[cc_page]:rec_start()
        elseif enc_pattern[cc_page].rec == 1 then
          enc_pattern[cc_page]:rec_stop()
          if enc_pattern[cc_page].count > 0 then
            enc_pattern[cc_page].step = 1
            enc_pattern[cc_page]:start()
          end
        end
      elseif n == 3  and z == 1 then
        if enc_pattern[cc_page].play == 0 and enc_pattern[cc_page].count > 0 then
          if enc_pattern[cc_page].rec == 1 then
            enc_pattern[cc_page]:rec_stop()
          end
          enc_pattern[cc_page]:start()
        elseif enc_pattern[cc_page].play == 1 then
          enc_pattern[cc_page]:stop()
        end
      end
    end
  end
end


function enc(n, d)
  -- mode 0 is grid mode
  -- encoders control output vol and fx params
  if mode == 0 then
    if n == 1 then
      if alt_k == 1 then
        for i = 1, 8 do
          params:delta(i .. "_dist", d)
        end
      else
        mix:delta("output", d)
      end
      last_enc = 1
      time_last_enc = util.time()

    elseif n == 2 then
      if alt_k == 1 then
        params:delta("delay_level", d)
      else
        params:delta("delay_time", d)
      end
      last_enc = 2
      time_last_enc = util.time()

    elseif n == 3 then
      if alt_k == 1 then
        for i = 1, 8 do
          params:delta(i .. "_delay_send", d)
        end
      else
        params:delta("delay_feedback", d)
      end
      last_enc = 3
      time_last_enc = util.time()
    end
  else
  -- mode 1 is encoder mode
    if n == 1 then
      cc_page = util.clamp(cc_page + d, 1, 8)
    elseif n == 2 then
      if cc_page > 0 then
        local enc_e = {}
        enc_e.id = cc_page
        enc_e.d = d
        enc_pattern[cc_page]:watch(enc_e)
        enc_process(enc_e)
      end
    end
  end
end


function g.event(x, y, state)
  if y == 3 and x == 3 then
    -- rec button. clears selected track/grid_pattern.
    -- alt_g + rec clears all patterns.
    if state == 1  then
      if alt_g == 1 then
        clear_all_grid_pat()
      elseif get_grid_pat().rec == 0 then
        get_grid_pat():stop()
        get_grid_pat():clear()
        get_grid_pat():rec_start()
      elseif get_grid_pat().rec == 1 then
        get_grid_pat():rec_stop()
        if get_grid_pat().count > 0 then
          get_grid_pat():start()
        end
      end
    end
  elseif y == 3 and x == 4 then
    -- start/stop button. if recording, starts playback.
    -- alt_g + stop/start stops all grid_pattern playback.
    if state == 1 then
      if alt_g == 1 then
        stop_all_pat()
      elseif get_grid_pat().play == 0 and get_grid_pat().count > 0 then
        if get_grid_pat().rec == 1 then
          get_grid_pat():rec_stop()
        end
        get_grid_pat():start()
        set_base_time()
      elseif get_grid_pat().play == 1 then
        get_grid_pat():stop()
      end
    end
  -- alt_g button
  elseif y == 3 and x == 6 then
    alt_g = state
  -- track select buttons
  -- alt_g + track select button stops track.
  elseif x == 1 then
    if state == 1 then
      if alt_g == 1 then
        if grid_pattern[y].play == 1 then
          grid_pattern[y]:stop()
        else
          grid_pattern[y]:start()
        end
      else
        current_g_pat = y
      end
    end
  elseif x >= 3 and x <= 6 then
    if y == 5 or y == 6 then
    -- this is the drum pad grid.
      local grid_e = {}
      grid_e.id = x*8 + y
      grid_e.x = x
      grid_e.y = y
      grid_e.state = state
      trig(grid_e)
      if get_grid_pat().rec == 1 then
        get_grid_pat():watch(grid_e)
      end
    end
  end
  if alt_g == 1 then
    -- timing and speed controls for grid
    if x == 9 then
      if state == 1 then
        if is_linearized[y] == 1 then
          is_linearized[y] = 0
          restore_time(y)
        else
          linearize_pat(y)
          is_linearized[y] = 1
        end
      end
    elseif x == 13 and y == 3 then
      speed_up_playback()
    elseif x == 14 and y == 4 then
      speed_up_time()
    elseif x == 13 and y == 5 then
      slow_down_playback()
    elseif x == 12 and y == 4 then
      slow_down_time()
    elseif x == 11 and y == 6 then
      for i = 1, 8 do
        restore_time(i)
      end
    elseif x == 15 and y == 6 then
      restore_playback()
    end
  end
gridredraw()
end


function gridredraw()
  g.all(0)
  -- rec button.
  if get_grid_pat().rec == 1 then
    g.led(3, 3, 10)
  elseif get_grid_pat().count > 0 then
    g.led(3, 3, 6)
  else
    g.led(3, 3, 3)
  end
  -- start/stop button
  if get_grid_pat().play == 1 then
    g.led(4, 3, 6)
  else
    g.led(4, 3, 3)
  end
  -- alt_g
  if alt_g == 1 then
    g.led(6, 3, 6)
  else
    g.led(6, 3, 3)
  end
  -- tracks
  for i = 1, 8 do
    if current_g_pat == i then
      g.led(1, i, 10)
    elseif grid_pattern[i].count > 0 then
      g.led(1, i, 6)
    else
      g.led(1, i, 3)
    end
  end
  -- drum pads
  for i = 3, 6 do
    g.led(i, 5, 4)
    g.led(i, 6, 4)
  end
  for i, e in pairs(lit) do
    if e.state == 1 then
      g.led(e.x, e.y, 10)
    else
      g.led(e.x, e.y, 4)
    end
  end
  -- grid_pattern linearize buttons
  if alt_g == 1 then
    for i = 1, 8 do
      if is_linearized[i] == 1 then
        g.led(9, i, 8)
      else
        g.led(9, i, 4)
      end
    end
    -- time/ playback speed controls
    g.led(13, 3, 4)
    g.led(12, 4, 4)
    g.led(14, 4, 4)
    g.led(13, 5, 4)
    g.led(11, 6, 4)
    g.led(15, 6, 4)
  end
  g:refresh()
end


function redraw()
  screen.clear()
  screen.aa(1)
  if mode == 0 then
  -- grid mode
    screen.font_face(4)
    screen.font_size(13)
    screen.move(64, 60)
    if last_enc == 1 then
      if check_time() then
        if alt_k == 1 then
          screen.text_center("distortion : " .. string.format("%.2f", params:get("1_dist")))
        else
          screen.text_center("vol : " .. string.format("%.2f", mix:get("output")))
        end
      end

    elseif last_enc == 2 then
      if check_time() then
        if alt_k == 1 then
          screen.text_center("delay level : " .. string.format("%.2f", params:get("delay_level")))
        else
          screen.text_center("delay time : " .. string.format("%.2f", params:get("delay_time")))
        end
      end

    elseif last_enc == 3 then
      if check_time() then
        if alt_k == 1 then
          screen.text_center("delay send : " .. string.format("%.2f", params:get("1_delay_send")))
        else
          screen.text_center("delay feedback : " .. string.format("%.2f", params:get("delay_feedback")))
        end
      end
    end

    screen.stroke()
    screen_fuzz()
    screen.update()
else
-- encoder mode
    screen.level(10)
    screen.move(0, 48)
    screen.font_size(21)
    screen.font_face(4)
    screen.text("CC ")
    screen.move(35, 48)
    screen.text(cc_page)
    screen.move(60, 32)
    screen.font_size(12)
    screen.font_face(5)
    screen.text("value  ")
    screen.move(60, 45)
    screen.text("count ")
    screen.move(60, 58)
    screen.text("step   ")
    screen.move(92, 32)
    screen.font_size(10)
    screen.font_face(6)
    screen.text(" :  " .. cc_val[cc_page])
    screen.move(92, 45)
    screen.text(" :  " .. enc_pattern[cc_page].count)
    screen.move(92, 58)
    screen.text(" :  " .. enc_pattern[cc_page].step)
    -- transport control icons
    draw_stop()
    draw_play()
    draw_record()
    screen.update()
  end
end
