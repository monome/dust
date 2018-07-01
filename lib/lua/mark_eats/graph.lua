-- Graph
-- Flexible graph drawing for envelopes, filter curves, sequencers, etc


local Graph = {}
Graph.__index = Graph

function Graph.new(x_min, x_max, x_warp, y_min, y_max, y_warp, style, show_x_axis, show_y_axis)
  local graph = {}
  graph.x_min = x_min or 0
  graph.x_max = x_max or 1
  graph.x_warp = x_warp or "lin"
  graph.y_min = y_min or 0
  graph.y_max = y_max or 1
  graph.y_warp = y_warp or "lin"
  graph.style = style or "line"
  graph.show_x_axis = show_x_axis == nil and false or show_x_axis
  graph.show_y_axis = show_y_axis == nil and false or show_y_axis
  graph.functions = {}
  graph.points = {}
  graph.active = true
  setmetatable(graph, Graph)
  graph:set_position_and_size(10, 10, 108, 44)
  return graph
end


function Graph:set_position_and_size(x, y, w, h)
  if x then self.x = x end
  if y then self.y = y end
  if w then self.w = w end
  if h then self.h = h end
  
  -- Recalculate screen co-ords
  self.origin_sx = util.round(util.linlin(self.x_min, self.x_max, self.x, self.x + self.w - 1, 0))
  self.origin_sy = util.round(util.linlin(self.y_min, self.y_max, self.y + self.h - 1, self.y, 0))
  for i = 1, #self.points do
    self.points[i].sx, self.points[i].sy = self:graph_to_screen(self.points[i].x, self.points[i].y)
  end
end

function Graph:graph_to_screen(x, y)
  if self.x_warp == "exp" then
    x = util.round(util.explin(self.x_min, self.x_max, self.x, self.x + self.w - 1, x))
  else
    x = util.round(util.linlin(self.x_min, self.x_max, self.x, self.x + self.w - 1, x))
  end
  if self.y_warp == "exp" then
    y = util.round(util.explin(self.y_min, self.y_max, self.y + self.h - 1, self.y, y))
  else
    y = util.round(util.linlin(self.y_min, self.y_max, self.y + self.h - 1, self.y, y))
  end
  return x, y
end



-------- Point methods --------

function Graph:get_point(index)
  return self.points[index]
end

-- curve defaults to 0, points will be added to the end if index is omitted
function Graph:add_point(px, py, curve, highlight, index)
  local point = {x = util.clamp(px or 0, self.x_min, self.x_max), y = util.clamp(py or 0, self.y_min, self.y_max), curve = curve or "lin", highlight = highlight or false}
  point.sx, point.sy = self:graph_to_screen(point.x, point.y)
  if index then table.insert(self.points, index, point)
  else table.insert(self.points, point) end
end

function Graph:edit_point(index, px, py, curve, highlight)
  if not self.points[index] then return end
  if px then self.points[index].x = util.clamp(px, self.x_min, self.x_max) end
  if py then self.points[index].y = util.clamp(py, self.y_min, self.y_max) end
  if px or py then self.points[index].sx, self.points[index].sy = self:graph_to_screen(self.points[index].x, self.points[index].y) end
  if curve then self.points[index].curve = curve end
  if highlight ~= nil then self.points[index].highlight = highlight end
end

function Graph:remove_point(index)
  table.remove(self.points, index)
end

function Graph:remove_all_points()
  self.points = {}
end

function Graph:highlight_point(index)
  self.points[index].highlight = true
end

function Graph:highlight_exclusive_point(index)
  for i = 1, #self.points do
    if i == index then
      self.points[i].highlight = true
    else
      self.points[i].highlight = false
    end
  end
end

function Graph:clear_highlight(index)
  self.points[index].highlight = false
end

function Graph:clear_all_highlights()
  for i = 1, #self.points do
    self.points[i].highlight = false
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
  table.remove(self.functions, index)
end

function Graph:remove_all_functions()
  self.functions = {}
end



-------- Envelope methods --------

-- Includes DADSR, ADSR, ASR, AR (Perc)

function Graph.new_env(x_min, x_max, y_min, y_max)
  return Graph.new(x_min, x_max, "lin", y_min, y_max, "lin", "line", false, false)
end

