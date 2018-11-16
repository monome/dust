-- Scales Demo
--
-- Example scale generation
-- using MusicUtil.
-- 
-- ENC1 : Tempo
-- ENC2 : Root note
-- ENC3 : Scale
-- KEY2 : Play/Pause
-- KEY3 : Reset step
-- 

local MusicUtil = require "mark_eats/musicutil"

local root_note = 48
local scale_type = 1
local scale_notes = {}
local scale_note_names = {}
local scale_len = 0
local SCALES_LEN = #MusicUtil.SCALES

local tempo = 90
local step = 1
local step_increment = 1
local step_metro

engine.name = "PolyPerc"


local function init_scale()
  scale_notes = MusicUtil.generate_scale(root_note, scale_type, 1)
  scale_note_names = MusicUtil.note_nums_to_names(scale_notes)
  scale_len = #scale_notes
end

local function advance_step()
  if step >= scale_len then
    step = scale_len
    step_increment = -1
  elseif step == 1 then
    step_increment = 1
  end
  step = step + step_increment
  engine.hz(MusicUtil.note_num_to_freq(scale_notes[step]))
  redraw()
end

local function start_stop_metro()
  if step_metro.is_running then
    step_metro:stop()
  else
    engine.hz(MusicUtil.note_num_to_freq(scale_notes[step]))
    step_metro:start(60 / tempo / 4) --  16ths
  end
end


function init()
  
  engine.amp(0.5)
  
  init_scale()
  
  step_metro = metro.alloc()
  step_metro.callback = advance_step
  start_stop_metro()
  
  screen.aa(1)
  redraw()
end


function enc(n, delta)

  -- ENC1 tempo
  if n == 1 then
    tempo = util.clamp(tempo + delta, 60, 200)
    step_metro.time = 60 / tempo / 4
    
  -- ENC2 root note
  elseif n == 2 then
    root_note = util.clamp(root_note + delta, 36, 84)
    init_scale()
    
  -- ENC3 scale
  elseif n == 3 then
    scale_type = util.clamp(scale_type + delta, 1, SCALES_LEN)
    init_scale()
    
  end
  
  redraw()
  
end

function key(n, z)
  
  if z == 1 then
    
    -- KEY2 is play/pause
    if n == 2 then
      start_stop_metro()
   
    -- KEY3 is reset step
    elseif n == 3 then
      if step_metro.is_running then step_metro:stop() end
      step = 1
      step_increment = 1
    end
    
    redraw()
  
  end
end


function redraw()
  screen.clear()

  screen.level(15)
  
  -- Play/pause
  if step_metro.is_running then
    screen.move(116, 6.2)
    screen.line(123, 9.5)
    screen.line(116, 12.8)
    screen.close()
  else
    screen.rect(116, 6, 2, 7)
    screen.rect(120, 6, 2, 7)
  end
  screen.fill()
  
  -- Tempo
  screen.move(5, 12)
  screen.text(tempo .. " BPM")

  -- Scale name
  screen.move(5, 27)
  screen.text(MusicUtil.note_num_to_name(root_note, true) .. " " .. MusicUtil.SCALES[scale_type].name)

  -- Notes
  local x, y = 5, 52
  local cols = 8
  if scale_len > cols then
    cols =  util.round_up(scale_len * 0.5)
    y = y - 6
  end
  for i = 1, scale_len do
    if i == cols + 1 then x, y = 5, y + 12 end
    screen.move(x, y)
    if i == step then screen.level(15) else screen.level(3) end
    screen.text(scale_note_names[i])
    if string.len(scale_note_names[i]) > 1 then x = x + 16
    else x = x + 10 end
  end
   
  screen.update()
end
