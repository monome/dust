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
-- if holding the sequence load
-- button (15, 1), each of the 16
-- pads represent a sequence.
-- sequence loading happens on the
-- "next step" by default, but
-- can be configured to
-- "last step" in PARAMETERS.
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
-- v1.1 justmat

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

local current_seq = 1
local current_step = 1
local next_seq = nil

local black_keys = {}
local note_name = nil
local last_note_name = nil
local last_enc = nil
local time_last = 0
local clear_hold_time = 0
local time_last_enc = 0

local alt = false
local playing = false
local record_mode = false
local enc_sel_mode = false
local seq_load_mode = false
local step_edit_mode = false
local end_of_seq_change = false


local engine_enc_choices = {
  "amp",
  "pw",
  "release",
  "cutoff",
  "gain"
}

local seq_enc_choices = {
  "bpm",
  "length"
  -- swing
}

local current_enc1 = 1
local current_enc2 = 4
local current_enc3 = 3

local seq_data = {}
for j = 1, 16 do
  seq_data[j] = {}
  for i = 1, 16 do
    seq_data[j][i] = {
    note_num = nil,
    prob = 100
  }
  end
  seq_data[j].steps = 16
end


local function note_from_grid(x, y)
  local note = ((7 - y) * 5) + x + 36
  return note
end


local function current_note_name()
  local num = seq_data[current_seq][current_step].note_num
  local name = music_util.note_num_to_name(num, 1)
  return name
end


local function trig(note)
  if math.random(100) <= seq_data[current_seq][current_step].prob then
    engine.hz(music_util.note_num_to_freq(note))
    last_note_name = music_util.note_num_to_name(note)
  end
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


function init()
  screen.aa(0)
  screen.line_width(1)

  clk.on_step = step
  clk.on_select_internal = function() end
  clk.on_select_external = reset_pattern
  clk:add_clock_params()
  params:add_separator()

  params:add_option("seq_change","seq change", {"next step", "last step"}, 1)
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

  if playing then
    clk:start()
  else clk:stop() end

  params:read("justmat/paths.pset")
  params:bang()
end


function step()
  if current_step == seq_data[current_seq].steps and end_of_seq_change then
    current_seq = next_seq
    end_of_seq_change = false
  end

  if seq_data[current_seq][current_step].note_num then
    trig(seq_data[current_seq][current_step].note_num)
  end

  current_step = current_step + 1
  if current_step > seq_data[current_seq].steps then
    current_step = 1
  end
end


function key(n, z)
  if n == 1 and z == 1 then
    time_last = util.time()
    if util.time() - time_last <= 1.0 then
      step_edit_mode = not step_edit_mode
    end
  end

  if n == 2 and z == 1 then
    enc_sel_mode = true
  else
    enc_sel_mode = false
  end

  if n == 3 and z == 1 then
    if not playing and not step_edit_mode then
      clk:start()
      playing = true
    else
      clk:stop()
      playing = false
    end
  end
end


function enc(n, d)
  if n == 1 then
    if step_edit_mode then
      current_step = util.clamp(current_step + d, 1, seq_data[current_seq].steps)
    elseif enc_sel_mode then
      current_enc1 = util.clamp(current_enc1 + d, 1, 2)
    elseif current_enc1 == 2 then
      seq_data[current_seq].steps = util.clamp(seq_data[current_seq].steps + d, 1, 16)
    else
      params:delta("bpm", d)
    end
    last_enc = 1
    time_last_enc = util.time()
  end

  if n == 2 then
    if step_edit_mode then
      seq_data[current_seq][current_step].prob = util.clamp(seq_data[current_seq][current_step].prob + d, 0, 100)
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
      if seq_data[current_seq][current_step].note_num then
        seq_data[current_seq][current_step].note_num = util.clamp(seq_data[current_seq][current_step].note_num + d, 0, 127)
      else
        seq_data[current_seq][current_step].note_num = 0
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
  -- y = 1 is the control row
  if y == 1 then
    if x == 1 then
      if z == 1 then
        if not playing and not step_edit_mode then
          if record_mode then
            record_mode = false
            seq_data[current_seq].steps = util.clamp(current_step - 1, 1, 16)
          end
          clk:start()
          playing = true
        else
          clk:stop()
          playing = false
        end
      end
    -- record mode
    elseif x == 2 and z == 1 and not step_edit_mode then
      if record_mode then
        record_mode = false
      else record_mode = true end
    -- clear sequence/ return to init state
    elseif x == 13 then
      if z == 1 then
        clear_hold_time = util.time()
      else
        if util.time() - clear_hold_time > 3.0 then
            for i = 1, 16 do
              seq_data[current_seq][i].note_num = nil
              seq_data[current_seq][i].prob = 100
          end
          seq_data[current_seq].steps = 16
          clk:stop()
          playing = false
          current_step = 1
        end
      clear_hold_time = 0.0
      end
    -- sequence load mode
    elseif x == 15 then
      if z == 1 then
        seq_load_mode = true
      else
        seq_load_mode = false
      end
    -- step edit mode
    elseif x == 16 and z == 1 then
      if not playing and not record_mode then
        if step_edit_mode then
          step_edit_mode = false
        else step_edit_mode = true end
      end
    end
  end
  -- y == 2 is the playbar
  if y == 2 and z == 1 then
    if record_mode and not playing then
      if x == current_step then
        seq_data[current_seq][x].note_num = nil
        current_step = current_step + 1
        if current_step > seq_data[current_seq].steps then
          current_step = 1
        end
      end
    else
      if seq_load_mode then
        if params:get('seq_change') == 1 then
          current_seq = x
        else
          end_of_seq_change = true
          next_seq = x
        end
      else
        current_step = x
      end
    end
  -- y == 3 or greater is the keybed
  elseif y >= 3 then
    if z == 1 and not step_edit_mode then
      trig(note_from_grid(x, y))
      time_last = util.time()
      if record_mode then
        seq_data[current_seq][current_step].note_num = note_from_grid(x, y)
        if not playing  then
          current_step = current_step + 1
        end
        if current_step > seq_data[current_seq].steps then current_step = 1 end
      end
    end
  end
end


function redraw()
  screen.clear()
  -- top bar
  screen.move(5, 9)
  screen.level(10)
  if step_edit_mode then
    screen.text("step : " .. current_step )
    screen.move(85, 9)
    screen.text("prob : " .. seq_data[current_seq][current_step].prob)
  else
    screen.text("bpm : " .. params:get("bpm"))
    screen.move(123, 9)
    if last_enc == 1 and current_enc1 == 2 then
      if util.time() - time_last_enc < .6 then
        screen.text_right(seq_data[current_seq].steps)
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
  else screen.text("1. " .. seq_enc_choices[current_enc1]) end

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
    if seq_data[current_seq][current_step].note_num then
      screen.text(current_note_name())
    end
  end
  if playing then
    if seq_data[current_seq][current_step].note_num then
      screen.text(current_note_name())
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

  if clear_hold_time > 0.0 then
    g.led(13, 1, 8)
  else g.led(13, 1, 3) end

  if seq_load_mode then
    g.led(15, 1, 8)
  else g.led(15, 1, 3) end

  if step_edit_mode then
    g.led(16, 1, 8)
  else g.led(16, 1, 3) end

  for i = 1, seq_data[current_seq].steps do
    if i == current_step then
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
