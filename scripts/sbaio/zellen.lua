-- zellen
--
-- sequencer based on
-- conway's game of life
--
-- grid: enter cell pattern
--
-- KEY2: play/pause sequence
-- KEY3: advance generation
-- hold KEY1 + press KEY3:
--   delete board
--
-- ENC1: set speed (bpm)
-- ENC2: set play mode
-- ENC3: set play direction
--
-- see the parameters screen
-- for more settings.

engine.name = "PolyPerc"

local music = require("mark_eats/musicutil")
local g = grid.connect()
local m = midi.connect()

-- constants
local GRID_SIZE = {
  ["X"] = 16,
  ["Y"] = 8
}
local LEVEL = {
  ["ALIVE"] = 8,
  ["BORN"] = 12,
  ["REBORN"] = 13,
  ["DYING"] = 2,
  ["DEAD"] = 0,
  ["ALIVE_THRESHOLD"] = 7,
  ["ACTIVE"] = 15
}
local SCREENS = {
  ["BOARD"] = 1,
  ["CONFIRM"] = 2
}
local NOTE_NAMES_OCTAVE = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local NOTES = {}
local NOTE_NAMES = {}
local SCALE_NAMES = {}
local SCALE_LENGTH = 24
local SEQ_MODES = {
  "manual",
  "semi-manual",
  "automatic"
}
local PLAY_DIRECTIONS = {
  "up",
  "down",
  "random",
  "drunken up",
  "drunken down"
}
local PLAY_MODES = {
"reborn",
"born",
"ghost"
}
local SYNTHS = {
  "internal",
  "midi",
  "both"
}
local KEY1_DOWN = false
local KEY2_DOWN = false
local KEY3_DOWN = false

-- initial values
local root_note = 36
local scale_name = ""
local scale = {}
local seq_counter = metro.alloc()
local note_offset = 0
local playable_cells = {}
local play_pos = 0
local active_notes = {}
local seq_running = false
local show_playing_indicator = false
local board = {}

-- note on/off
local function note_on(note)
  local note_num = math.min((note + note_offset), 127)
  local synth_mode = params:get("synth")
  if(synth_mode == 1 or synth_mode == 3) then
    engine.hz(music.note_num_to_freq(note_num))
  end
  if(synth_mode == 2 or synth_mode == 3) then
    m.note_on(note_num, params:get("midi_note_velocity"))
  end
  table.insert(active_notes, note_num)
end

local function notes_off()
  for i=1,#active_notes do
    m.note_off(active_notes[i])
  end
  active_notes = {}
end


-- helpers
local function table_clone(org)
  return {table.unpack(org)}
end

local function clone_board(b)
  b_c = {}
  for i=1,#b do
    b_c[i] = table_clone(b[i])
  end
  return b_c
end

local function table_map(f, arr)
  local mapped_arr = {}
  for i,v in ipairs(arr) do
    mapped_arr[i] = f(v)
  end
  return mapped_arr
end

local function table_reverse(arr)
  local rev_arr = {}
  for i = #arr, 1, -1 do
    table.insert(rev_arr, arr[i])
  end
  return rev_arr
end

local function table_shuffle(arr)
  for i = #arr, 2, -1 do
    local j = math.random(i)
    arr[i], arr[j] = arr[j], arr[i]
  end
  return arr
end

local function note_name_to_num(name)
  local NOTE_NAME_INDEX = {
    ["C"] = 0,
    ["C#"] = 1,
    ["D"] = 2,
    ["D#"] = 3,
    ["E"] = 4,
    ["F"] = 5,
    ["F#"] = 6,
    ["G"] = 7,
    ["G#"] = 8,
    ["A"] = 9,
    ["A#"] = 10,
    ["B"] = 11
  }
  local name_len = #name
  local note_name = "C"
  local octave = "0"
  if (name_len == 2) then
    note_name = name:sub(1,1)
    octave = name:sub(2,2)
  elseif (name_len == 3) then
    note_name = name:sub(1,2)
    octave = name:sub(3,3)
  end
  local note_index = NOTE_NAME_INDEX[note_name]
  return tonumber(octave) * 12 + note_index
