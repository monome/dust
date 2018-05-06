-- glut
--
-- granular sampler in progress
--

engine.name = 'Glut'

local VOICES = 7
local SCREEN_PARAMS = 6

local positions = {-1, -1, -1, -1, -1, -1, -1}
local gates = {0, 0, 0, 0, 0, 0, 0}
local current_voice = 1
local current_voice_param = 1
local current_voice_param_offset = 0
local current_glut_param = 1

local glut_params = {
  "reverb_mix",
  "reverb_room",
  "reverb_damp",
}

local voice_params = {
  "sample", -- file
  "volume",
  "speed",
  "jitter",
  "size",
  "density",
  "pitch",
  "spread",
}

local gridbuf = require 'gridbuf'
local grid_ctl = gridbuf.new(16, 8)
local grid_voc = gridbuf.new(16, 8)

local metro_grid_refresh

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

local function ledinterp(value, width)
  local pos = value * width

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
  engine.pos(voice, pos)
  engine.gate(voice, 1)
  gates[voice] = 1
end

local function stop_voice(voice)
  gates[voice] = 0
  engine.gate(voice, 0)
end

local function fileselect_callback(path)
  if path ~= "cancel" then
    engine.read(current_voice, path)
  end
end

local function grid_refresh()
  if g == nil then
    return
  end

  grid_ctl:led_level_all(0)
  grid_voc:led_level_all(0)

  -- current voice
  for i=1, 16 do
    grid_ctl:led_level_set(i, current_voice + 1, 3)
  end

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
    if gates[i] > 0 then
      grid_ctl:led_level_set(i, 1, 7)
      grid_voc:led_level_row(1, i + 1, ledinterp(positions[i], 16))
    end
  end

  local buf = grid_ctl | grid_voc
  buf:render(g)
  g:refresh()
end

