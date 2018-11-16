-- awake: time changes
-- (grid optional)
--
-- top sequence plays.
-- bottom sequence adds
-- modifies note played.
--
-- ENC1 = tempo
-- ENC2 = nav
-- ENC3 = edit
-- KEY2 = morph
-- KEY3 = toggle edit
--
-- KEY3 hold + KEY2 = reset pos
-- KEY3 hold + ENC1 = transpose
-- KEY3 hold + ENC2/3 = lengths
--
-- KEY1 hold = ALT
-- ALT+ENC1 = scale mode
-- ALT+ENC2 = filter
-- ALT+ENC3 = release
-- ALT+KEY2 = play/pause
--
-- modify sound params in
-- SYSTEM > AUDIO menu

engine.name = 'PolyPerc'

local MusicUtil = require "mark_eats/musicutil"

local options = {}
options.OUTPUT = {"audio", "midi", "audio + midi"}
options.STEP_LENGTH_NAMES = {"1 bar", "1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16", "1/24", "1/32", "1/48", "1/64"}
options.STEP_LENGTH_DIVIDERS = {1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64}

local g = grid.connect()

local KEY3 = false
local alt = false

local one = {
  pos = 0,
  length = 8,
  data = {0,0,6,4,7,3,0,0,0,0,0,0,0,0,0,0}
}
local two = {
  pos = 0,
  length = 7,
  data = {6,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
}

local midi_out_device
local midi_out_channel

local scale_names = {}
local notes = {}
local active_notes = {}

local edit_mode = 1
local edit_pos = 1

local BeatClock = require 'beatclock'
local clk = BeatClock.new()
local clk_midi = midi.connect()
clk_midi.event = function(data)
  clk:process_midi(data)
end

local notes_off_metro = metro.alloc()

local function build_scale()
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 16)
  local num_to_add = 16 - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[16 - num_to_add])
  end
end

local function all_notes_off()
  if (params:get("output") == 2 or params:get("output") == 3) then
    for _, a in pairs(active_notes) do
      midi_out_device.note_off(a, nil, midi_out_channel)
    end
  end
  active_notes = {}
end

local function step()
  
  all_notes_off()
  
  one.pos = one.pos + 1
  if one.pos > one.length then one.pos = 1 end
  two.pos = two.pos + 1
  if two.pos > two.length then two.pos = 1 end
  
  if one.data[one.pos] > 0 then
    local note_num = notes[one.data[one.pos]+two.data[two.pos]]
    local freq = MusicUtil.note_num_to_freq(note_num)
    
    -- Audio engine out
    if params:get("output") == 1 or params:get("output") == 3 then
      engine.hz(freq)
    end
    
    -- MIDI out
    if (params:get("output") == 2 or params:get("output") == 3) then
      midi_out_device.note_on(note_num, 96, midi_out_channel)
      table.insert(active_notes, note_num)
    end
    
    -- Note off timeout
    if params:get("note_length") < 4 then
      notes_off_metro:start((60 / clk.bpm / clk.steps_per_beat / 4) * params:get("note_length"), 1)
    end
  end
  
  if g then
    gridredraw()
  end
  redraw()
  
end

local function stop()
  all_notes_off()
end

local function reset_pattern()
  one.pos = 0
  two.pos = 0
  clk:reset()
end

function init()
  
  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
  end
  
  midi_out_device = midi.connect(1)
  midi_out_device.event = function() end
  
  clk.on_step = step
  clk.on_stop = stop
  clk.on_select_internal = function() clk:start() end
  clk.on_select_external = reset_pattern
  clk:add_clock_params()
  params:set("bpm", 92)
  
  notes_off_metro.callback = all_notes_off
  
  params:add{type = "option", id = "output", name = "output",
    options = options.OUTPUT,
    action = all_notes_off}
  params:add{type = "number", id = "midi_out_device", name = "midi out device",
    min = 1, max = 4, default = 1,
    action = function(value) midi_out_device:reconnect(value) end}
  params:add{type = "number", id = "midi_out_channel", name = "midi out channel",
    min = 1, max = 16, default = 1,
    action = function(value)
      all_notes_off()
      midi_out_channel = value
    end}
  params:add_separator()
  
  params:add{type = "option", id = "step_length", name = "step length", options = options.STEP_LENGTH_NAMES, default = 6,
    action = function(value)
      clk.ticks_per_step = 96 / options.STEP_LENGTH_DIVIDERS[value]
      clk.steps_per_beat = options.STEP_LENGTH_DIVIDERS[value] / 4
      clk:bpm_change(clk.bpm)
    end}
  params:add{type = "option", id = "note_length", name = "note length",
    options = {"25%", "50%", "75%", "100%"},
    default = 4}
  
  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 1,
    action = function() build_scale() end}
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 45, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end}
  params:add_separator()

  cs_AMP = controlspec.new(0,1,'lin',0,0.5,'')
  params:add{type="control",id="amp",controlspec=cs_AMP,
    action=function(x) engine.amp(x) end}

  cs_PW = controlspec.new(0,100,'lin',0,50,'%')
  params:add{type="control",id="pw",controlspec=cs_PW,
    action=function(x) engine.pw(x/100) end}

  cs_REL = controlspec.new(0.1,3.2,'lin',0,1.2,'s')
  params:add{type="control",id="release",controlspec=cs_REL,
    action=function(x) engine.release(x) end}

  cs_CUT = controlspec.new(50,5000,'exp',0,555,'hz')
  params:add{type="control",id="cutoff",controlspec=cs_CUT,
    action=function(x) engine.cutoff(x) end}

  cs_GAIN = controlspec.new(0,4,'lin',0,1,'')
  params:add{type="control",id="gain",controlspec=cs_GAIN,
    action=function(x) engine.gain(x) end}

  params:read("tehn/awake.pset")
  params:bang()

  clk:start()

