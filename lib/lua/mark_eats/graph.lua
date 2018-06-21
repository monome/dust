-- Graph
-- Flexible graph drawing for envelopes, filter curves, sequencers, etc

local util = require 'util'
local tabutil = require 'tabutil'

local Graph = {}
Graph.__index = Graph

function Graph.new(x_min, x_max, y_min, y_max, style, show_x_axis, show_y_axis, x, y, w, h)
  local graph = {}
  graph.x_min = x_min or 0
  graph.x_max = x_max or 1
  graph.y_min = y_min or 0
  graph.y_max = y_max or 1
  graph.style = style or 'point'
  graph.show_x_axis = show_x_axis == nil and false or show_x_axis
  graph.show_y_axis = show_y_axis == nil and false or show_y_axis
  graph.x = x or 0
  graph.y = y or 0
  graph.w = w or 128
  graph.h = h or 64
  graph.functions = {}
  graph.points = {}
  setmetatable(graph, Graph)
  return graph
end



-------- Point methods --------

function Graph:get_point(index)
  return self.points[index]
end

-- curve defaults to 0, points will be added to the end if index is omitted
function Graph:add_point(px, py, curve, highlight, index)
  local point = {x = util.clamp(px or 0, self.x_min, self.x_max), y = util.clamp(py or 0, self.y_min, self.y_max), curve = curve or 0, highlight = highlight or false}
  if index then
    table.insert(self.points, index, point)
  else
    table.insert(self.points, point)
  end
end

function Graph:edit_point(index, px, py, curve, highlight)
  if not self.points[index] then return end
  if px then self.points[index].x = util.clamp(px, self.x_min, self.x_max) end
  if py then self.points[index].y = util.clamp(py, self.y_min, self.y_max) end
  if curve then self.points[index].curve = curve end
  if highlight ~= nil then self.points[index].highlight = highlight end
end

function Graph:remove_point(index)
  self.points[index] = nil
end

function Graph:remove_all_points()
  self.points = {}
end

function Graph:highlight_point(index)
  self.points[index].highlight = true
end

function Graph:highlight_exclusive_point(index)
  for k, v in pairs(self.points) do
    if k == index then
      v.highlight = true
    else
      v.highlight = false
    end
  end
end

function Graph:clear_all_highlights()
  for k, v in pairs(self.points) do
    v.highlight = false
  end
end



-------- Function methods --------

function Graph:get_function(index)
  return self.functions[index]
end

function Graph:add_function(func, index)
  if func(1) == nil then return end
  if index then
    table.insert(self.functions, index, func)
  else
    table.insert(self.functions, func)
  end
end

function Graph:edit_function(index, func)
  if not self.functions[index] then return end
  if func(1) ~= nil then self.functions[index] = func end
end

function Graph:remove_function(index)
  self.functions[index] = nil
end

function Graph:remove_all_functions()
  self.functions = {}
end



-------- Envelope methods --------

-- Includes DADSR, ADSR, ASR, AR (Perc)

function Graph.new_env(x_min, x_max, y_min, y_max, x, y, w, h)
  return Graph.new(x_min, x_max, y_min, y_max, 'line', false, false, x, y, w, h)
end

-- DADSR
function Graph.new_dadsr(x_min, x_max, y_min, y_max, x, y, w, h, delay, attack, decay, sustain, release, level, curve)
  local graph = Graph.new_env(x_min, x_max, y_min, y_max, x, y, w, h)
  local dl = math.max(0, delay or 0.1)
  local a = math.max(0, attack or 0.01)
  local d = math.max(0, decay or 0.3)
  graph.env_sustain = util.clamp(sustain or 0.5, 0, 1)
  local r = math.max(0, release or 1)
  local l = util.clamp(level or 1, graph.y_min, graph.y_max)
  local curve = curve or -4
  graph:add_point(0, 0)
  graph:add_point(dl, 0)
  graph:add_point(dl + a, l, curve)
  graph:add_point(dl + a + d, l * graph.env_sustain, curve)
  graph:add_point(x_max - r, l * graph.env_sustain, curve)
  graph:add_point(x_max, 0, curve)
  return graph
end

