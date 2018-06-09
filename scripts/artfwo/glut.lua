-- glut
--
-- granular sampler in progress
-- (currently requires a grid)
--
-- trigger voices
-- using grid rows 2-8
--
-- mute voices and record
-- patterns using grid row 1
--

engine.name = 'Glut'

local VOICES = 7

local positions = {}
local gates = {}
local voice_levels = {}

for i=1, VOICES do
  positions[i] = -1
  gates[i] = 0
  voice_levels[i] = 0
end

local gridbuf = require 'gridbuf'
local grid_ctl = gridbuf.new(16, 8)
local grid_voc = gridbuf.new(16, 8)

local metro_grid_refresh
local metro_blink

--[[
recorder
]]

local pattern_banks = {}
local pattern_timers = {}
local pattern_leds = {} -- for displaying button presses
local pattern_positions = {} -- playback positions
local record_bank = -1
local record_prevtime = -1
local record_length = -1
local alt = false
local blink = 0
local metro_blink

local function record_event(x, y, z)
  if record_bank > 0 then
    -- record first event tick
    local current_time = util.time()

    if record_prevtime < 0 then
      record_prevtime = current_time
    end

    local time_delta = current_time - record_prevtime
    table.insert(pattern_banks[record_bank], {time_delta, x, y, z})
    record_prevtime = current_time
  end
end

local function start_playback(n)
  pattern_timers[n]:start(0.001, 1) -- TODO: timer doesn't start immediately with zero
end

local function stop_playback(n)
  pattern_timers[n]:stop()
  pattern_positions[n] = 1
end

local function arm_recording(n)
  record_bank = n
end

local function stop_recording()
  local recorded_events = #pattern_banks[record_bank]

  if recorded_events > 0 then
    -- save last delta to first event
    local current_time = util.time()
    local final_delta = current_time - record_prevtime
    pattern_banks[record_bank][1][1] = final_delta

    start_playback(record_bank)
  end

  record_bank = -1
  record_prevtime = -1
end

local function pattern_next(n)
  local bank = pattern_banks[n]
  local pos = pattern_positions[n]

  local event = bank[pos]
  local delta, x, y, z = table.unpack(event)
  pattern_leds[n] = z
  gridkey(x, y, z, true)

  local next_pos = pos + 1
  if next_pos > #bank then
    next_pos = 1
  end

  local next_event = bank[next_pos]
  local next_delta = next_event[1]
  pattern_positions[n] = next_pos

  -- schedule next event
  pattern_timers[n]:start(next_delta, 1)
end

local function record_handler(n)
  if alt then
    -- clear pattern
    if n == record_bank then stop_recording() end
    if pattern_timers[n].is_running then stop_playback(n) end
    pattern_banks[n] = {}
    do return end
  end

  if n == record_bank then
    -- stop if pressed current recording
    stop_recording()
  else
    local pattern = pattern_banks[n]

    if #pattern > 0 then
      -- toggle playback if there's data
      if pattern_timers[n].is_running then stop_playback(n) else start_playback(n) end
    else
      -- stop recording if it's happening
      if record_bank > 0 then
        stop_recording()
      end
      -- arm new pattern for recording
      arm_recording(n)
    end
  end
end

--[[
internals
]]

local function display_voice(phase, width)
  local pos = phase * width

  local levels = {}
  for i = 1, width do levels[i] = 0 end

  local left = math.floor(pos)
  local index_left = left + 1
  local dist_left = math.abs(pos - left)

  local right = math.floor(pos + 1)
  local index_right = right + 1
  local dist_right = math.abs(pos - right)

  if index_left < 1 then index_left = width end
  if index_left > width then index_left = 1 end

  if index_right < 1 then index_right = width end
  if index_right > width then index_right = 1 end

  levels[index_left] = math.floor(math.abs(1 - dist_left) * 15)
  levels[index_right] = math.floor(math.abs(1 - dist_right) * 15)

  return levels
end

local function start_voice(voice, pos)
  engine.seek(voice, pos)
  engine.gate(voice, 1)
  gates[voice] = 1
end

local function stop_voice(voice)
  gates[voice] = 0
  engine.gate(voice, 0)
end

local function grid_refresh()
  if g == nil then
    return
  end

  grid_ctl:led_level_all(0)
  grid_voc:led_level_all(0)

  -- alt
  grid_ctl:led_level_set(16, 1, alt and 15 or 1)

  -- pattern banks
  for i=1, VOICES do
    local level = 2

    if #pattern_banks[i] > 0 then level = 5 end
    if pattern_timers[i].is_running then
      level = 10
      if pattern_leds[i] > 0 then
        level = 12
      end
    end

    grid_ctl:led_level_set(8 + i, 1, level)
  end

  -- blink armed pattern
  if record_bank > 0 then
      grid_ctl:led_level_set(8 + record_bank, 1, 15 * blink)
  end

  -- voices
  for i=1, VOICES do
    if voice_levels[i] > 0 then
      grid_ctl:led_level_set(i, 1, math.min(math.ceil(voice_levels[i] * 15), 15))
      grid_voc:led_level_row(1, i + 1, display_voice(positions[i], 16))
    end
  end

  local buf = grid_ctl | grid_voc
  buf:render(g)
  g:refresh()
