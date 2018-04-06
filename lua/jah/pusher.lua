-- @name pusher
-- @version 0.2.0
-- @author jah
-- @txt capture & playback a sound

ControlSpec = require 'jah/controlspec'
Param = require 'jah/param'
Scroll = require 'jah/scroll' -- TODO: not yet used
Helper = require 'helper'

engine = 'Pusher'

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

local rate_spec = ControlSpec.new(0.125, 8, ControlSpec.WARP_EXP, 0, 1, "")
local delay_time_spec = ControlSpec.new(0.0001, 3, ControlSpec.WARP_EXP, 0, 0.3, "secs")
local decay_time_spec = ControlSpec.new(0, 100, ControlSpec.WARP_LIN, 0, 1, "secs")
local cutoff_spec = ControlSpec.new(20, 10000, ControlSpec.WARP_EXP, 0, 10000, "Hz")
local volume_spec = ControlSpec.new(-60, 0, ControlSpec.WARP_LIN, 0, -60, "dB")
local percentage_spec = ControlSpec.new(0, 100, ControlSpec.WARP_LIN, 0, 0, "%")
local resonance_spec = ControlSpec.new(0, 100, ControlSpec.WARP_LIN, 0, 13, "%")

local start_pos = Param.new("Start", percentage_spec)
local end_pos = Param.new("End", percentage_spec)
local speed = Param.new("Speed", rate_spec)
local cutoff = Param.new("Cutoff", cutoff_spec)
local resonance = Param.new("Resonance", resonance_spec)
local delay_send = Param.new("Delay Send", volume_spec)
local reverb_send = Param.new("Reverb Send", volume_spec)
local delay_time = Param.new("Delay Time", delay_time_spec)
local decay_time = Param.new("Decay Time", decay_time_spec)
local reverb_room = Param.new("Reverb Room", percentage_spec)
local reverb_damp = Param.new("Reverb Damp", percentage_spec)

set_defaults = function()
  start_pos:revert_to_default()
  end_pos:set(1.0)
  speed:revert_to_default()
  cutoff:revert_to_default()
  resonance:revert_to_default()
  delay_send:revert_to_default()
  reverb_send:revert_to_default()
  delay_time:revert_to_default()
  decay_time:revert_to_default()
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
  s.move(0, 16)
  if current_param_group == PARAM_GROUP_POS then
    s.text(start_pos:string(0.1))
    s.move(0, 24)
    s.text(end_pos:string(0.1))
  elseif current_param_group == PARAM_GROUP_RATE then
    s.text(speed:string(0.01))
    s.move(0, 24)
    s.text("") -- TODO: something?
  elseif current_param_group == PARAM_GROUP_FILTER then
    s.text(cutoff:string(0.01))
    s.move(0, 24)
    s.text(resonance:string(0.1))
  elseif current_param_group == PARAM_GROUP_MIX then
    s.text(delay_send:string(0.01))
    s.move(0, 24)
    s.text(reverb_send:string(0.01))
  elseif current_param_group == PARAM_GROUP_DELAY then
    s.text("Delay Time: "..(delay_time:mapped_value()*1000).."ms")
    s.move(0, 24)
    s.text("Decay Time: "..(decay_time:mapped_value()*1000).."ms")
  elseif current_param_group == PARAM_GROUP_REVERB then
    s.text(reverb_room:string(0.1))
    s.move(0, 24)
    s.text(reverb_damp:string(0.1))
  end
end

local switch_to_page = function(page)
  current_page = page
  redraw()
end

redraw = function()
  s.clear()
  s.level(15)
  s.move(0, 8)
  if current_page == PAGE_FIRST then
    s.text("Press and hold rightmost key")
    s.move(0, 16)
    s.text("to capture a sound!")
    --[[
    s.move(0, 48)
    s.text("(Long press leftmost key for")
    s.move(0, 56)
    s.text("help and options)")
    ]]
  elseif current_page == PAGE_RELEASE_TO_PLAY then
    s.text("Recording...")
    s.move(0, 24)
    s.text("Release key and recorded")
    s.move(0, 32)
    s.text("sound will start playing")
  elseif current_page == PAGE_MASH then
    s.text("Encoders adjust params")
    display_param()
    s.move(0, 40)
    s.text("Middle key cycles between")
    s.move(0, 48)
    s.text("params, rightmost key will")
    s.move(0, 56)
    s.text("capture a new sound.")
  end
  s.update()
end

init = function(commands, count)
  s.aa(1)
  s.line_width(1.0) 
  -- TODO: load saved state and buffer, if any
  set_defaults()
  redraw()
end

cleanup = function()
  -- TODO: write state to file
  -- TODO: write audio sample to file
end

enc = function(n, delta)
  if n == 1 then
    Helper.adjust_audio_output_level(delta)
    return
  end

  if current_page == PAGE_MASH then
    local d = delta/100
    if n == 2 then
      if current_param_group == PARAM_GROUP_POS then
        start_pos:adjust(d)
        e.startPos(start_pos:mapped_value())
      elseif current_param_group == PARAM_GROUP_RATE then
        speed:adjust(d)
        e.speed(speed:mapped_value())
      elseif current_param_group == PARAM_GROUP_FILTER then
        cutoff:adjust(d)
        e.cutoff(cutoff:mapped_value())
      elseif current_param_group == PARAM_GROUP_MIX then
        delay_send:adjust(d)
        e.delaySend(delay_send:mapped_value())
      elseif current_param_group == PARAM_GROUP_DELAY then
        delay_time:adjust(d)
        e.delayTime(delay_time:mapped_value())
      elseif current_param_group == PARAM_GROUP_REVERB then
        reverb_room:adjust(d)
        e.reverbRoom(reverb_room:mapped_value())
      end
    elseif n == 3 then
      if current_param_group == PARAM_GROUP_POS then
        end_pos:adjust(d)
        e.endPos(end_pos:mapped_value())
      elseif current_param_group == PARAM_GROUP_RATE then
        print("TODO")
      elseif current_param_group == PARAM_GROUP_FILTER then
        resonance:adjust(d)
        e.resonance(resonance:mapped_value())
      elseif current_param_group == PARAM_GROUP_MIX then
        reverb_send:adjust(d)
        e.reverbSend(reverb_send:mapped_value())
      elseif current_param_group == PARAM_GROUP_DELAY then
        decay_time:adjust(d)
        e.decayTime(decay_time:mapped_value())
      elseif current_param_group == PARAM_GROUP_REVERB then
        reverb_damp:adjust(d)
        e.reverbDamp(reverb_damp:mapped_value())
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
      e.record()
      set_defaults()
      switch_to_page(PAGE_RELEASE_TO_PLAY)
    else
      e.play()
      switch_to_page(PAGE_MASH)
    end
  end
end