function Graph:edit_dadsr(delay, attack, decay, sustain, release, level, curve)
  if tabutil.count(self.points) ~= 6 then return end
  local dl = math.max(0, delay or self.points[2].x)
  local a = math.max(0, attack or self.points[3].x - self.points[2].x)
  local d = math.max(0, decay or self.points[4].x - self.points[3].x)
  if sustain then self.env_sustain = util.clamp(sustain, 0, 1) end
  local r = math.max(0, release or self.x_max - self.points[5].x)
  local l = util.clamp(level or self.points[3].y, self.y_min, self.y_max)
  self.points[2].x = dl;
  self.points[3].x = dl + a;
  self.points[3].y = l;
  self.points[4].x = dl + a + d;
  self.points[4].y = l * self.env_sustain;
  self.points[5].x = self.x_max - r;
  self.points[5].y = l * self.env_sustain;
  if curve ~= nil then
    for i = 3, 6 do
      self.points[i].curve = curve
    end
  end
end

-- ADSR
function Graph.new_adsr(x_min, x_max, y_min, y_max, x, y, w, h, attack, decay, sustain, release, level, curve)
  local graph = Graph.new_env(x_min, x_max, y_min, y_max, x, y, w, h)
  local a = math.max(0, attack or 0.01)
  local d = math.max(0, decay or 0.3)
  graph.env_sustain = util.clamp(sustain or 0.5, 0, 1)
  local r = math.max(0, release or 1)
  local l = util.clamp(level or 1, graph.y_min, graph.y_max)
  local curve = curve or -4
  graph:add_point(0, 0)
  graph:add_point(a, l, curve)
  graph:add_point(a + d, l * graph.env_sustain, curve)
  graph:add_point(x_max - r, l * graph.env_sustain, curve)
  graph:add_point(x_max, 0, curve)
  return graph
end

function Graph:edit_adsr(attack, decay, sustain, release, level, curve)
  if tabutil.count(self.points) ~= 5 then return end
  local a = math.max(0, attack or self.points[2].x)
  local d = math.max(0, decay or self.points[3].x - self.points[2].x)
  if sustain then self.env_sustain = util.clamp(sustain, 0, 1) end
  local r = math.max(0, release or self.x_max - self.points[5].x)
  local l = util.clamp(level or self.points[2].y, self.y_min, self.y_max)
  self.points[2].x = a;
  self.points[2].y = l;
  self.points[3].x = a + d;
  self.points[3].y = l * self.env_sustain;
  self.points[4].x = self.x_max - r;
  self.points[4].y = l * self.env_sustain;
  if curve ~= nil then
    for i = 2, 5 do
      self.points[i].curve = curve
    end
  end
end


-- ASR
function Graph.new_asr(x_min, x_max, y_min, y_max, x, y, w, h, attack, release, level, curve)
  local graph = Graph.new_env(x_min, x_max, y_min, y_max, x, y, w, h)
  local a = math.max(0, attack or 0.01)
  local r = math.max(0, release or 1)
  local l = util.clamp(level or 1, graph.y_min, graph.y_max)
  local curve = curve or -4
  graph:add_point(0, 0)
  graph:add_point(a, l, curve)
  graph:add_point(x_max - r, l, curve)
  graph:add_point(x_max, 0, curve)
  return graph
end

function Graph:edit_asr(attack, release, level, curve)
  if tabutil.count(self.points) ~= 4 then return end
  local a = math.max(0, attack or self.points[2].x)
  local r = math.max(0, release or self.x_max - self.points[3].x)
  local l = util.clamp(level or self.points[2].y, self.y_min, self.y_max)
  self.points[2].x = a;
  self.points[2].y = l;
  self.points[3].x = self.x_max - r;
  self.points[3].y = l;
  if curve ~= nil then
    for i = 2, 4 do
      self.points[i].curve = curve
    end
  end
end

-- AR (Perc)
function Graph.new_ar(x_min, x_max, y_min, y_max, x, y, w, h, attack, release, level, curve)
  local graph = Graph.new_env(x_min, x_max, y_min, y_max, x, y, w, h)
  local a = math.max(0, attack or 0.01)
  local r = math.max(0, release or 1)
  local l = util.clamp(level or 1, graph.y_min, graph.y_max)
  local curve = curve or -4
  graph:add_point(0, 0)
  graph:add_point(a, l, curve)
  graph:add_point(a + r, 0, curve)
  return graph
end

function Graph:edit_ar(attack, release, level, curve)
  if tabutil.count(self.points) ~= 3 then return end
  local a = math.max(0, attack or self.points[2].x)
  local r = math.max(0, release or self.points[3].x - self.points[2].x)
  local l = util.clamp(level or self.points[2].y, self.y_min, self.y_max)
  self.points[2].x = a;
  self.points[2].y = l;
  self.points[3].x = a + r;
  self.points[3].y = 0;
  if curve ~= nil then
    for i = 2, 3 do
      self.points[i].curve = curve
    end
  end
end



-------- Drawing methods --------

