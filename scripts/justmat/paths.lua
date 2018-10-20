--
-- a step sequencer
--
-- ----------
--
-- enc1 - bpm
-- enc2 - cutoff
-- enc3 - release
--
-- hold key1 for 1 sec to
-- access step edit mode.
-- hold key1 again to return
-- to normal use.
--
-- hold key2 and turn an
-- encoder to change the
-- encoders function.
--
-- key3 - start/stop
--
-- ----------
--
-- grid
--
-- row 1 is the control
-- row.
--
-- 1,1 - play/stop
-- 2,1 - rec
-- 
-- 6, 1 through 9, 1 select
-- paths(tracks) 1-4.
--
-- 13, 1 - hold to clear sequence
-- 15, 1 - load sequence
-- 16, 1 - step edit mode
--
-- ----------
--
-- row 2 is a multi-use row.
-- if playing its function is
-- "jump to step".
--
-- if recording, touching your
-- current position on row 2 will
-- input a rest.
--
-- ----------
--
-- if holding the sequence load
-- button (15, 1), each of the 16
-- pads on row 4 represent a
-- sequence. sequence loading 
-- happens on the "next step"
-- by default, but can be
-- configured to "last step"
-- in PARAMETERS.
--
-- ----------
--
-- row 3 and greater are an
-- earthsea style keyboard.
--
-- there is an option in
-- PARAMETERS to enable keybed
-- highlighting of the black keys.
-- (thanks to @ypxkap)
--
-- ----------
--
-- ---TODO---
--
-- midi output.
-- change engine.
-- pattern meta sequencing.
-- saving/loading.
-- proper docs.
-- 
-- ----------
--
-- v1.2 justmat

engine.name = "PolyPerc"

local g = grid.connect(1)

local music_util = require 'mark_eats/musicutil'
local cs = require 'controlspec'

local bc = require 'beatclock'
local clk = bc.new()
local clk_midi = midi.connect(1)
clk_midi.event = function(data)
  clk:process_midi(data)
end

local note_name = nil
local last_note_name = nil
local last_enc = nil
local time_last = 0
local clear_hold_time = 0
local time_last_enc = 0

local alt = false
local record_mode = false
local enc_sel_mode = false
local step_edit_mode = false
local black_keys_flag = false

local current_enc1 = 1
local current_enc2 = 4
local current_enc3 = 3

-- tables galore 

local black_keys = {}

local engine_enc_choices = {
  "amp",
  "pw",
  "release",
  "cutoff",
  "gain"
}

local pat_enc_choices = {
  "bpm",
  "steps"
}

local current_path = 1

local paths = {}
for i = 1, 4 do
  paths[i] = {
    playing = false,
    end_of_pat_change = false,
    pat_load_mode = false,
    current_pat = 1,
    next_pat = nil,
    current_step = 1
  }
end

local patterns = {}
for j = 1, 4 do
  patterns[j] = {}
  for i = 1, 16 do
    patterns[j][i] = {
      has_data = false,
      steps = 16
    }
  end
end

local steps = {}
for j = 1, 4 do
  steps[j] = {}
  for i = 1, 16 do
    steps[j][i] = {
    note_number = nil,
    prob = 100
  }
  end
end

-- helper functions

local function note_from_grid(x, y)
  local note = ((7 - y) * 5) + x + 36
  return note
end


local function trig(note)
  for i = 1, 4 do
    if paths[i].playing then
      if math.random(100) <= steps[i][paths[i].current_step].prob then
        engine.hz(music_util.note_num_to_freq(note))
        last_note_name = music_util.note_num_to_name(note)
      end
    end
  end
end


local function get_current_step()
  return steps[current_path][paths[current_path].current_step]
end


local function get_current_pat()
  return patterns[current_path][paths[current_path].current_pat]
end


local function keybed_leds()
  for y = 3, 8 do
    for x = 1, 16 do
      local note = music_util.note_num_to_name(note_from_grid(x, y), 1)
      if string.find(note, "%#") then
        table.insert(black_keys, {x, y})
      end
    end
  end
  return black_keys
