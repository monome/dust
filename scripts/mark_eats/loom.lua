-- Loom
--
-- Pattern weaver for grids.
--
-- Hold a grid key and press
-- another on the same row/col
-- to add a trigger or note.
-- Three keys clear a row/col.
--
-- ENC1/KEY2 : Change page
--
-- PAGE 1:
--  ENC2 : BPM
--  ENC3 : Add/Remove
--  KEY3 : Play/Pause
-- PAGE 2:
--  ENC2 : Root note/Select
--  ENC3 : Scale type/Note edit
--  KEY3 : Scale/Custom
-- PAGE 3:
--  Load/Save/Delete
--
-- v1.0.0
-- Concept Jay Gilligan
-- Code Mark Eats
--

local MusicUtil = require "mark_eats/musicutil"
local UI = require "mark_eats/ui"
local BeatClock = require "beatclock"
local MollyThePoly = require "mark_eats/mollythepoly"

engine.name = "MollyThePoly"

local specs = {}
specs.OUTPUT = {"Audio", "MIDI", "Audio + MIDI"}
specs.STEP_LENGTH_NAMES = {"1 bar", "1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16", "1/24", "1/32", "1/48", "1/64"}
specs.STEP_LENGTH_DIVIDERS = {1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64}

local DATA_FILE_PATH = data_dir .. "mark_eats/loom.data"

local SCREEN_FRAMERATE = 15
local screen_dirty = true
local GRID_FRAMERATE = 30
local grid_dirty = true
local grid_leds = {}
local grid_w, grid_h = 16, 8

local beat_clock

local grid_device
local midi_in_device
local midi_out_device
local midi_out_channel

local notes = {}
local triggers = {}

local root_note = 36
local scale_type = 1
local custom_scale = false
local scale_edit_id = 1
local scale_notes = {}
local scale_note_names = {}
local SCALES_LEN = #MusicUtil.SCALES

local active_notes = {}
local down_marks = {}
local down_keys = {}
local trails = {}
local remove_animations = {}
local DOWN_ANI_LENGTH = 0.2
local REMOVE_ANI_LENGTH = 0.4
local TRAIL_ANI_LENGTH = 6.0

local pages
local tabs
local playback_icon
local add_remove_animations = {}
local ADD_REMOVE_ANI_LENGTH = 0.2
local notes_changed_timeout = 0
local triggers_changed_timeout = 0
local NOTES_TRIGGERS_TIMEOUT_LENGTH = 0.2
local save_data = {version = 1, patterns = {}}
local save_menu_items = {"Load", "Save", "Delete"}
local save_slot_list
local save_menu_list
local last_edited_slot = 0
local confirm_message
local confirm_function


local function copy_object(object)
  if type(object) ~= 'table' then return object end
  local result = {}
  for k, v in pairs(object) do result[copy_object(k)] = copy_object(v) end
  return result
end