-- DADSR
function Graph.new_dadsr(x_min, x_max, y_min, y_max, delay, attack, decay, sustain, release, level, curve)
  local graph = Graph.new_env(x_min, x_max, y_min, y_max)
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
  if #self.points ~= 6 then return end
  local dl = math.max(0, delay or self.points[2].x)
  local a = math.max(0, attack or self.points[3].x - self.points[2].x)
  local d = math.max(0, decay or self.points[4].x - self.points[3].x)
  if sustain then self.env_sustain = util.clamp(sustain, 0, 1) end
  local r = math.max(0, release or self.x_max - self.points[5].x)
  local l = util.clamp(level or self.points[3].y, self.y_min, self.y_max)
  self:edit_point(2, dl)
  self:edit_point(3, dl + a, l)
  self:edit_point(4, dl + a + d, l * self.env_sustain)
  self:edit_point(5, self.x_max - r, l * self.env_sustain)
  if curve ~= nil then
    for i = 3, 6 do
      self:edit_point(i, nil, nil, curve)
    end
  end
end

-- ADSR
function Graph.new_adsr(x_min, x_max, y_min, y_max, attack, decay, sustain, release, level, curve)
  local graph = Graph.new_env(x_min, x_max, y_min, y_max)
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
  if #self.points ~= 5 then return end
  local a = math.max(0, attack or self.points[2].x)
  local d = math.max(0, decay or self.points[3].x - self.points[2].x)
  if sustain then self.env_sustain = util.clamp(sustain, 0, 1) end
  local r = math.max(0, release or self.x_max - self.points[5].x)
  local l = util.clamp(level or self.points[2].y, self.y_min, self.y_max)
  self:edit_point(2, a, l)
  self:edit_point(3, a + d, l * self.env_sustain)
  self:edit_point(4, self.x_max - r, l * self.env_sustain)
  if curve ~= nil then
    for i = 2, 5 do
      self:edit_point(i, nil, nil, curve)
    end
  end
end


-- ASR
function Graph.new_asr(x_min, x_max, y_min, y_max, attack, release, level, curve)
  local graph = Graph.new_env(x_min, x_max, y_min, y_max)
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
  if #self.points ~= 4 then return end
  local a = math.max(0, attack or self.points[2].x)
  local r = math.max(0, release or self.x_max - self.points[3].x)
  local l = util.clamp(level or self.points[2].y, self.y_min, self.y_max)
  self:edit_point(2, a, l)
  self:edit_point(3, self.x_max - r, l)
  if curve ~= nil then
    for i = 2, 4 do
      self:edit_point(i, nil, nil, curve)
    end
  end
end

-- AR (Perc)
function Graph.new_ar(x_min, x_max, y_min, y_max, attack, release, level, curve)
  local graph = Graph.new_env(x_min, x_max, y_min, y_max)
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
  if #self.points ~= 3 then return end
  local a = math.max(0, attack or self.points[2].x)
  local r = math.max(0, release or self.points[3].x - self.points[2].x)
  local l = util.clamp(level or self.points[2].y, self.y_min, self.y_max)
  self:edit_point(2, a, l)
  self:edit_point(3, a + r)
  if curve ~= nil then
    for i = 2, 3 do
      self:edit_point(i, nil, nil, curve)
    end
  end
end



-------- Drawing methods --------

function Graph:redraw()
  
  screen.line_width(1)
  
  self:draw_axes()
  self:draw_points()
  self:draw_functions()

end

function Graph:draw_axes()
  if self.show_x_axis then
    screen.level(3)
    screen.move(self.x, self.origin_sy + 0.5)
    screen.line(self.x + self.w, self.origin_sy + 0.5)
    screen.stroke()
  end
  if self.show_y_axis then
    screen.level(1) -- This looks the same as the x line at level 3 for some reason
    screen.move(self.origin_sx + 0.5, self.y)
    screen.line(self.origin_sx + 0.5, self.y + self.h)
    screen.stroke()
  end
end