end


local function reset_path(n)
  paths[n].current_step = 1
end


local function pattern_clear(t)
  if util.time() - t > 3.0 then
    for i = 1, 16 do
      get_current_step().note_num = nil
      get_current_step().prob = 100
    end
    get_current_pat().steps = 16
    paths[current_path].playing = false
    reset_path(current_path)
    get_current_pat().has_data = false
  end
end


function init()
  screen.aa(0)
  screen.line_width(1)

  clk.on_step = step
  clk.on_select_internal = function() end
  clk.on_select_external = reset_pattern
  clk:add_clock_params()
  params:add_separator()

  params:add_option("pat_change","pattern change", {"next step", "on one"}, 1)
  params:add_option("show_black_keys", "show black keys", {"no", "yes"}, 1)
  params:add_separator()

  cs.AMP = cs.new(0,1,'lin',0,0.5,'')
  params:add_control("amp","amp",cs.AMP)
  params:set_action("amp", function(x) engine.amp(x) end)

  cs.PW = cs.new(0,100,'lin',0,50,'%')
  params:add_control("pw","pw",cs.PW)
  params:set_action("pw", function(x) engine.pw(x/100) end)

  cs.REL = cs.new(0.1,3.2,'lin',0,1.2,'s')
  params:add_control("release","release",cs.REL)
  params:set_action("release", function(x) engine.release(x) end)

  cs.CUT = cs.new(50,5000,'exp',0,555,'hz')
  params:add_control("cutoff","cutoff",cs.CUT)
  params:set_action("cutoff", function(x) engine.cutoff(x) end)

  cs.GAIN = cs.new(0,4,'lin',0,1,'')
  params:add_control("gain","gain",cs.GAIN)
  params:set_action("gain", function(x) engine.gain(x) end)

  screen_refresh_timer = metro.alloc(function(stage) redraw() end, 1 / 15)
  screen_refresh_timer:start()

  grid_refresh_timer = metro.alloc(function(stage) grid_redraw() end, 1 / 15)
  grid_refresh_timer:start()
  
  black_keys = keybed_leds()

  clk:start()

  params:read("justmat/paths.pset")
  params:bang()
end


function step()
  if paths[current_path].current_step == 1 and paths[current_path].end_of_pat_change then
    paths[current_path].current_pat = paths[current_path].next_pat
    paths[current_path].end_of_pat_change = false
  end

  for i = 1, 4 do
    if patterns[i][paths[i].current_pat].has_data and paths[i].playing then
      if steps[i][paths[i].current_step].note_num then
        trig(steps[i][paths[i].current_step].note_num)
      end
    end
  end
  
  for i = 1, 4 do
    if paths[i].playing then
      paths[i].current_step = paths[i].current_step + 1
      if paths[i].current_step > patterns[i][paths[i].current_pat].steps then
        reset_path(i)
      end
    end
  end
end


function key(n, z)
  if n == 1 and z == 1 then
    time_last = util.time()
    if util.time() - time_last <= 1.0 and not paths[current_path].playing then
      step_edit_mode = not step_edit_mode
    end
  end

  if n == 2 and z == 1 then
    enc_sel_mode = true
  else
    enc_sel_mode = false
  end

  if n == 3 and z == 1 then
    if not paths[current_path].playing and not step_edit_mode then
      paths[current_path].playing = true
    else
      paths[current_path].playing = false
    end
  end
end