end

local function bpm_to_seconds_16(bpm)
  return 60 / bpm / 4
end

local function init_engine()
  engine.release(params:get("release"))
  engine.cutoff(params:get("cutoff"))
end

local function update_playing_indicator()
  if (params:get("seq_mode") ~= 1) then
    if (show_playing_indicator) then
      screen.level(15)
    else
      screen.level(0)
    end
    screen.rect(125, 53, 3, 3)
    screen.fill()
  end
end


-- game logic
local function is_active(x, y)
  return board[x][y] > LEVEL.ALIVE_THRESHOLD
end

local function is_dying(x, y)
  return board[x][y] == LEVEL.DYING
end

local function was_born(x, y)
  return board[x][y] == LEVEL.BORN
end

local function was_reborn(x, y)
  return board[x][y] == LEVEL.REBORN
end

local function number_of_neighbors(x, y)
  local num_neighbors = 0
  if (x < GRID_SIZE.X) then
    num_neighbors = num_neighbors + (is_active(x + 1, y) and 1 or 0)
  end
  if (x > 1) then
    num_neighbors = num_neighbors + (is_active(x - 1, y) and 1 or 0)
  end
  if (y < GRID_SIZE.Y) then
    num_neighbors = num_neighbors + (is_active(x, y + 1) and 1 or 0)
  end
  if (y > 1) then
    num_neighbors = num_neighbors + (is_active(x, y - 1) and 1 or 0)
  end
  if (x < GRID_SIZE.X and y < GRID_SIZE.Y) then
    num_neighbors = num_neighbors + (is_active(x + 1, y + 1) and 1 or 0)
  end
  if (x < GRID_SIZE.X and y > 1) then
    num_neighbors = num_neighbors + (is_active(x + 1, y - 1) and 1 or 0)
  end
  if (x > 1 and y < GRID_SIZE.Y) then
    num_neighbors = num_neighbors + (is_active(x - 1, y + 1) and 1 or 0)
  end
  if (x > 1 and y > 1) then
    num_neighbors = num_neighbors + (is_active(x - 1, y - 1) and 1 or 0)
  end
  
  return num_neighbors
end

local function collect_playable_cells()
  playable_cells = {}
  local mode = params:get("play_mode")
  for x=1,GRID_SIZE.X do
    for y=1,GRID_SIZE.Y do
      if ((was_born(x, y) or was_reborn(x, y)) and mode == 1) then
        table.insert(playable_cells, {
          ["x"] = x,
          ["y"] = y
        })
      end
      if (was_born(x, y) and mode == 2) then
        table.insert(playable_cells, {
          ["x"] = x,
          ["y"] = y
        })
      end
      if (is_dying(x, y) and mode == 3) then
        table.insert(playable_cells, {
          ["x"] = x,
          ["y"] = y
        })
      end
    end
  end
  
  local play_direction = params:get("play_direction")
  if(play_direction == 2 or play_direction == 5) then
    playable_cells = table_reverse(playable_cells)
  elseif(play_direction == 3) then
    playable_cells = table_shuffle(playable_cells)
  end
end

local function generation_step()
  notes_off()
  local board_c = clone_board(board)
  for x=1,GRID_SIZE.X do
    for y=1,GRID_SIZE.Y do
      local num_neighbors = number_of_neighbors(x, y)
      local cell_active = is_active(x, y)
      if(is_dying(x, y)) then
        board_c[x][y] = LEVEL.DEAD
      end
      if (num_neighbors < 2 and cell_active) then
        board_c[x][y] = LEVEL.DYING
      end
      if (num_neighbors > 3 and cell_active) then
        board_c[x][y] = LEVEL.DYING
      end
      if (num_neighbors > 1 and num_neighbors < 4 and cell_active) then
        board_c[x][y] = LEVEL.ALIVE
      end
      if (num_neighbors == 3 and cell_active) then
        board_c[x][y] = LEVEL.REBORN
      end
      if (num_neighbors == 3 and not cell_active) then
        board_c[x][y] = LEVEL.BORN
      end
    end
  end
  board = board_c
  play_pos = 1
  collect_playable_cells()
  grid_redraw()