function init()
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

  params:add_control("reverb_mix", controlspec.new(0, 1, "lin", 0, 0.5, ""))
  params:set_action("reverb_mix", function(value) engine.reverb_mix(value) end)

  params:add_control("reverb_room", controlspec.new(0, 1, "lin", 0, 1, ""))
  params:set_action("reverb_room", function(value) engine.reverb_room(value) end)

  params:add_control("reverb_damp", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("reverb_damp", function(value) engine.reverb_damp(value) end)

  -- phase polls
  for v = 1, VOICES do
    p = poll.set('phase_' .. v, function(pos) positions[v] = pos end)
    p.time = 0.05
    p:start()
  end

  for v = 1, VOICES do
    params:add_file("sample"..v)
    params:set_action("sample"..v, function(file) engine.read(v, file) end)

    params:add_control("volume"..v, controlspec.new(0, 1, "lin", 0, 1, ""))
    params:set_action("volume"..v, function(value) engine.volume(v, value) end)

    params:add_control("speed"..v, controlspec.new(-8, 8, "lin", 0, 1, ""))
    params:set_action("speed"..v, function(value) engine.speed(v, value) end)

    params:add_control("jitter"..v, controlspec.new(0, 0.5, "lin", 0, 0.01, "sec"))
    params:set_action("jitter"..v, function(value) engine.jitter(v, value) end)

    params:add_control("size"..v, controlspec.new(0.001, 10, "lin", 0, 0.1, "sec"))
    params:set_action("size"..v, function(value) engine.size(v, value) end)

    params:add_control("density"..v, controlspec.new(0, 512, "lin", 0, 20, ""))
    params:set_action("density"..v, function(value) engine.density(v, value) end)

    params:add_control("pitch"..v, controlspec.new(0, 8, "lin", 0, 1, ""))
    params:set_action("pitch"..v, function(value) engine.pitch(v, value) end)

    params:add_control("spread"..v, controlspec.new(0, 1, "lin", 0, 0, ""))
    params:set_action("spread"..v, function(value) engine.spread(v, value) end)
  end

  params:bang()

  -- load default sounds
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
  if n == 1 then
    -- current_voice = (current_voice + d) % 8
    current_voice = util.clamp(current_voice + d, 0, VOICES)
  elseif n == 2 then
    if current_voice > 0 then
      -- scroll voice parameters
      --current_voice_param = (current_voice_param - 1 + d) % #voice_params + 1
      current_voice_param = util.clamp(current_voice_param + d, 1, #voice_params)

      -- maximum 6 parameters visible on screen
      if current_voice_param > SCREEN_PARAMS + current_voice_param_offset then
        current_voice_param_offset = current_voice_param - SCREEN_PARAMS
      end

      if current_voice_param <= current_voice_param_offset then
        current_voice_param_offset = current_voice_param - 1
      end

    else
      -- scroll glut parameters
      current_glut_param = (current_glut_param - 1 + d) % #glut_params + 1
    end
  elseif n == 3 then
    if current_voice > 0 then
      -- voice param
      if current_voice_param > 1 then
        params:delta(voice_params[current_voice_param]..current_voice, d / 10)
      end
    else
      -- glut param
      params:delta(glut_params[current_glut_param], d / 10)
    end
  end
  redraw()
end

function key(n, z)
  if n == 3 then
    if current_voice > 0 and current_voice_param == 1 then
      fileselect.enter(os.getenv("HOME").."/dust", fileselect_callback)
    end
  end
end

function redraw()
  -- do return end
  screen.clear()

  screen.level(5)
  screen.move(127, 20)

  if current_voice > 0 then
    -- voice parameters
    screen.level(5)
    screen.move(127, 10)
    screen.text_right("voice: "..current_voice)

    if current_voice_param == 1 then screen.level(15) else screen.level(5) end
    screen.move(0, -1 + (1 - current_voice_param_offset) * 10)
    screen.text("load >")

    if current_voice_param == 2 then screen.level(15) else screen.level(5) end
    screen.move(0, -1 + (2 - current_voice_param_offset) * 10)
    screen.text("volume: "..params:string("volume"..current_voice))

    if current_voice_param == 3 then screen.level(15) else screen.level(5) end
    screen.move(0, -1 + (3 - current_voice_param_offset) * 10)
    screen.text("speed: "..params:string("speed"..current_voice))

    if current_voice_param == 4 then screen.level(15) else screen.level(5) end
    screen.move(0, -1 + (4 - current_voice_param_offset) * 10)
    screen.text("jitter: "..params:string("jitter"..current_voice))

    if current_voice_param == 5 then screen.level(15) else screen.level(5) end
    screen.move(0, -1 + (5 - current_voice_param_offset) * 10)
    screen.text("size: "..params:string("size"..current_voice))

    if current_voice_param == 6 then screen.level(15) else screen.level(5) end
    screen.move(0, -1 + (6 - current_voice_param_offset) * 10)
    screen.text("density: "..params:string("density"..current_voice))

    if current_voice_param == 7 then screen.level(15) else screen.level(5) end
    screen.move(0, -1 + (7 - current_voice_param_offset) * 10)
    screen.text("pitch: "..params:string("pitch"..current_voice))

    if current_voice_param == 8 then screen.level(15) else screen.level(5) end
    screen.move(0, -1 + (8 - current_voice_param_offset) * 10)
    screen.text("spread: "..params:string("spread"..current_voice))
  else
    -- glut parameters
    screen.level(5)
    screen.move(127, 10)
    screen.text_right("voice: all")

    if current_glut_param == 1 then screen.level(15) else screen.level(5) end
    screen.move(0, 1 * 10)
    screen.text("mix: "..params:string("reverb_mix"))

    if current_glut_param == 2 then screen.level(15) else screen.level(5) end
    screen.move(0, 2 * 10)
    screen.text("room: "..params:string("reverb_room"))

    if current_glut_param == 3 then screen.level(15) else screen.level(5) end
    screen.move(0, 3 * 10)
    screen.text("damp: "..params:string("reverb_damp"))
  end

  screen.update()
end

-- called on script quit, release memory
function cleanup()
  for v = 1, VOICES do
    poll.polls['phase_' .. v]:stop()
  end
  metro.free_all()
end