end

function g.event(x, y, z)
  local grid_h = g.rows()
  if z > 0 then
    if (grid_h == 8 and edit_mode == 1) or (grid_h == 16 and y <= 8) then
      if one.data[x] == 9-y then
        one.data[x] = 0
      else
        one.data[x] = 9-y
      end
    end
    if (grid_h == 8 and edit_mode == 2) or (grid_h == 16 and y > 8) then
      if grid_h == 16 then y = y - 8 end
      if two.data[x] == 9-y then
        two.data[x] = 0
      else
        two.data[x] = 9-y
      end
    end
    gridredraw()
    redraw()
  end
end

function gridredraw()
  local grid_h = g.rows()
  g.all(0)
  if edit_mode == 1 or grid_h == 16 then
    for x = 1, 16 do
      if one.data[x] > 0 then g.led(x, 9-one.data[x], 5) end
    end
    if one.pos > 0 and one.data[one.pos] > 0 then
      g.led(one.pos, 9-one.data[one.pos], 15)
    else
      g.led(one.pos, 1, 3)
    end
  end
  if edit_mode == 2 or grid_h == 16 then
    local y_offset = 0
    if grid_h == 16 then y_offset = 8 end
    for x = 1, 16 do
      if two.data[x] > 0 then g.led(x, 9-two.data[x] + y_offset, 5) end
    end
    if two.pos > 0 and two.data[two.pos] > 0 then
      g.led(two.pos, 9-two.data[two.pos] + y_offset, 15)
    else
      g.led(two.pos, 1 + y_offset, 3)
    end
  end
  g.refresh()
end

function enc(n, delta)
  if alt and n==1 then
    params:delta("scale_mode", delta)
  elseif KEY3 and n==1 then
    params:delta("root_note", delta)
  elseif n == 1 then
    params:delta("bpm", delta)
  elseif alt and n == 2 then
    params:delta("cutoff", delta)
  elseif alt and n == 3 then
    params:delta("release", delta)
  elseif KEY3 and n==2 then
    one.length = util.clamp(one.length+delta,1,16)
  elseif KEY3 and n==3 then
    two.length = util.clamp(two.length+delta,1,16)
  elseif n==3 then
    if edit_mode == 1 then
      one.data[edit_pos] = util.clamp(one.data[edit_pos]+delta,0,8)
    else
      two.data[edit_pos] = util.clamp(two.data[edit_pos]+delta,0,8)
    end
  elseif n==2 then
    local p = (edit_mode == 1) and one.length or two.length
    edit_pos = util.clamp(edit_pos+delta,1,p)
  end
  redraw()
end

function key(n,z)
  if n==1 then
    alt = z==1
  elseif n == 3 and z == 1 then
    KEY3 = true
    if edit_mode == 1 then
      edit_mode = 2
      if edit_pos > two.length then edit_pos = two.length end
    else
      edit_mode = 1
      if edit_pos > one.length then edit_pos = one.length end
    end
  elseif n==3 and z==0 then
    KEY3 = false
  elseif n == 2 and z == 1 then
    if KEY3 then
      reset_pattern()
      gridredraw()
    elseif alt then
      if not clk.external then
        if clk.playing then
          clk:stop()
        else
          clk:start()
        end
      end
    else
      if edit_mode == 1 then
        for i=1,one.length do
          if one.data[i] > 0 then
            one.data[i] = util.clamp(one.data[i]+math.floor(math.random()*3)-1,0,8)
          end
        end
      else
        for i=1,two.length do
          if two.data[i] > 0 then
            two.data[i] = util.clamp(two.data[i]+math.floor(math.random()*3)-1,0,8)
          end
        end
      end
      gridredraw()
    end
  end
  redraw()
end

function redraw()
  screen.clear()
  screen.line_width(1)
  screen.aa(0)
  screen.move(26 + edit_pos*6, edit_mode==1 and 33 or 63)
  screen.line_rel(4,0)
  screen.level(15)
  screen.stroke()
  screen.move(32,30)
  screen.line_rel(one.length*6-2,0)
  screen.level(2)
  screen.stroke()
  screen.move(32,60)
  screen.line_rel(two.length*6-2,0)
  screen.level(2)
  screen.stroke()
  for i=1,one.length do
    if one.data[i] > 0 then
      screen.move(26 + i*6, 30 - one.data[i]*3)
      screen.line_rel(4,0)
      screen.level(i == one.pos and 15 or (edit_mode == 1 and 4 or 1))
      screen.stroke()
    end
  end
  for i=1,two.length do
    if two.data[i] > 0 then
      screen.move(26 + i*6, 60 - two.data[i]*3)
      screen.line_rel(4,0)
      screen.level(i == two.pos and 15 or (edit_mode == 2 and 4 or 1))
      screen.stroke()
    end
  end
  screen.level((not alt and not KEY3) and 15 or 4)
  screen.move(0,10)
  screen.text("bpm:"..params:get("bpm"))
  screen.level(alt and 15 or 4)
  screen.move(0,20)
  screen.text("sc:"..params:get("scale_mode"))
  screen.level(KEY3 and 15 or 4)
  screen.move(0,30)
  screen.text("rt:"..MusicUtil.note_num_to_name(params:get("root_note"), true))

  screen.level(4)
  screen.move(0,60)
  if alt then screen.text("cut/rel")
  elseif KEY3 then screen.text("loop") end
  screen.update()
end

function cleanup ()
  clk:stop()
end