local function update_save_slot_list()
  local entries = {}
  for i = 1, math.min(#save_data.patterns + 1, 999) do
    local entry
    if i <= #save_data.patterns then
      entry = save_data.patterns[i].name
    else
      entry = "-"
    end
    if i == last_edited_slot then entry = entry .. "*" end
    entries[i] = i .. ". " .. entry
  end
  save_slot_list.entries = entries
end

local function read_data()
  local disk_data = tab.load(DATA_FILE_PATH)
  if disk_data and disk_data.version then
    if disk_data.version == 1 then
      save_data = disk_data
    else
      print("Unrecognized data, version " .. disk_data.version)
    end
  end
  update_save_slot_list()
end

local function write_data()
  tab.save(save_data, DATA_FILE_PATH)
end

local function load_pattern(index)
  if index > #save_data.patterns then return end
  
  local pattern = copy_object(save_data.patterns[index])
  params:set("BPM", pattern.bpm)
  params:set("Step Length", pattern.step_length)
  params:set("Pattern Width", pattern.pattern_width)
  params:set("Pattern Height", pattern.pattern_height)
  params:set("Min Velocity", pattern.min_velocity)
  params:set("Max Velocity", pattern.max_velocity)
  notes = pattern.notes
  triggers = pattern.triggers
  root_note = pattern.root_note
  scale_type = pattern.scale_type
  custom_scale = pattern.custom_scale
  scale_notes = pattern.scale_notes
  scale_note_names = MusicUtil.note_nums_to_names(scale_notes, true)
  
  last_edited_slot = index
  update_save_slot_list()
  grid_dirty = true
end

local function save_pattern(index)
  local pattern = {}
  pattern.name = os.date("%b %d %H:%M")
  pattern.bpm = params:get("BPM")
  pattern.step_length = params:get("Step Length")
  pattern.pattern_width = params:get("Pattern Width")
  pattern.pattern_height = params:get("Pattern Height")
  pattern.min_velocity = params:get("Min Velocity")
  pattern.max_velocity = params:get("Max Velocity")
  pattern.notes = notes
  pattern.triggers = triggers
  pattern.root_note = root_note
  pattern.scale_type = scale_type
  pattern.custom_scale = custom_scale
  pattern.scale_notes = scale_notes
  
  save_data.patterns[index] = copy_object(pattern)
  last_edited_slot = index
  update_save_slot_list()
  
  write_data()
end

local function delete_pattern(index)
  if index > 0 and index <= #save_data.patterns then
    table.remove(save_data.patterns, index)
    if index == last_edited_slot then
      last_edited_slot = 0
    elseif index < last_edited_slot then
      last_edited_slot = last_edited_slot - 1
    end
  end
  update_save_slot_list()
  
  write_data()
end


local function note_on(note_num)
  
  local min_vel, max_vel = params:get("Min Velocity"), params:get("Max Velocity")
  if min_vel > max_vel then
    max_vel = min_vel
  end
  local note_midi_vel = math.random(min_vel, max_vel)
  
  -- print("note_on", note_num, note_midi_vel)
  
  -- Audio engine out
  if params:get("Output") == 1 or params:get("Output") == 3 then
    engine.noteOn(note_num, MusicUtil.note_num_to_freq(note_num), note_midi_vel / 127)
  end
  
  -- MIDI out
  if (params:get("Output") == 2 or params:get("Output") == 3) then
    midi_out_device.note_on(note_num, note_midi_vel, midi_out_channel)
  end
  
end

local function note_off(note_num)
  
  -- print("note_off", note_num)
  
  -- Audio engine out
  if params:get("Output") == 1 or params:get("Output") == 3 then
    engine.noteOff(note_num)
  end
  
  -- MIDI out
  if (params:get("Output") == 2 or params:get("Output") == 3) then
    midi_out_device.note_off(note_num, nil, midi_out_channel)
  end
  
end

local function all_notes_off()
  
  -- Audio engine out
  engine.noteKillAll()
  
  -- MIDI out
  if (params:get("Output") == 2 or params:get("Output") == 3) then
    for k, a in pairs(active_notes) do
      midi_out_device.note_off(a, 96, midi_out_channel)
    end
  end
  
  active_notes = {}
end

local function start_remove_animation(orientation, position)
  local ani = {orientation = orientation, position = position, time_remaining = REMOVE_ANI_LENGTH }
  table.insert(remove_animations, ani)
end

local function start_add_remove_animation(icon)
  if #add_remove_animations < 16 then
    local ani = {icon = icon, x = math.random(118) + 5, y = math.random(54) + 5, time_remaining = ADD_REMOVE_ANI_LENGTH}
    table.insert(add_remove_animations, ani)
    screen_dirty = true
  end
end

local function add_note(position, head, length, direction, show_screen_animation)
  length = length or 1
  direction = direction or 1
  
  local note = {position = position, head = head, length = length, advance_countdown = length, direction = direction, active = false}
  table.insert(notes, note)
  
  if show_screen_animation then
    start_add_remove_animation("note")
  else
    notes_changed_timeout = NOTES_TRIGGERS_TIMEOUT_LENGTH
  end
  if pages.index == 1 or show_screen_animation then screen_dirty = true end
  grid_dirty = true
end

local function add_trigger(position, head, length, direction, show_screen_animation)
  length = length or 1
  direction = direction or 1
  
  local trigger = {position = position, head = head, length = length, advance_countdown = length, direction = direction, active = false}
  table.insert(triggers, trigger)
  
  if show_screen_animation then
    start_add_remove_animation("trigger")
  else
    triggers_changed_timeout = NOTES_TRIGGERS_TIMEOUT_LENGTH
  end
  if pages.index == 1 or show_screen_animation then screen_dirty = true end
  grid_dirty = true
end

local function remove_note(position, show_screen_animation, silent)
  local note
  if position then
    for k, v in pairs(notes) do
      if v.position == position then
        note = table.remove(notes, k)
        break
      end
    end
  else
    note = table.remove(notes)
  end
  
  if note and not silent then
    if show_screen_animation then
      start_add_remove_animation("remove")
    else
      notes_changed_timeout = NOTES_TRIGGERS_TIMEOUT_LENGTH
    end
    start_remove_animation("col", note.position)
    if pages.index == 1 or show_screen_animation then screen_dirty = true end
    grid_dirty = true
  end
end

local function remove_trigger(position, show_screen_animation, silent)
  local trigger
  if position then
    for k, v in pairs(triggers) do
      if v.position == position then
        trigger = table.remove(triggers, k)
        break
      end
    end
  else
    trigger = table.remove(triggers)
  end
  
  if trigger and not silent then
    if show_screen_animation then
      start_add_remove_animation("remove")
    else
      triggers_changed_timeout = NOTES_TRIGGERS_TIMEOUT_LENGTH
    end
    start_remove_animation("row", trigger.position)
    if pages.index == 1 or show_screen_animation then screen_dirty = true end
    grid_dirty = true
  end
end

local function add_random()
  
  if #notes >= grid_w and #triggers >= grid_h then return end
  
  -- Note
  if math.random() >= 0.5 then
    
    local available_positions = {}
    for i = 1, grid_w do
      local available = true
      for kn, vn in pairs(notes) do
        if vn.position == i then
          available = false
          break
        end
      end
      if available then
        table.insert(available_positions, i)
      end
    end
    
    if #available_positions > 0 then
      local length = util.round(math.pow(math.random(), 4) * (grid_h - 2) + 1)
      add_note(available_positions[math.random(#available_positions)], math.random(grid_h), length, (math.random() >= 0.5 and 1 or -1), true)
    end
    
  -- Trigger
  else
    
    local available_positions = {}
    for i = 1, grid_h do
      local available = true
      for kt, vt in pairs(triggers) do
        if vt.position == i then
          available = false
          break
        end
      end
      if available then
        table.insert(available_positions, i)
      end
    end
    
    if #available_positions > 0 then
      local length = util.round(math.pow(math.random(), 4) * (grid_w - 2) + 1)
      add_trigger(available_positions[math.random(#available_positions)], math.random(grid_w), length, (math.random() >= 0.5 and 1 or -1), true)
    end
    
  end
end

local function remove_last()
  if #notes == 0 and #triggers == 0 then return end
  
  if math.random() >= 0.5 then
    remove_note(nil, true)
  else
    remove_trigger(nil, true)
  end
end

local function advance_step()
  
  if grid_device then
    grid_w = grid_device.cols()
    grid_h = grid_device.rows()
    if grid_w ~= 8 and grid_w ~= 16 then grid_w = 16 end
    if grid_h ~= 8 and grid_h ~= 16 then grid_h = 8 end
  end
  
  for _, n in pairs(notes) do
    n.advance_countdown = n.advance_countdown - 1
    if n.advance_countdown == 0 then
      n.advance_countdown = n.length
      if n.direction > 0 then n.head = n.head % params:get("Pattern Height") + 1
      else n.head = (n.head + params:get("Pattern Height") - 2) % params:get("Pattern Height") + 1 end
    end
    n.active = false
  end
  
  local active_notes_this_step = {}
  
  for _, t in pairs(triggers) do
    
    -- Progress
    t.advance_countdown = t.advance_countdown - 1
    if t.advance_countdown == 0 then
      t.advance_countdown = t.length
      if t.direction > 0 then t.head = t.head % params:get("Pattern Width") + 1
      else t.head = (t.head + params:get("Pattern Width") - 2) % params:get("Pattern Width") + 1 end
    end
    t.active = false
    
    -- Check for intersections and generate trails
    local tx
    for ti = 0, t.length - 1 do
      tx = t.head + (ti * t.direction * -1)
      tx = (tx - 1) % params:get("Pattern Width") + 1
      if tx <= grid_w then trails[tx][t.position] = TRAIL_ANI_LENGTH end
      for _, n in pairs(notes) do
        local ny
        for ni = 0, n.length - 1 do
          ny = n.head + (ni * n.direction * -1)
          ny = (ny - 1) % params:get("Pattern Height") + 1
          if ny <= grid_h then trails[n.position][ny] = TRAIL_ANI_LENGTH end
          if tx == n.position and t.position == ny then
            if not n.active then
              table.insert(active_notes_this_step, scale_notes[n.position])
            end
            n.active = true
            t.active = true
            break
          end
        end
      end
    end
  end
  
  -- Generate trails for notes if need be
  if #triggers == 0 then
    for _, n in pairs(notes) do
      local ny
      for ni = 0, n.length - 1 do
        ny = n.head + (ni * n.direction * -1)
        ny = (ny - 1) % params:get("Pattern Height") + 1
        if ny <= grid_h then trails[n.position][ny] = TRAIL_ANI_LENGTH end
      end
    end
  end
  
  -- Work out which need noteOffs
  for i = #active_notes, 1, -1 do
    local still_active = false
    for sk, sa in pairs(active_notes_this_step) do
      if sa == active_notes[i] then
        still_active = true
        table.remove(active_notes_this_step, sk)
        break
      end
    end
    if not still_active then
      note_off(active_notes[i])
      table.remove(active_notes, i)
    end
  end
  
  -- Add remaining, the new notes
  for _, sa in pairs(active_notes_this_step) do
    if #active_notes < params:get("Max Active Notes") then
      note_on(sa)
      table.insert(active_notes, sa)
    end
  end
  
  screen_dirty = true
  grid_dirty = true
end

local function reset_step()
  beat_clock:reset()
end


local function grid_update()
  
  if #down_marks > 0 or #remove_animations > 0 then grid_dirty = true end
  
  local time_increment = 1 / GRID_FRAMERATE
  
  -- Trails
  for x = 1, grid_w do
    for y = 1, grid_h do
      trails[x][y] = util.clamp(trails[x][y] - time_increment, 0, TRAIL_ANI_LENGTH)
      if trails[x][y] > 0 then grid_dirty = true end
    end
  end
  
  -- Down marks
  for i = #down_marks, 1, -1 do
    if not down_marks[i].active then
      down_marks[i].time_remaining = down_marks[i].time_remaining - time_increment
      if down_marks[i].time_remaining <= 0 then
        table.remove(down_marks, i)
      end
    end
  end
  
  -- Remove animations
  for i = #remove_animations, 1, -1 do
    remove_animations[i].time_remaining = remove_animations[i].time_remaining - time_increment
    if remove_animations[i].time_remaining <= 0 then
      table.remove(remove_animations, i)
    end
  end
  
end

local function screen_update()
  
  if pages.index == 1 and #add_remove_animations > 0 then screen_dirty = true end
  
  local time_increment = 1 / SCREEN_FRAMERATE
  
  -- Add/remove animations
  for i = #add_remove_animations, 1, -1 do
    add_remove_animations[i].time_remaining = add_remove_animations[i].time_remaining - time_increment
    if add_remove_animations[i].time_remaining <= 0 then
      table.remove(add_remove_animations, i)
    end
  end
  
  notes_changed_timeout = util.clamp(notes_changed_timeout - time_increment, 0, NOTES_TRIGGERS_TIMEOUT_LENGTH)
  triggers_changed_timeout = util.clamp(triggers_changed_timeout - time_increment, 0, NOTES_TRIGGERS_TIMEOUT_LENGTH)
  
end

local function init_scale()
  scale_notes = MusicUtil.generate_scale_of_length(root_note, scale_type, 16)
  while #scale_notes < 16 do
    table.insert(scale_notes, scale_notes[#scale_notes])
  end
  scale_note_names = MusicUtil.note_nums_to_names(scale_notes, true)
end


-- Encoder input
function enc(n, delta)
  
  -- Global
  if n == 1 then
    pages:set_index_delta(util.clamp(delta, -1, 1), false)
    save_menu_list:set_index(1)
  
  else
    
    -- Time
    if pages.index == 1 then
      
      if n == 2 and beat_clock.external == false then
        params:delta("BPM", delta)
        
      elseif n == 3 then
        if delta > 0 then
          add_random()
        else
          remove_last()
        end
        
      end
      
    -- Pitch
    elseif pages.index == 2 then
      
      if custom_scale then
        if n == 2 then
          scale_edit_id = util.clamp(scale_edit_id + util.clamp(delta, -1, 1), 1, grid_w)
          
        elseif n == 3 then
          scale_notes[scale_edit_id] = util.clamp(scale_notes[scale_edit_id] + delta, 0, 127)
          scale_note_names = MusicUtil.note_nums_to_names(scale_notes, true)
        end
        
      else
        if n == 2 then
          root_note = util.clamp(root_note + util.clamp(delta, -1, 1), 0, 127)
          init_scale()
          
        elseif n == 3 then
          scale_type = util.clamp(scale_type + util.clamp(delta, -1, 1), 1, SCALES_LEN)
          init_scale()
        end
      end
      
    -- Load/Save
    elseif pages.index == 3 then
      
      if n == 2 then
        save_slot_list:set_index_delta(util.clamp(delta, -1, 1))
        
      elseif n == 3 then
        save_menu_list:set_index_delta(util.clamp(delta, -1, 1))
        
      end
      
    end
  end
  
  screen_dirty = true
  
end

-- Key input
function key(n, z)
  
  if z == 1 then
    
    -- Key 2
    if n == 2 then
      
      if confirm_message then
        confirm_message = nil
        confirm_function = nil
      
      else
        pages:set_index_delta(1, true)
        save_menu_list:set_index(1)
      end
    
    -- Key 3
    elseif n == 3 then
      
      if confirm_message then
        confirm_function()
        confirm_message = nil
        confirm_function = nil
        
      else
      
        -- Time
        if pages.index == 1 then
          if not beat_clock.external then
            if beat_clock.playing then
              beat_clock:stop()
              all_notes_off()
            else
              beat_clock:start()
            end
          end
        
        -- Pitch
        elseif pages.index == 2 then
          custom_scale = not custom_scale
          if not custom_scale then
            init_scale()
          else
            scale_edit_id = 1
          end
        
        -- Load/Save
        elseif pages.index == 3 then
          
          -- Load
          if save_menu_list.index == 1 then
            load_pattern(save_slot_list.index)
          
          -- Save
          elseif save_menu_list.index == 2 then
            if save_slot_list.index < #save_slot_list.entries then
              confirm_message = UI.Message.new({"Replace saved pattern?"})
              confirm_function = function() save_pattern(save_slot_list.index) end
            else
              save_pattern(save_slot_list.index)
            end
            
          -- Delete
          elseif save_menu_list.index == 3 then
            if save_slot_list.index < #save_slot_list.entries then
              confirm_message = UI.Message.new({"Delete saved pattern?"})
              confirm_function = function() delete_pattern(save_slot_list.index) end
            end
            
          end
        end
      end
    end
    
    screen_dirty = true
  end
end


-- Grid event
local function grid_event(x, y, z)
  
  if z == 1 then
    
    -- Is there a relevant down mark?
    local relevant_down_mark = nil
    for k, v in pairs(down_marks) do
      
      -- Re-activate fading down mark
      if v.x == x and v.y == y then
        
        v.active = true
        v.time_remaining = DOWN_ANI_LENGTH
        relevant_down_mark = v
        break
      
      -- Note
      elseif v.x == x and v.active then
        
        local three_keys = false
        for kk, kv in pairs(down_keys) do
          if kv.x == x then
            three_keys = true
            break
          end
        end
        
        if three_keys then
          remove_note(x, true, false)
        else
          remove_note(x, false, true)
          add_note(x, v.y, math.abs(v.y - y), (y < v.y and 1 or -1), false)
        end
        relevant_down_mark = v
        
      -- Trigger
      elseif v.y == y and v.active then
        
        local three_keys = false
        for kk, kv in pairs(down_keys) do
          if kv.y == y then
            three_keys = true
            break
          end
        end
        
        if three_keys then
          remove_trigger(y, true, false)
        else
          remove_trigger(y, false, true)
          add_trigger(y, v.x, math.abs(v.x - x), (x < v.x and 1 or -1), false)
        end
        relevant_down_mark = v
        
      end
    end
    
    -- Make it the down mark
    if relevant_down_mark then
      if relevant_down_mark.x ~= x or relevant_down_mark.y ~= y then
        table.insert(down_keys, {x = x, y = y})
      end
    else
      table.insert(down_marks, {active = true, x = x, y = y, time_remaining = DOWN_ANI_LENGTH})
    end
    
  else
    for _, v in pairs(down_marks) do
      if v.x == x and v.y == y then
        v.active = false
        break
      end
    end
    for k, v in pairs(down_keys) do
      if v.x == x and v.y == y then
        table.remove(down_keys, k)
        break
      end
    end
    
  end
  
  grid_dirty = true
end


function init()
  
  for x = 1, 16 do
    grid_leds[x] = {}
    trails[x] = {}
    for y = 1, 16 do
      trails[x][y] = 0
    end
  end
  
  for k, v in pairs(MusicUtil.SCALES) do
    if v.name == "Major Pentatonic" then
      scale_type = k
      break
    end
  end
  init_scale()
  
  grid_device = grid.connect(1)
  grid_device.event = grid_event
  
  beat_clock = BeatClock.new()
  
  beat_clock.on_step = advance_step
  beat_clock.on_select_internal = function()
    beat_clock:start()
    screen_dirty = true
  end
  beat_clock.on_select_external = function()
    reset_step()
    screen_dirty = true
  end
  
  midi_in_device = midi.connect(1)
  midi_in_device.event = function(data)
    beat_clock:process_midi(data)
    if not beat_clock.playing and playback_icon.status == 1 then
      screen_dirty = true
    end
  end
  
  midi_out_device = midi.connect(1)
  midi_out_device.event = function() end
  
  local screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function()
    screen_update()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  
  local grid_redraw_metro = metro.alloc()
  grid_redraw_metro.callback = function()
    grid_update()
    if grid_dirty and grid_device.attached() then
      grid_dirty = false
      grid_redraw()
    end
  end

  
  -- Add params
  
  params:add_number("Grid Device", 1, 4, 1)
  params:set_action("Grid Device", function(value)
    grid_device.all(0)
    grid_device.refresh()
    grid_device:reconnect(value)
  end)
  
  params:add_option("Output", specs.OUTPUT)
  params:set_action("Output", all_notes_off)
  
  params:add_number("MIDI Out Device", 1, 4, 1)
  params:set_action("MIDI Out Device", function(value)
    midi_out_device:reconnect(value)
  end)
  
  params:add_number("MIDI Out Channel", 1, 16, 1)
  params:set_action("MIDI Out Channel", function(value)
    all_notes_off()
    midi_out_channel = value
  end)
  
  params:add_number("Max Active Notes", 1, 16, 16)
  
  params:add_option("Clock", {"Internal", "External"}, beat_clock.external or 2 and 1)
  params:set_action("Clock", function(value)
    beat_clock:clock_source_change(value)
  end)
  
  params:add_number("Clock MIDI In Device", 1, 4, 1)
  params:set_action("Clock MIDI In Device", function(value)
    midi_in_device:reconnect(value)
  end)
  
  params:add_option("Clock Out", {"Off", "On"}, beat_clock.send or 2 and 1)
  params:set_action("Clock Out", function(value)
    if value == 1 then beat_clock.send = false
    else beat_clock.send = true end
  end)
  
  params:add_separator()
  
  params:add_number("BPM", 1, 480, beat_clock.bpm)
  params:set_action("BPM", function(value)
    beat_clock:bpm_change(value)
    screen_dirty = true
  end)
  
  params:add_option("Step Length", specs.STEP_LENGTH_NAMES, 10)
  params:set_action("Step Length", function(value)
    beat_clock.steps_per_beat = specs.STEP_LENGTH_DIVIDERS[value] / 4
    beat_clock:bpm_change(beat_clock.bpm)
  end)
  
  params:add_number("Pattern Width", 8, 64, 16)
  params:add_number("Pattern Height", 8, 64, 16)
  
  params:add_number("Min Velocity", 1, 127, 80)
  params:add_number("Max Velocity", 1, 127, 100)
  
  params:add_separator()
  
  midi_out_channel = params:get("MIDI Out Channel")
  
  -- Engine params
  
  MollyThePoly.add_params()
  
  -- UI
  
  pages = UI.Pages.new(page_id, 3)
  tabs = UI.Tabs.new()
  save_slot_list = UI.ScrollingList.new(5, 14, 1, {})
  save_menu_list = UI.List.new(92, 25, 1, save_menu_items)
  playback_icon = UI.PlaybackIcon.new(121, 1)
  
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  grid_redraw_metro:start(1 / GRID_FRAMERATE)
  beat_clock:start()
  
  -- Data
  read_data()
  
end


function grid_redraw()
  
  local DOWN_BRIGHTNESS = 3
  local TRAIL_BRIGHTNESS = 3
  local OUTSIDE_BRIGHTNESS = 3
  local INACTIVE_BRIGHTNESS = 10
  local ACTIVE_BRIGHTNESS = 15
  
  local brightness
  
  -- Draw trails
  for x = 1, 16 do
    for y = 1, 16 do
      if trails[x][y] then grid_leds[x][y] = util.round(util.linlin(0, TRAIL_ANI_LENGTH, 0, TRAIL_BRIGHTNESS, trails[x][y]))
      else grid_leds[x][y] = 0 end
      if (x > params:get("Pattern Width") or y > params:get("Pattern Height")) and grid_leds[x][y] < OUTSIDE_BRIGHTNESS then grid_leds[x][y] = OUTSIDE_BRIGHTNESS end
    end
  end
  
  -- Draw down marks
  for k, v in pairs(down_marks) do
    brightness = util.round(util.linlin(0, DOWN_ANI_LENGTH, 0, DOWN_BRIGHTNESS, v.time_remaining))
    for i = 1, grid_w do
      if grid_leds[i][v.y] < brightness then grid_leds[i][v.y] = brightness end
    end
    for i = 1, grid_h do
      if grid_leds[v.x][i] < brightness then grid_leds[v.x][i] = brightness end
    end
    if v.active and grid_leds[v.x][v.y] < INACTIVE_BRIGHTNESS then grid_leds[v.x][v.y] = INACTIVE_BRIGHTNESS end
  end
  
  -- Draw remove animations
  for _, v in pairs(remove_animations) do
    brightness = util.round(util.linlin(0, REMOVE_ANI_LENGTH, 0, 15, v.time_remaining))
    if v.orientation == "row" then
      for i = 1, grid_w do
        if grid_leds[i][v.position] < brightness then grid_leds[i][v.position] = brightness end
      end
    else
      for i = 1, grid_h do
        if grid_leds[v.position][i] < brightness then grid_leds[v.position][i] = brightness end
      end
    end
  end
  
  -- Draw notes
  for _, n in pairs(notes) do
    if n.active then brightness = ACTIVE_BRIGHTNESS
    else brightness = INACTIVE_BRIGHTNESS end
    if n.position <= grid_w then
      local ny
      for i = 0, n.length - 1 do
        ny = n.head + (i * n.direction * -1)
        ny = (ny - 1) % params:get("Pattern Height") + 1
        if ny > 0 and ny <= grid_h then
          grid_leds[n.position][ny] = brightness
        end
      end
    end
  end
  
  -- Draw triggers
  for _, t in pairs(triggers) do
    if t.active then brightness = ACTIVE_BRIGHTNESS
    else brightness = INACTIVE_BRIGHTNESS end
    if t.position <= grid_h then
      local tx
      for i = 0, t.length - 1 do
        tx = t.head + (i * t.direction * -1)
        tx = (tx - 1) % params:get("Pattern Width") + 1
        if tx > 0 and tx <= grid_w then
          grid_leds[tx][t.position] = brightness
        end
        
      end
    end
  end
  
  for x = 1, grid_w do
    for y = 1, grid_h do
      grid_device.led(x, y, grid_leds[x][y])
    end
  end
  grid_device.refresh()
  
end


local function draw_add_remove_icons()
  
  screen.level(15)
  screen.line_width(1)
  
  local RADIUS = 4
  for k, v in pairs(add_remove_animations) do
    
    if v.icon == "remove" then
      screen.move(v.x - RADIUS, v.y - RADIUS)
      screen.line(v.x + RADIUS, v.y + RADIUS)
      screen.stroke()
      screen.move(v.x + RADIUS, v.y - RADIUS)
      screen.line(v.x - RADIUS, v.y + RADIUS)
      screen.stroke()
      
    elseif v.icon == "trigger" then
      screen.move(v.x - RADIUS - 2, v.y)
      screen.line(v.x + RADIUS, v.y)
      screen.stroke()
      screen.move(v.x, v.y - RADIUS)
      screen.line(v.x + RADIUS, v.y)
      screen.line(v.x, v.y + RADIUS)
      screen.stroke()
      
    else
      screen.circle(v.x, v.y + RADIUS * 0.5, RADIUS * 0.5)
      screen.stroke()
      screen.move(v.x + RADIUS * 0.5, v.y + RADIUS * 0.5)
      screen.line(v.x + RADIUS * 0.5, v.y - RADIUS - 2)
      screen.line(v.x + RADIUS * 0.5 + 3, v.y - RADIUS + 1)
      screen.stroke()
      
    end
  end
end

function redraw()
  
  screen.clear()
  screen.aa(1)
  
  if confirm_message then
    confirm_message:redraw()
    
  else
  
    pages:redraw()
    
    if beat_clock.playing then
      playback_icon.status = 1
    else
      playback_icon.status = 3
    end
    playback_icon:redraw()
    
    -- Time
    if pages.index == 1 then
      
      -- BPM
      screen.move(5, 29)
      if beat_clock.external then
        screen.level(3)
        screen.text("External")
      else
        screen.level(15)
        screen.text(params:get("BPM") .. " BPM")
      end
      
      -- Status
      if notes_changed_timeout > 0 then screen.level(15)
      else screen.level(3) end
      screen.move(69, 29)
      screen.text("Notes " .. #notes)
      
      if triggers_changed_timeout > 0 then screen.level(15)
      else screen.level(3) end
      screen.move(69, 40)
      screen.text("Triggers " .. #triggers)
      
    -- Pitch
    elseif pages.index == 2 then
      
      -- Scale name
      screen.move(5, 10)
      if custom_scale then
        screen.level(3)
        screen.text("Custom")
      else
        screen.level(15)
        screen.text(MusicUtil.note_num_to_name(root_note, true) .. " " .. MusicUtil.SCALES[scale_type].name)
      end
      
      -- Scale notes
      local x, y = 5, 14
      local COLS = 4
      for i = 1, grid_w do
        if (i - 1) % COLS == 0 then x, y = 5, y + 11 end
        
        local is_active = false
        for _, n in pairs(notes) do
          if n.position == i and n.active then
            is_active = true
            break
          end
        end
        
        local underline_length = 10
        if string.len(scale_note_names[i]) > 3 then
          underline_length = 18
        elseif string.len(scale_note_names[i]) > 2 then
          underline_length = 16
        end
        if custom_scale and i == scale_edit_id then
          screen.level(15)
          screen.move(x - 1, y + 2.5)
          screen.line(x + underline_length, y + 2.5)
          screen.stroke()
        end
        
        if is_active or (custom_scale and i == scale_edit_id) then screen.level(15)
        else screen.level(3) end
        screen.move(x, y)
        screen.text(scale_note_names[i])
        
        x = x + 25
      end
      
    -- Load/Save
    elseif pages.index == 3 then
      
      save_slot_list:redraw()
      save_menu_list:redraw()
      
    end
    
    -- Icons
    screen.fill()
    draw_add_remove_icons()
    
  end
  
  screen.update()
end


function cleanup()
  
end