function enc(n, d)
  if n == 1 then
    if step_edit_mode then
      paths[current_path].current_step = util.clamp(paths[current_path].current_step + d, 1, get_current_pat().steps)
    elseif enc_sel_mode then
      current_enc1 = util.clamp(current_enc1 + d, 1, 2)
    elseif current_enc1 == 2 then
      get_current_pat().steps = util.clamp(get_current_pat().steps + d, 1, 16)
    else
      params:delta("bpm", d)
    end
    last_enc = 1
    time_last_enc = util.time()
  end

  if n == 2 then
    if step_edit_mode then
      get_current_step().prob = util.clamp(get_current_step().prob + d, 0, 100)
    elseif enc_sel_mode then
      current_enc2 = util.clamp(current_enc2 + d, 1, 5)
    else
      params:delta(engine_enc_choices[current_enc2], d)
    end
    last_enc = 2
    time_last_enc = util.time()
  end

  if n == 3 then
    if step_edit_mode then
      if get_current_step().note_num then
        get_current_step().note_num = util.clamp(get_current_step().note_num + d, 0, 127)
      else
        get_current_step().note_num = 0
      end
    elseif enc_sel_mode then
      current_enc3 = util.clamp(current_enc3 + d, 1, 5)
    else
      params:delta(engine_enc_choices[current_enc3], d)
    end
    last_enc = 3
    time_last_enc = util.time()
  end
end


function g.event(x, y, z)
  -- y = 1 is the control row 1,1 is start/stop
  if y == 1 then
    if x == 1 then
      if z == 1 then
        if not paths[current_path].playing and not step_edit_mode then
          if record_mode then
            record_mode = false
            get_current_pat().steps =  util.clamp(paths[current_path].current_step - 1, 1, 16)
          end
          paths[current_path].playing = true
        else
          paths[current_path].playing = false
        end
      end
    -- record mode
    elseif x == 2 and z == 1 and not step_edit_mode then
      if record_mode then
        record_mode = false
      else
        record_mode = true
      end
    -- path selection
    elseif x >= 6 and x <= 9 and z == 1 then
      current_path = x - 5
    -- clear sequence/ return to init state
    elseif x == 13 then
      if z == 1 then
        clear_hold_time = util.time()
      else
        pattern_clear(clear_hold_time)
        clear_hold_time = 0.0
      end
    -- sequence load mode
    elseif x == 15 then
      if z == 1 then
        paths[current_path].pat_load_mode = true
        if params:get("show_black_keys") == 2 then
          black_keys_flag = true
          params:set("show_black_keys", 1)
        end
      else
        paths[current_path].pat_load_mode = false
        if black_keys_flag then
          params:set("show_black_keys", 2)
          black_keys_flag = false
        end
      end
    -- step edit mode
    elseif x == 16 and z == 1 then
      if not paths[current_path].playing and not record_mode then
        if step_edit_mode then
          step_edit_mode = false
        else step_edit_mode = true end
      end
    end
  end
  -- y == 2 is the playbar
  if y == 2 and z == 1 then
    if record_mode and not paths[current_path].playing then
      for i = 1, 4 do
        if x == paths[current_path].current_step then
          get_current_step().note_num = nil
          paths[current_path].current_step = paths[current_path].current_step + 1
          if paths[current_path].current_step > get_current_pat().steps then
            reset_path(current_path)
          end
        end
      end
    else
      paths[current_path].current_step = x
    end
  -- y == 3 or greater is the keybed
  elseif y >= 3 and not paths[current_path].pat_load_mode then
    if z == 1 and not step_edit_mode then
      engine.hz(music_util.note_num_to_freq(note_from_grid(x, y)))
      last_note_name = music_util.note_num_to_name(note_from_grid(x, y))
      time_last = util.time()
      if record_mode then
        get_current_step().note_num = note_from_grid(x, y)
        get_current_pat().has_data = true
        if not playing  then
          paths[current_path].current_step = paths[current_path].current_step + 1
        end
        if paths[current_path].current_step > get_current_pat().steps then
          reset_path(current_path)
        end
      end
    end
  -- y == 4 is used for loading patterns
  elseif y == 4 and paths[current_path].pat_load_mode then
    if not paths[current_path].playing then
      paths[current_path].current_pat = x
      reset_path(current_path)
    elseif params:get('pat_change') == 1 then
      paths[current_path].current_pat = x
    elseif params:get('pat_change') == 2 then
      paths[current_path].end_of_pat_change = true
      paths[current_path].next_pat = x
    else
      paths[current_path].current_step = x
    end
  end
end


