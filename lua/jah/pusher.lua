-- @name pusher
-- @version 0.2.0
-- @author jah
-- @txt capture & playback a sound

ControlSpec = require 'controlspec'
Control = require 'control'
Scroll = require 'jah/scroll' -- TODO: not yet used

engine.name = 'Pusher'

local PAGE_FIRST = 1
local PAGE_RELEASE_TO_PLAY = 2
local PAGE_MASH = 3

local current_page = PAGE_FIRST

local PARAM_GROUP_POS = 1
local PARAM_GROUP_RATE = 2
local PARAM_GROUP_FILTER = 3
local PARAM_GROUP_MIX = 4
local PARAM_GROUP_DELAY = 5
local PARAM_GROUP_REVERB = 6

local current_param_group = PARAM_GROUP_POS

local speed_spec = ControlSpec.rate()
local delay_time_spec = ControlSpec.new(0.0001, 3, ControlSpec.WARP_EXP, 0, 0.3, "secs")
local decay_time_spec = ControlSpec.new(0, 100, ControlSpec.WARP_LIN, 0, 1, "secs")
local cutoff_spec = ControlSpec.new(20, 10000, ControlSpec.WARP_EXP, 0, 10000, "Hz")
local volume_spec = ControlSpec.new(-60, 0, ControlSpec.WARP_LIN, 0, -60, "dB")
local percentage_spec = ControlSpec.new(0, 100, ControlSpec.WARP_LIN, 0, 0, "%")
local resonance_spec = ControlSpec.new(0, 100, ControlSpec.WARP_LIN, 0, 13, "%")

local start_pos = Control.new("Start", percentage_spec)
local end_pos = Control.new("End", percentage_spec)
local speed = Control.new("Speed", speed_spec)
local cutoff = Control.new("Cutoff", cutoff_spec)
local resonance = Control.new("Resonance", resonance_spec)
local delay_send = Control.new("Delay Send", volume_spec)
local reverb_send = Control.new("Reverb Send", volume_spec)
local delay_time = Control.new("Delay Time", delay_time_spec)
local decay_time = Control.new("Decay Time", decay_time_spec)
local reverb_room = Control.new("Reverb Room", percentage_spec)
local reverb_damp = Control.new("Reverb Damp", percentage_spec)

set_defaults = function()
  start_pos:set_default()
  end_pos:set(1.0)
  speed:set_default()
  cutoff:set_default()
  resonance:set_default()
  delay_send:set_default()
  reverb_send:set_default()
  delay_time:set_default()
  decay_time:set_default()
  reverb_room:set(0.5)
  reverb_damp:set(0.5)
end

--[[
save_state = function()
  -- TODO: save buffer
  file = io.open("~/jah/pusher_state.lua", "w")
  file:write("local pusher_state = {", "\n")
  file:write("	start_pos = ", start_pos.value, "\n")
  file:write("	end_pos = ", end_pos.value, "\n")
  file:write("	speed = ", speed.value, "\n")
  file:write("	cutoff = ", cutoff.value, "\n")
  file:write("	resonance = ", resonance.value, "\n")
  file:write("	delay_send = ", delay_send.value, "\n")
  file:write("	reverb_send = ", reverb_send.value, "\n")
  file:write("	delay_time = ", delay_time.value, "\n")
  file:write("	decay_time = ", decay_time.value, "\n")
  file:write("	reverb_room = ", reverb_room.value, "\n")
  file:write("	reverb_damp = ", reverb_damp.value, "\n")
  file:write("}", "\n")
  file:write("return pusher_state")
end

load_state = function()
  -- TODO: restore buffer, if any
  local pusher_state = require '~/jah/pusher_state.lua'
  start_pos:set(pusher_state.start_pos)
  end_pos:set(pusher_state.end_pos)
  speed:set(pusher_state.speed)
  cutoff:set(pusher_state.cutoff)
  resonance:set(pusher_state.resonance)
  delay_send:set(pusher_state.delay_send)
  reverb_send:set(pusher_state.reverb_send)
  delay_time:set(pusher_state.delay_time)
  decay_time:set(pusher_state.decay_time)
  reverb_room:set(pusher_state.reverb_room)
  reverb_damp:set(pusher_state.reverb_damp)
end
]]