end


-- sequencing
local function init_position()
  position = {
    ["x"] = -1,
    ["y"] = -1
  }
end

local function reset_sequence()
  local seq_mode = params:get("seq_mode")
  play_pos = 1
  
  if(seq_mode == 3) then
    init_position()
    generation_step()
    if(not seq_running) then
      seq_counter:start()
      seq_running = true
      show_playing_indicator = true
    end
  else
    seq_counter:stop()
    seq_running = false
    show_playing_indicator = false
  end
end

local function play_seq_step()
  local play_direction = params:get("play_direction")
  local seq_mode = params:get("seq_mode")
  notes_off()
  
  show_playing_indicator = not show_playing_indicator
  
  if (play_pos <= #playable_cells) then
    position = playable_cells[play_pos]
    local midi_note = scale[(position.x - 1) + position.y]
    note_on(midi_note)
    if(play_direction == 4 or play_direction == 5) then
      if(math.random(2) == 1 and play_pos > 1) then
        play_pos = play_pos - 1
      else
        play_pos = play_pos + 1
      end
    else
      if (play_pos < #playable_cells or seq_mode == 2) then
        play_pos = play_pos + 1
      else
        reset_sequence()
      end
    end
  else
    init_position()
    reset_sequence()
  end
  redraw()
  grid_redraw()
end

local function clear_board()
  for x=1,GRID_SIZE.X do
    for y=1,GRID_SIZE.Y do
      board[x][y] = LEVEL.DEAD
    end 
  end
  notes_off()
  init_position()
  playable_cells = {}
  grid_redraw()
end


-- parameter callbacks
local function set_speed(bpm)
  seq_counter.time = bpm_to_seconds_16(bpm)
end

local function set_play_mode(play_mode)
  if(play_mode == 3) then
    note_offset = params:get("ghost_offset")
  else
    note_offset = 0
  end
  collect_playable_cells()
end

local function set_play_direction()
  collect_playable_cells()
end

local function set_ghost_offset()
  set_play_mode(params:get("play_mode"))
end

local function set_scale(new_scale_name)
  scale = music.generate_scale_of_length(root_note, new_scale_name, SCALE_LENGTH)
end

local function set_root_note(new_root_note)
  root_note = new_root_note
  scale = music.generate_scale_of_length(new_root_note, scale_name, SCALE_LENGTH)
end

local function set_release(r)
  engine.release(r)
end

local function set_cutoff(f)
  engine.cutoff(f)
end

local function set_midi_device_number()
  m:disconnect()
  m:reconnect(params:get("midi_device_number"))
end


-------------
-- GLOBALS --
-------------


-- init
function init()
  for i=0, 72 do
    NOTES[i] = {
      ["number"] = i,
      ["name"] = NOTE_NAMES_OCTAVE[i % 12 + 1] .. math.floor(i / 12),
      ["octave"] = math.floor(i / 12)
    }
  end
  NOTE_NAMES = table_map(function(note) return note.name end, NOTES)
  SCALE_NAMES = table_map(function(scale) return scale.name end, music.SCALES)
  
  -- params
  params:add_option("seq_mode", "seq mode", SEQ_MODES, 2)
  
  params:add_option("scale", "scale", SCALE_NAMES, 1)
  params:set_action("scale", set_scale)
  
  params:add_option("root_note", "root note", NOTE_NAMES, 48)
  params:set_action("root_note", set_root_note)
  
  params:add_number("ghost_offset", "ghost offset", -24, 24, 0)
  params:set_action("ghost_offset", set_ghost_offset)
  
  params:add_number("speed", "speed", 0, 1000, 100)
  params:set_action("speed", set_speed)
  
  params:add_option("play_mode", "play mode", PLAY_MODES, 1)
  params:set_action("play_mode", set_play_mode)
  
  params:add_option("play_direction", "play direction", PLAY_DIRECTIONS, 1)
  params:set_action("play_direction", set_play_direction)
  
  params:add_control("release", "release", controlspec.new(0.1, 5.0, "lin", 0.01, 0.5, "s"))
  params:set_action("release", set_release)
  
  params:add_control("cutoff", "cutoff", controlspec.new(50, 5000, "exp", 0, 1000, "hz"))
  params:set_action("cutoff", set_cutoff)
  
  params:add_option("synth", "synth", SYNTHS, 3)
  
  params:add_number("midi_device_number", "midi device number", 1, 5, 1)
  params:set_action("midi_device_number", set_midi_device_number)
  
  params:add_number("midi_note_velocity", "midi note velocity", 1, 127, 100)
  
  scale_name = SCALE_NAMES[13]
  scale = music.generate_scale_of_length(root_note, scale_name, SCALE_LENGTH)
  
  seq_counter.time = bpm_to_seconds_16(params:get("speed"))
  seq_counter.count = -1
  seq_counter.callback = play_seq_step
  
  for x=1,GRID_SIZE.X do
  board[x] = {}
    for y=1,GRID_SIZE.Y do
      board[x][y] = LEVEL.DEAD
    end
  end
  
  init_position()
  init_engine()
end


-- display UI
function redraw()
  screen.clear()
  screen.move(0, 8)
  screen.level(15)
  screen.text(params:get("speed"))
  screen.level(7)
  screen.move(0, 16)
  screen.text("speed")
  
  screen.move(0, 28)
  screen.level(15)
  screen.text(PLAY_MODES[params:get("play_mode")])
  screen.level(7)
  screen.move(0, 36)
  screen.text("play mode")
  
  screen.move(0, 48)
  screen.level(15)
  screen.text(PLAY_DIRECTIONS[params:get("play_direction")])
  screen.level(7)
  screen.move(0, 56)
  screen.text("play direction")
  
  update_playing_indicator()
  
  screen.update()
end

-- grid UI
function grid_redraw()
  g.all(0)
  for x=1,GRID_SIZE.X do
    for y=1,GRID_SIZE.Y do
      if (position.x == x and position.y == y) then
        g.led(x, y, LEVEL.ACTIVE)
      else
        g.led(x, y, board[x][y])
      end
    end
  end
  g.refresh()
end


-- ENC input handling
function enc(n, d)
  if (n == 1) then
    params:delta("speed", d)
  end
  if (n == 2) then
    params:delta("play_mode", d)
  end
  if (n == 3) then
    params:delta("play_direction", d)
  end
  redraw()
end


-- KEY input handling
function key(n, z)
  local seq_mode = params:get("seq_mode")
  if (n == 1) then
    KEY1_DOWN = z == 1
  end
  if (n == 2) then
    KEY2_DOWN = z == 1
    if (KEY2_DOWN) then
      if(seq_mode == 1) then
        if (#playable_cells == 0) then
          generation_step()
        end
        play_seq_step()
      elseif(seq_mode == 2 or seq_mode == 3) then
        if(seq_running) then
          seq_counter:stop()
          seq_running = false
          show_playing_indicator = false
        else
          if (#playable_cells == 0) then
            generation_step()
          end
          seq_counter:start()
          seq_running = true
          show_playing_indicator = true
        end
      end
    end
  end
  if (n == 3) then
    KEY3_DOWN = z == 1
    if(KEY3_DOWN and KEY1_DOWN) then
      clear_board()
    elseif(KEY3_DOWN) then
      seq_counter:stop()
      seq_running = false
      show_playing_indicator = false
      generation_step()
    end
  end
  redraw()
end


-- GRID input handling
g.event = function(x, y, z)
  if (z == 1) then
    if (is_active(x, y)) then
      board[x][y] = LEVEL.DEAD
    else
      board[x][y] = LEVEL.ALIVE
    end
  end
  grid_redraw()
end