function redraw()
  screen.clear()
  -- top bar
  screen.move(5, 9)
  screen.level(10)
  if step_edit_mode then
    screen.text("step : " .. paths[current_path].current_step)
    screen.move(85, 9)
    screen.text("prob : " .. get_current_step().prob)
  else
    screen.text(params:get("bpm"))
    screen.move(123, 9)
    if last_enc == 1 and current_enc1 == 2 then
      if util.time() - time_last_enc < .6 then
        screen.text_right(get_current_pat().steps)
      end
    elseif last_enc == 2 then
      if util.time() - time_last_enc < .6 then
        screen.text_right(string.format("%.2f", params:get(engine_enc_choices[current_enc2])))
      end
    elseif last_enc == 3 then
      if util.time() - time_last_enc < .6 then
        screen.text_right(string.format("%.2f", params:get(engine_enc_choices[current_enc3])))
      end
    end
  end
  screen.move(2, 13)
  screen.line(128, 13)
  screen.stroke()
  -- encoder function selection
  screen.move(84, 25)
  if step_edit_mode then
    screen.text("1. step")
  else screen.text("1. " .. pat_enc_choices[current_enc1]) end

  screen.move(84, 40)
  if step_edit_mode then
    screen.text("2. prob ")
  else screen.text("2. " .. engine_enc_choices[current_enc2]) end

  screen.move(84, 55)
  if step_edit_mode then
    screen.text("3. note")
  else screen.text("3. " .. engine_enc_choices[current_enc3]) end
  -- boxes for days
  screen.level(2)
  screen.rect(82, 18, 46, 11)
  screen.rect(82, 33, 46, 11)
  screen.rect(82, 48, 46, 11)
  screen.stroke()
  -- current note name, but like really big.
  screen.move(0, 53)
  screen.font_size(39)
  screen.font_face(3)
  screen.level(10)
  if step_edit_mode then
    if get_current_step().note_num then
      local num = get_current_step().note_num
      local name = music_util.note_num_to_name(num, 1)
      screen.text(name)
    end
  
  elseif paths[current_path].playing then
    if get_current_step().note_num then
      local num = get_current_step().note_num
      local name = music_util.note_num_to_name(num, 1)
      screen.text(name)
    end
  else
    if last_note_name and util.time() - time_last < 0.5 then
      screen.text(last_note_name)
    end
  end
  -- back to normal
  screen.font_size(8)
  screen.font_face(0)
  -- clearing sequence
  if clear_hold_time > 0.0 then
    screen.clear()
    screen.move(64, 32)
    if util.time() - clear_hold_time > 3.0 then
      screen.text_center("release to clear.")
    else screen.text_center("clear sequence?") end
  end
  screen.update()
end


function grid_redraw()
  g.all(0)
  if not playing then
    g.led(1, 1, 8)
  else g.led(1, 1, 3) end

  if record_mode then
    g.led(2, 1, 8)
  else g.led(2, 1, 3) end

  for i = 1, 4 do
    if i == current_path then
      g.led(i + 5, 1, 8)
    else g.led(i + 5, 1, 3) end
  end
  
  if clear_hold_time > 0.0 then
    g.led(13, 1, 8)
  else g.led(13, 1, 3) end

  if paths[current_path].pat_load_mode then
    g.led(15, 1, 8)
    for i = 1, 16 do
      if i == paths[current_path].current_pat then
        g.led(i, 4, 8)
      elseif patterns[current_path][i].has_data then
        g.led(i, 4, 4)
      else
        g.led(i, 4, 2)
      end
    end
  else g.led(15, 1, 3) end

  if step_edit_mode then
    g.led(16, 1, 8)
  else g.led(16, 1, 3) end

  for i = 1, get_current_pat().steps do
    if i == paths[current_path].current_step then
      g.led(i, 2, 8)
    else
      g.led(i, 2, 3)
    end
  end
  
  if params:get("show_black_keys") == 2 then
    for _, t in pairs(black_keys) do
      g.led(t[1], t[2], 2)
    end
  end
  
  g.refresh()
end
