-- Graph Demo
--
-- Four types of graphs you
-- can use in your own scripts.
-- 
-- ENC2/3 : Adjust graph
-- KEY2 : Next demo
-- KEY3 : Shift
-- 
-- No sounds, just graphs!
--
-- v1.0.0 Mark Eats
--


-- Include the Graph classes
local Graph = require "mark_eats/graph"
local EnvGraph = require "mark_eats/envgraph"

local MusicUtil = require "mark_eats/musicutil"

-- This is where we will store the graph
local demo_graph = nil
local graph_id = 1

-- Misc vars for the demos
local wave_shape = 0
local wave_freq = 2
local env_vals = {a = 0.7, d = 1, s = 0.45, r = 1.8, c = -4}
local point_vals = {}
local seq_vals = {}
local step = 1
local step_metro
local highlight_progress = 1
local highlight_id = 1

local SCREEN_FRAMERATE = 15
local screen_refresh_metro
local screen_dirty = true
local shift_key = false

engine.name = "TestSine"


function init()
  engine.amp(0)
  
  -- Dummy data for graphs
  for i = 1, 12 do point_vals[i] = math.random() * 2 - 1 end
  for i = 1, 16 do seq_vals[i] = math.random(48, 72) end
  
  init_graph(graph_id)
  
  -- Metro to call redraw()
  screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function(stage)
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  
  -- Metro for sequencer demo
  step_metro = metro.alloc()
  step_metro.callback = function(stage)
    if graph_id == 4 then
      step = step % 16 + 1
      screen_dirty = true
    end
  end
  step_metro:start(0.25)
  
end


-- This is where we create the graphs
function init_graph(id)
  
  -- Wave shape graph
  if graph_id == 1 then
    
    -- Graphs are created with Graph.new and take the following arguments (all optional):
    -- Graph.new(x_min, x_max, x_warp, y_min, y_max, y_warp, style, show_x_axis, show_y_axis)
    demo_graph = Graph.new(0, 2, "lin", -1, 1, "lin", nil, true, false)
    -- We then set its position and size.
    demo_graph:set_position_and_size(5, 7, 118, 40)
    
    -- Add a function to the graph instance that takes an x value and outputs the y value.
    local wave_func = function(x)
        local sine = math.sin(x * wave_freq * math.pi)
        local saw = (1 - (x * wave_freq * 0.5 - 0.5) % 1) * 2 - 1
        return sine * (1 - wave_shape) + saw * wave_shape
    end
    -- Set sample_quality to 3 (high)
    demo_graph:add_function(wave_func, 3)
  
  
  -- ADSR graph
  elseif graph_id == 2 then
    
    -- The EnvGraph class is used for creating common envelope graphs. Passing nil means it will use a default value.
    -- EnvGraph.new_adsr(x_min, x_max, y_min, y_max, attack, decay, sustain, release, level, curve)
    demo_graph = EnvGraph.new_adsr(0, 8, nil, nil, env_vals.a, env_vals.d, env_vals.s, env_vals.r, 1, env_vals.c)
    demo_graph:set_position_and_size(66, 11, 58, 42)
    
    
  -- Selectable points graph
  elseif graph_id == 3 then
    
    -- This graph is a 'points' graph (as opposed to a 'function' graph).
    -- It is set to contain 12 equally spaced points from a table generated in init
    demo_graph = Graph.new(1, 12, "lin", -1, 1, "lin", "point", true, false)
    demo_graph:set_position_and_size(3, 3, 122, 58)
    for i = 1, #point_vals do
      demo_graph:add_point(i, point_vals[i])
    end
    
    -- We also highlight one of the points that will be tied to interaction.
    highlight_progress = 1
    highlight_id = 1
    demo_graph:highlight_exclusive_point(highlight_id)
    
    
  -- Simple sequencer graph
  elseif graph_id == 4 then
    
    -- This is a bar graph. It's similar to the selectable points graph but with a different visual style.
    -- The y axis is based on MIDI note numbers
    demo_graph = Graph.new(1, 16, "lin", 48, 72, "lin", "bar", false, false)
    demo_graph:set_position_and_size(9, 4, 110, 46)
    for i = 1, #seq_vals do
      demo_graph:add_point(i, seq_vals[i])
    end
    
    highlight_progress = 1
    highlight_id = 1
    demo_graph:highlight_exclusive_point(highlight_id)
  end
  
end