local display_param = function()
  screen.move(0, 16)
  if current_param_group == PARAM_GROUP_POS then
    screen.text(start_pos:string(0.1))
    screen.move(0, 24)
    screen.text(end_pos:string(0.1))
  elseif current_param_group == PARAM_GROUP_RATE then
    screen.text(speed:string(0.01))
    screen.move(0, 24)
    screen.text("") -- TODO: something?
  elseif current_param_group == PARAM_GROUP_FILTER then
    screen.text(cutoff:string(0.01))
    screen.move(0, 24)
    screen.text(resonance:string(0.1))
  elseif current_param_group == PARAM_GROUP_MIX then
    screen.text(delay_send:string(0.01))
    screen.move(0, 24)
    screen.text(reverb_send:string(0.01))
  elseif current_param_group == PARAM_GROUP_DELAY then
    screen.text("Delay Time: "..(delay_time:get()*1000).."ms")
    screen.move(0, 24)
    screen.text("Decay Time: "..(decay_time:get()*1000).."ms")
  elseif current_param_group == PARAM_GROUP_REVERB then
    screen.text(reverb_room:string(0.1))
    screen.move(0, 24)
    screen.text(reverb_damp:string(0.1))
  end
end

local switch_to_page = function(page)
  current_page = page
  redraw()
end

redraw = function()
  screen.clear()
  screen.level(15)
  screen.move(0, 8)
  if current_page == PAGE_FIRST then
    screen.text("Press and hold rightmost key")
    screen.move(0, 16)
    screen.text("to capture a sound!")
    --[[
    screen.move(0, 48)
    screen.text("(Long press leftmost key for")
    screen.move(0, 56)
    screen.text("help and options)")
    ]]
  elseif current_page == PAGE_RELEASE_TO_PLAY then
    screen.text("Recording...")
    screen.move(0, 24)
    screen.text("Release key and recorded")
    screen.move(0, 32)
    screen.text("sound will start playing")
  elseif current_page == PAGE_MASH then
    screen.text("Encoders adjust params")
    display_param()
    screen.move(0, 40)
    screen.text("Middle key cycles between")
    screen.move(0, 48)
    screen.text("params, rightmost key will")
    screen.move(0, 56)
    screen.text("capture a new sound.")
  end
  screen.update()
end

init = function(commands, count)
  screen.aa(1)
  screen.line_width(1.0) 
  -- TODO: load saved state and buffer, if any
  set_defaults()
  redraw()
end

cleanup = function()
  -- TODO: write state to file
  -- TODO: write audio sample to file
end

enc = function(n, d)
  if n == 1 then
    norns.audio.adjust_output_level(d)
    return
  end

  if current_page == PAGE_MASH then
    if n == 2 then
      if current_param_group == PARAM_GROUP_POS then
        start_pos:delta(d)
        engine.startPos(start_pos:get())
      elseif current_param_group == PARAM_GROUP_RATE then
        speed:delta(d)
        engine.speed(speed:get())
      elseif current_param_group == PARAM_GROUP_FILTER then
        cutoff:delta(d)
        engine.cutoff(cutoff:get())
      elseif current_param_group == PARAM_GROUP_MIX then
        delay_send:delta(d)
        engine.delaySend(delay_send:get())
      elseif current_param_group == PARAM_GROUP_DELAY then
        delay_time:delta(d)
        engine.delayTime(delay_time:get())
      elseif current_param_group == PARAM_GROUP_REVERB then
        reverb_room:delta(d)
        engine.reverbRoom(reverb_room:get())
      end
    elseif n == 3 then
      if current_param_group == PARAM_GROUP_POS then
        end_pos:delta(d)
        engine.endPos(end_pos:get())
      elseif current_param_group == PARAM_GROUP_RATE then
        print("TODO")
      elseif current_param_group == PARAM_GROUP_FILTER then
        resonance:delta(d)
        engine.resonance(resonance:get())
      elseif current_param_group == PARAM_GROUP_MIX then
        reverb_send:delta(d)
        engine.reverbSend(reverb_send:get())
      elseif current_param_group == PARAM_GROUP_DELAY then
        decay_time:delta(d)
        engine.decayTime(decay_time:get())
      elseif current_param_group == PARAM_GROUP_REVERB then
        reverb_damp:delta(d)
        engine.reverbDamp(reverb_damp:get())
      end
    end
    redraw()
  end
end

key = function(n, z)
  if n == 2 and z == 1 then
    if current_param_group == PARAM_GROUP_REVERB then
      current_param_group = 1
    else
      current_param_group = current_param_group + 1
    end
    switch_to_page(PAGE_MASH)
  elseif n == 3 then
    if z == 1 then
      engine.record()
      set_defaults()
      switch_to_page(PAGE_RELEASE_TO_PLAY)
    else
      engine.play()
      switch_to_page(PAGE_MASH)
    end
  end
end