function Graph:draw_points()
  
  local px, py, prev_px, prev_py, sx, sy, prev_sx, prev_sy
  
  for i = 1, #self.points do
    
    prev_px, prev_py = px, py
    px, py = self.points[i].x, self.points[i].y
    prev_sx, prev_sy = sx, sy
    sx, sy = self.points[i].sx, self.points[i].sy
    
    -- Line style
    if self.style == "line" and i > 1 then
      
      if self.active then screen.level(15) else screen.level(5) end
      
      -- Exponential or curve value
      local curve = self.points[i].curve
      if curve == "exp" or ( type(curve) == "number" and math.abs(curve) > 0.01) then
        
        screen.move(prev_sx + 0.5, prev_sy + 0.5)
        local sx_distance = sx - prev_sx
        
        if sx_distance <= 1 or prev_sy == sy then
          screen.line(sx + 0.5, sy + 0.5)
          
        else
          
          local grow, a
          if type(curve) == "number" then
            grow = math.exp(curve)
            a = 1 / (1.0 - grow)
          end
          
          for sample_x = prev_sx + 1, sx do
            local sample_x_progress = (sample_x - prev_sx) / sx_distance
            if self.x_warp == "exp" then
              local sample_graph_x = util.linexp(self.x_min, self.x_max, self.x_min, self.x_max, prev_px + (px - prev_px) * sample_x_progress)
              local prev_px_exp = util.linexp(self.x_min, self.x_max, self.x_min, self.x_max, prev_px)
              local px_exp = util.linexp(self.x_min, self.x_max, self.x_min, self.x_max, px)
              sample_x_progress = (sample_graph_x - prev_px_exp) / (px_exp - prev_px_exp)
            end
            if sample_x_progress <= 0 then sample_x_progress = 1 end
            local sy_section
            
            if curve == "exp" then
              -- Avoiding zero
              local prev_adj_y, cur_adj_y
              if prev_py < 0 then prev_adj_y = math.min(prev_py, -0.0001)
              else prev_adj_y = math.max(prev_py, 0.0001) end
              if py < 0 then cur_adj_y = math.min(py, -0.0001)
              else cur_adj_y = math.max(py, 0.0001) end
              
              sy_section = util.linexp(0, 1, prev_adj_y, cur_adj_y, sample_x_progress)
              
            else
              -- Curve formula from SuperCollider
              sy_section = util.linlin(0, 1, prev_py, py, a - (a * math.pow(grow, sample_x_progress)))
              
            end
            
            if self.y_warp == "exp" then
              sy_section = util.explin(self.y_min, self.y_max, self.y + self.h - 1, self.y, sy_section)
            else
              sy_section = util.linlin(self.y_min, self.y_max, self.y + self.h - 1, self.y, sy_section)
            end
            
            screen.line(sample_x + 0.5, sy_section + 0.5)
          end
        end
        screen.stroke()
        
      -- Linear
      else
        screen.move(prev_sx + 0.5, prev_sy + 0.5)
        screen.line(sx + 0.5, sy + 0.5)
        screen.stroke()
        
      end
      
    -- Bar style
    elseif self.style == "bar" then
      
      if self.points[i].highlight then
        if sy < self.origin_sy then
          screen.rect(sx - 1, sy, 3, math.max(1, self.origin_sy - sy + 1))
        else
          screen.rect(sx - 1, self.origin_sy, 3, math.max(1, sy - self.origin_sy + 1))
        end
        if self.active then screen.level(15) else screen.level(3) end
        screen.fill()
        
      else
        screen.level(3)
        if math.abs(sy - self.origin_sy) < 1 then
          screen.rect(sx - 1, sy, 3, 1)
          screen.fill()
        elseif sy < self.origin_sy then
          screen.rect(sx - 0.5, sy + 0.5, 2, math.max(0, self.origin_sy - sy))
          screen.stroke()
        else
          screen.rect(sx - 0.5, self.origin_sy + 0.5, 2, math.max(0, sy - self.origin_sy))
          screen.stroke()
        end
        
      end
    end
    
    -- Points
    if self.style ~= "bar" then
      screen.rect(sx - 1, sy - 1, 3, 3)
      if self.active then screen.level(15) else screen.level(5) end
      screen.fill()
      
      if self.points[i].highlight then
        screen.rect(sx - 2.5, sy - 2.5, 6, 6)
        screen.stroke()
      end
    end
    
  end
end

function Graph:draw_functions()
  
  for i = 1, #self.functions do
    screen.move(self.x + 0.5, util.round(util.linlin(self.y_min, self.y_max, self.y + self.h - 1, self.y, self.functions[i](self.x_min))) + 0.5)
    for sx = self.x, self.x + self.w - 1 do
      local y = self.functions[i](util.linlin(self.x, self.x + self.w - 1, self.x_min, self.x_max, sx))
      screen.line(sx + 0.5, util.linlin(self.y_min, self.y_max, self.y + self.h - 1, self.y, y) + 0.5)
    end
    if self.active then screen.level(15) else screen.level(5) end
    screen.stroke()
  end
end

return Graph
