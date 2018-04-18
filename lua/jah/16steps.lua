-- @name 16steps
-- @version 0.1.0
-- @author jah
-- @txt 16x8 step sequencer

ControlSpec = require 'controlspec'
Control = require 'control'
Scroll = require 'jah/scroll' -- TODO: not yet used

-- TODO: refactor so that 16steps and 8steps uses the same core

engine.name = 'Step'

local TRIG_LEVEL = 15
local PLAYPOS_LEVEL = 7
local CLEAR_LEVEL = 0

-- specs
tempo_spec = ControlSpec.new(20, 300, 'lin', 0, 120, "BPM")
swing_amount_spec = ControlSpec.new(0, 100, 'lin', 0, 0, "%")

-- params
local swing_amount = Control.new("Swing", swing_amount_spec)
local tempo = Control.new("Tempo", tempo_spec)

-- state
local width = 16
local height = 8
local playpos = nil
local playing = false

local trigs = {}
for i=1,width*height do trigs[i] = false end

local refresh_trig_on_grid = function(x, y) -- TODO: naming, this is not really refresh but intermediate update
  if g then
    if trigs[y*width+x] then
      g:led(x, y, TRIG_LEVEL)
    elseif x-1 == playpos then
      g:led(x, y, PLAYPOS_LEVEL)
    else
      g:led(x, y, CLEAR_LEVEL)
    end
    g:refresh()
  end
end

local refresh_trig_col_on_grid = function(x) -- TODO: naming, this is not really refresh but intermediate update
  for y=1,height do
    refresh_trig_on_grid(x, y)
  end
end

local trig_is_unset = function(x, y)
  return trigs[y*width+x] == false
end

local trig_is_set = function(x, y)
  return trigs[y*width+x]
end

local playpos_callback = function(new_playpos)
  if playpos ~= new_playpos then
    local previous_playpos = playpos
    playpos = new_playpos
    if previous_playpos then
      refresh_trig_col_on_grid(previous_playpos+1)
    end
    if playpos then
      refresh_trig_col_on_grid(playpos+1)
    end
    if g then
      g:refresh()
    end
  end
end

local start_playpos_poll = function()
  print('starting playpos poll in step')
  p = poll.set('playpos', playpos_callback)
  p.time = 0.02;
  p:start()
end

-- init function
init = function()
  -- print to command line
  print("step!")
  -- add log message
  norns.log.post("hello from step!")
  -- set engine params
  engine.setNumSteps(width)
  engine.setTempo(tempo:get())
  engine.setSwingAmount(swing_amount:get())
  engine.stopSequencer()
  engine.clearAllTrigs()
  -- clear grid, if it exists
  if g then
    g:all(0)
    g:refresh()
  end
  start_playpos_poll()
end

-- encoder function
enc = function(n, delta)
  if n == 1 then
    norns.audio.adjust_output_level(delta)
  elseif n == 2 then
    tempo:delta(delta)
    engine.setTempo(tempo:get())
  elseif n == 3 then
    swing_amount:delta(delta)
    engine.setSwingAmount(swing_amount:get())
  end
  redraw()
end

-- key function
key = function(n, z)
  if n == 2 and z == 1 then
    -- engine.clearPattern()
    engine.stopSequencer()
    playing = false
  elseif n == 3 and z == 1 then
    -- engine.scrambleSamples()
    engine.playSequencer()
    playing = true
  end
  redraw()
end

-- screen redraw function
redraw = function()
  -- clear screen
  screen.clear()
  -- set pixel brightness (0-15)
  screen.level(15)

  -- show timer
  screen.move(0,8)
  screen.text("16STEPS")

  screen.move(0, 24)
  screen.text("Tempo: "..tempo:get().."BPM")
  screen.move(0, 32)
  screen.text("Swing: "..swing_amount:get().."%")
  screen.move(0, 48)
  if playing then
    screen.text("Playing")
  else
    screen.text("Stopped")
  end
  screen.update()
end

-- grid key function
gridkey = function(x, y, state)
  if state > 0 then
    if trig_is_set(x, y) then
      engine.clearTrig(y-1, x-1)
      trigs[y*width+x] = false
      refresh_trig_on_grid(x, y)
    else
      engine.setTrig(y-1, x-1)
      trigs[y*width+x] = true
      refresh_trig_on_grid(x, y)
    end
    if g then
      g:refresh()
    end
  end
end

-- called on script quit, release memory
cleanup = function()
  if g then
    g:all(0)
    g:refresh()
  end
end
