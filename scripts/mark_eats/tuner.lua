-- Tuner
--
-- Responds to audio input.
--
-- ENC3 : Reference note
--
-- v1.0.1 Mark Eats
--

local ControlSpec = require "controlspec"
local MusicUtil = require "mark_eats/musicutil"
local Formatters = require "jah/formatters"

engine.name = "TestSine"

local SCREEN_FRAMERATE = 15
local screen_dirty = true

local current_freq = -1
local last_freq = -1


-- Encoder input
function enc(n, delta)
  
  if n == 2 then
          
  elseif n == 3 then
    params:delta("note_vol", delta)
  end
end

-- Key input
function key(n, z)
  if z == 1 then
    if n == 2 then
      
    elseif n == 3 then
      
    end
  end
end


local function update_freq(freq)
  current_freq = freq
  if current_freq > 0 then last_freq = current_freq end
  screen_dirty = true
end


function init()
  
  engine.amp(0)
  
  -- Add params
  
  params:add{type = "option", id = "in_channel", name = "In Channel", options = {"Left", "Right"}}
  params:add{type = "option", id = "note", name = "Note", options = MusicUtil.NOTE_NAMES, default = 10, action = function(value)
    engine.hz(MusicUtil.note_num_to_freq(59 + value))
    screen_dirty = true
  end}
  params:add{type = "control", id = "note_vol", name = "Note Volume", controlspec = ControlSpec.UNIPOLAR, action = function(value)
    engine.amp(value)
    screen_dirty = true
  end}
  
  params:bang()
  
  -- Polls
  
  local pitch_poll_l = poll.set("pitch_in_l", function(value)
    if params:get("in_channel") == 1 then
      update_freq(value)
    end
  end)
  pitch_poll_l:start()
  
  local pitch_poll_r = poll.set("pitch_in_r", function(value)
    if params:get("in_channel") == 2 then
      update_freq(value)
    end
  end)
  pitch_poll_r:start()
  
  local screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  screen.aa(1)
end


function redraw()
  screen.clear()
  
  -- Draw rules
  
  for i = 1, 11 do
    local x = util.round(12.7 * (i - 1)) + 0.5
    if i == 6 then
      if current_freq > 0 then screen.level(15)
      else screen.level(3) end
      screen.move(x, 24)
      screen.line(x, 35)
    else
      if current_freq > 0 then screen.level(3)
      else screen.level(1) end
      screen.move(x, 29)
      screen.line(x, 35)
    end
    screen.stroke()
  end
  
  -- Draw last freq line
  
  local note_num = MusicUtil.freq_to_note_num(last_freq)
  local freq_x
  if last_freq > 0 then
    freq_x = util.explin(math.max(MusicUtil.note_num_to_freq(note_num - 0.5), 0.00001), MusicUtil.note_num_to_freq(note_num + 0.5), 0, 128, last_freq)
    freq_x = util.round(freq_x) + 0.5
  else
    freq_x = 64.5
  end
  if current_freq > 0 then screen.level(15)
  else screen.level(3) end
  screen.move(freq_x, 29)
  screen.line(freq_x, 40)
  screen.stroke()
  
  -- Draw text
  
  screen.move(64, 19)
  if current_freq > 0 then screen.level(15)
  else screen.level(3) end
  
  if last_freq > 0 then
    screen.text_center(MusicUtil.note_num_to_name(note_num, true))
  end
  
  if last_freq > 0 then
    screen.move(64, 50)
    if current_freq > 0 then screen.level(3)
    else screen.level(1) end
    screen.text_center(Formatters.format_freq_raw(last_freq))
  end
  
  -- Draw ref note
  
  screen.move(128, 8)
  screen.level(util.round(params:get("note_vol") * 15))
  screen.text_right(params:string("note"))
  
  screen.fill()
  
  screen.update()
end