function Graph:redraw()
  
  -- TODO some of this doesn't need to be calculated every frame!
  -- Utilize dirty flags for some sections?
  
  screen.line_width(1)
  
  self.origin_sx = util.round(util.linlin(self.x_min, self.x_max, self.x, self.x + self.w, 0)) + 0.5
  self.origin_sy = util.round(util.linlin(self.y_min, self.y_max, self.y + self.h, self.y, 0)) + 0.5
  
  self:draw_axes()
  screen.level(15)
  self:draw_points()
  self:draw_functions()

end

function Graph:draw_axes()
  if self.show_x_axis then
    screen.level(3)
    screen.move(self.x, self.origin_sy)
    screen.line(self.x + self.w - 1, self.origin_sy)
    screen.stroke()
  end
  if self.show_y_axis then
    screen.level(1)
    screen.move(self.origin_sx, self.y - 1)
    screen.line(self.origin_sx, self.y + self.h)
    screen.stroke()
  end
end

function Graph:draw_points()
  
  local sx
  local sy
  local prev_sx
  local prev_sy
  
  for k, v in pairs(self.points) do
    
    prev_sx = sx
    prev_sy = sy
    sx = util.round(util.linlin(self.x_min, self.x_max, self.x, self.x + self.w, v.x))
    sy = util.round(util.linlin(self.y_min, self.y_max, self.y + self.h, self.y, v.y))
    
    -- Line style
    if self.style == 'line' and k > 1 then
      
      -- Exponential or curve value
      -- TODO reuse draw function code?
      if v.curve == 'exp' or ( type(v.curve) == 'number' and math.abs(v.curve) > 0.01) then
        
        screen.move(prev_sx, prev_sy)
        local sx_distance = sx - prev_sx
        
        if sx_distance <= 1 then
          screen.line(sx, sy)
          
        else
          for sample_x = prev_sx + 1, sx, 1 do
            local sample_x_progress = (sample_x - prev_sx) / sx_distance
            if sample_x_progress <= 0 then sample_x_progress = 1 end
            
            local y
            if v.curve == 'exp' then
              y = util.linexp(0, 1, math.max(self.points[k-1].y, 0.0001), math.max(v.y, 0.0001), sample_x_progress)
            else
              y = util.linlin(0, 1, self.points[k-1].y, v.y, (math.exp(sample_x_progress * v.curve) - 1) / (math.pow(math.exp(1), v.curve) - 1))
            end
            
            screen.line(sample_x, util.linlin(self.y_min, self.y_max, self.y + self.h, self.y, y))
          end
        end
        screen.stroke()
        
      -- Linear
      else
        screen.move(prev_sx, prev_sy)
        screen.line(sx, sy)
        screen.stroke()
        
      end
      
    -- Bar style
    elseif self.style == 'bar' then
      
      if v.highlight then
        if sy < self.origin_sy then
          screen.rect(sx - 2, sy, 3, math.max(1, self.origin_sy - sy + 0.5))
        else
          screen.rect(sx - 2, self.origin_sy - 0.5, 3, math.max(1, sy - self.origin_sy + 0.5))
        end
        screen.level(15)
        screen.fill()
        
      else
        if sy < self.origin_sy then
          screen.rect(sx - 1.5, sy - 0.5, 2, math.max(0, self.origin_sy - sy))
        else
          screen.rect(sx - 1.5, self.origin_sy - 0.5, 2, math.max(0, sy - self.origin_sy))
        end
        screen.level(3)
        screen.stroke()
      end
    end
    
    -- Draw points for all styles except bar
    if self.style ~= 'bar' then
      screen.rect(sx - 1, sy - 1, 3, 3)
      screen.fill()
      
      if v.highlight then
        screen.rect(sx - 2.5, sy - 2.5, 6, 6)
        screen.stroke()
        if math.abs(sy - self.origin_sy) > 3 then 
          local y_offset = 3
          if sy > self.origin_sy then y_offset = y_offset * -1 end
          screen.move(sx + 0.5, sy + y_offset)
          screen.line(sx + 0.5, self.origin_sy)
          screen.stroke()
        end
      end
    end
    
  end
end

function Graph:draw_functions()
  
  for _, func in pairs(self.functions) do
    screen.move(self.x, util.round(util.linlin(self.y_min, self.y_max, self.y + self.h, self.y, func(self.x_min))))
    for sx = self.x, self.x + self.w, 1 do
      local y = func(util.linlin(self.x, self.x + self.w, self.x_min, self.x_max, sx))
      screen.line(sx, util.linlin(self.y_min, self.y_max, self.y + self.h, self.y, y))
    end
    screen.stroke()
  end
end

return Graph