-- Encoder input
function enc(n, delta)
  
  -- Wave shape interaction
  if graph_id == 1 then
    
    -- ENC2 blends between the two wave shapes using a 0-1 value.
    if n == 2 then
      -- We call update_functions() whenever the wave function gets new data (here, wave_shape is changed)
      wave_shape = util.clamp(wave_shape + delta * 0.01, 0, 1)
      demo_graph:update_functions()
      
    -- ENC3 set the wave frequency, 1-10.
    elseif n == 3 then
      wave_freq = util.clamp(wave_freq + delta * 0.03, 1, 10)
      demo_graph:update_functions()
    end
    
  -- ADSR interaction
  elseif graph_id == 2 then
    
    -- The ENC2 and ENC3 change attack and decay. When KEY3 is held they switch to sustain and release.
    local change = delta * 0.01
    
    if n == 2 then
      if not shift_key then
        env_vals.a = util.clamp(env_vals.a + change, 0, 2.5)
      else
        env_vals.s = util.clamp(env_vals.s + change, 0, 1)
      end
    elseif n == 3 then
      if not shift_key then
        env_vals.d = util.clamp(env_vals.d + change, 0, 2)
      else
        env_vals.r = util.clamp(env_vals.r - change, 0, 2.5)
      end
    end
    
    -- The ADSR values are stored in env_vals in this script then updated in the graph here.
    demo_graph:edit_adsr(env_vals.a, env_vals.d, env_vals.s, env_vals.r, 1, env_vals.c)
  
  -- Points interation
  elseif graph_id == 3 then
    
    -- ENC2 changes the highlight_id which is fed to the graph.
    if n == 2 then
      highlight_progress = util.clamp(highlight_progress + delta * 0.1, 1, 12)
      highlight_id = util.round(highlight_progress)
      demo_graph:highlight_exclusive_point(highlight_id)
      
    -- ENC3 changes the highlighted point value.
    elseif n == 3 then
      -- We could store the values in the graph but here we store the data model in this class and update the graph view from it.
      point_vals[highlight_id] = util.clamp(point_vals[highlight_id] + delta * 0.01, demo_graph:get_y_min(), demo_graph:get_y_max())
      demo_graph:edit_point(highlight_id, nil, point_vals[highlight_id])
    end
    
  -- Sequencer interaction
  elseif graph_id == 4 then
    
    -- ENC2 changes the highlight_id again.
    if n == 2 then
      highlight_progress = util.clamp(highlight_progress + delta * 0.1, 1, 16)
      highlight_id = util.round(highlight_progress)
      demo_graph:highlight_exclusive_point(highlight_id)
      
    -- ENC3 sets the MIDI note value.
    elseif n == 3 then
      seq_vals[highlight_id] = util.clamp(seq_vals[highlight_id] + util.clamp(delta, -1, 1), demo_graph:get_y_min(), demo_graph:get_y_max())
      demo_graph:edit_point(highlight_id, nil, seq_vals[highlight_id])
    end
    
  end
  
  screen_dirty = true
end

-- Key input
function key(n, z)
  
  -- KEY2 advances to the next graph.
  if n == 2 and z == 1 then
    
    -- Increment graph_id
    graph_id = graph_id + 1
    if graph_id > 4 then graph_id = 1 end
    
    -- Init a new graph.
    init_graph(graph_id)
    
  -- KEY3 is a shift key used for additional functionality in some of the graphs.
  elseif n == 3 then
    shift_key =  z > 0 and true or false
    
    if graph_id == 3 then
      if shift_key then demo_graph:set_style("line")
      else demo_graph:set_style("point") end
    end
  end
  
  screen_dirty = true
end


-- Drawing
function redraw()
  screen.clear()
  screen.aa(1)
  
  -- Don't panic! Only one line of this redraw function is used to draw the graph, everything else relates to the supporting text and graphics.
  
  -- Draw wave shape text
  if graph_id == 1 then
    screen.level(15)
    screen.move(5, 60)
    screen.text("Sine")
    screen.move(38, 60)
    screen.text_center("Saw")
    screen.level(3)
    screen.rect(26 * wave_shape + 4, 62, 17 + 1 * (1 - wave_shape), 1)
    screen.fill()
  
  -- Draw ADSR text
  elseif graph_id == 2 then
    if shift_key then screen.level(3) else screen.level(15) end
    screen.move(4, 14)
    screen.text("A  " .. util.round(env_vals.a, 0.01) .."s")
    screen.move(4, 27)
    screen.text("D  " .. util.round(env_vals.d, 0.01) .."s")
    if shift_key then screen.level(15) else screen.level(3) end
    screen.move(4, 40)
    screen.text("S  " .. util.round(env_vals.s, 0.01))
    screen.move(4, 53)
    screen.text("R  " .. util.round(env_vals.r, 0.01) .."s")
    
  -- Draw sequencer position and note name
  elseif graph_id == 4 then
    screen.level(15)
    screen.rect(util.round(util.linlin(demo_graph:get_x_min(), demo_graph:get_x_max(), demo_graph:get_x(), demo_graph:get_x() + demo_graph:get_width() - 1, step)) - 2, 52, 5, 2)
    screen.fill()
    screen.move(util.linlin(demo_graph:get_x_min(), demo_graph:get_x_max(), demo_graph:get_x(), demo_graph:get_x() + demo_graph:get_width() - 1, highlight_id), 62)
    screen.text_center(MusicUtil.note_num_to_name(seq_vals[highlight_id], true))
  end
  
  -- Draw the actual graph!
  demo_graph:redraw()
  
  screen.update()
end