end

function init()
  -- polls
  for v = 1, VOICES do
    local phase_poll = poll.set('phase_' .. v, function(pos) positions[v] = pos end)
    phase_poll.time = 0.05
    phase_poll:start()

    local level_poll = poll.set('level_' .. v, function(lvl) voice_levels[v] = lvl end)
    level_poll.time = 0.05
    level_poll:start()
  end

  -- recorders
  for v = 1, VOICES do
    table.insert(pattern_timers, metro.alloc(function(tick) pattern_next(v) end))
    table.insert(pattern_banks, {})
    table.insert(pattern_leds, 0)
    table.insert(pattern_positions, 1)
  end

  -- grid refresh timer, 40 fps
  metro_grid_refresh = metro.alloc(function(stage) grid_refresh() end, 1 / 40)
  metro_grid_refresh:start()

  metro_blink = metro.alloc(function(stage) blink = blink ~ 1 end, 1 / 4)
  metro_blink:start()

  local sep = ": "

  params:add_taper("*"..sep.."mix", 0, 100, 50, 0, "%")
  params:set_action("*"..sep.."mix", function(value) engine.reverb_mix(value / 100) end)

  params:add_taper("*"..sep.."room", 0, 100, 50, 0, "%")
  params:set_action("*"..sep.."room", function(value) engine.reverb_room(value / 100) end)

  params:add_taper("*"..sep.."damp", 0, 100, 50, 0, "%")
  params:set_action("*"..sep.."damp", function(value) engine.reverb_damp(value / 100) end)

  for v = 1, VOICES do
    params:add_separator()

    params:add_file(v..sep.."sample")
    params:set_action(v..sep.."sample", function(file) engine.read(v, file) end)

    params:add_taper(v..sep.."volume", -60, 20, 0, 0, "dB")
    params:set_action(v..sep.."volume", function(value) engine.volume(v, math.pow(10, value / 20)) end)

    params:add_taper(v..sep.."speed", -200, 200, 100, 0, "%")
    params:set_action(v..sep.."speed", function(value) engine.speed(v, value / 100) end)

    params:add_taper(v..sep.."jitter", 0, 500, 0, 5, "ms")
    params:set_action(v..sep.."jitter", function(value) engine.jitter(v, value / 1000) end)

    params:add_taper(v..sep.."size", 1, 500, 100, 5, "ms")
    params:set_action(v..sep.."size", function(value) engine.size(v, value / 1000) end)

    params:add_taper(v..sep.."density", 0, 512, 20, 6, "hz")
    params:set_action(v..sep.."density", function(value) engine.density(v, value) end)

    params:add_taper(v..sep.."pitch", -24, 24, 0, 0, "st")
    params:set_action(v..sep.."pitch", function(value) engine.pitch(v, math.pow(0.5, -value / 12)) end)

    params:add_taper(v..sep.."spread", 0, 100, 0, 0, "%")
    params:set_action(v..sep.."spread", function(value) engine.spread(v, value / 100) end)

    params:add_taper(v..sep.."att / dec", 1, 9000, 1000, 3, "ms")
    params:set_action(v..sep.."att / dec", function(value) engine.envscale(v, value / 1000) end)
  end

  params:bang()
end

--[[
exports
]]

function gridkey(x, y, z, skip_record)
  if y > 1 or (y == 1 and x < 9) then
    if not skip_record then
      record_event(x, y, z)
    end
  end

  if z > 0 then
    -- set voice pos
    if y > 1 then
      local voice = y - 1
      start_voice(voice, (x - 1) / 16)
    else
      if x == 16 then
        -- alt
        alt = true
      elseif x > 8 then
        record_handler(x - 8)
      elseif x == 8 then
        -- reserved
      elseif x < 8 then
        -- stop
        local voice = x
        stop_voice(voice)
      end
    end
  else
    -- alt
    if x == 16 and y == 1 then alt = false end
  end
end

function enc(n, d)
end

function key(n, z)
end

function redraw()
  -- do return end
  screen.clear()
  screen.level(15)

  screen.move(0, 10)
  screen.text("^ load samples")
  screen.move(0, 20)
  screen.text("  via menu > parameters")
  
  screen.update()
end
