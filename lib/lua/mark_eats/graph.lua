-- Graph
-- Flexible graph drawing for waves, points, bars, etc.
-- v1.0.0 by Mark Eats

local Graph = {}
Graph.__index = Graph



-------- Private utility methods --------

local function graph_to_screen(self, x, y)
  if self._x_warp == "exp" then
    x = util.round(util.explin(self._x_min, self._x_max, self._x, self._x + self._w - 1, x))
  else
    x = util.round(util.linlin(self._x_min, self._x_max, self._x, self._x + self._w - 1, x))
  end
  if self._y_warp == "exp" then
    y = util.round(util.explin(self._y_min, self._y_max, self._y + self._h - 1, self._y, y))
  else
    y = util.round(util.linlin(self._y_min, self._y_max, self._y + self._h - 1, self._y, y))
  end
  return x, y
end

local function recalculate_screen_coords(self)
  self.origin_sx = util.round(util.linlin(self._x_min, self._x_max, self._x, self._x + self._w - 1, 0))
  self.origin_sy = util.round(util.linlin(self._y_min, self._y_max, self._y + self._h - 1, self._y, 0))
  for i = 1, #self._points do
    self._points[i].sx, self._points[i].sy = graph_to_screen(self, self._points[i].x, self._points[i].y)
  end
  self._lines_dirty = true
end



-------- Setup methods --------

function Graph.new(x_min, x_max, x_warp, y_min, y_max, y_warp, style, show_x_axis, show_y_axis)
  local graph = {}
  graph._x_min = x_min or 0
  graph._x_max = x_max or 1
  graph._x_warp = x_warp or "lin"
  graph._y_min = y_min or 0
  graph._y_max = y_max or 1
  graph._y_warp = y_warp or "lin"
  graph._style = style or "line"
  graph.show_x_axis = show_x_axis == nil and false or show_x_axis
  graph.show_y_axis = show_y_axis == nil and false or show_y_axis
  graph._functions = {}
  graph._points = {}
  graph._lines = {}
  graph._lines_dirty = false
  graph.active = true
  setmetatable(graph, Graph)
  graph:set_position_and_size(10, 10, 108, 44)
  return graph
end

function Graph:get_x() return self._x end
function Graph:get_y() return self._y end
function Graph:get_width() return self._w end
function Graph:get_height() return self._h end

function Graph:set_x(x)
  if x then self._x = x end
  recalculate_screen_coords(self)
end
function Graph:set_y(y)
  if y then self._y = y end
  recalculate_screen_coords(self)
end
function Graph:set_width(w)
  if w then self._w = w end
  recalculate_screen_coords(self)
end
function Graph:set_height(h)
  if h then self._h = h end
  recalculate_screen_coords(self)
end

function Graph:set_position_and_size(x, y, w, h)
  if x then self._x = x end
  if y then self._y = y end
  if w then self._w = w end
  if h then self._h = h end
  recalculate_screen_coords(self)
end

function Graph:get_x_min() return self._x_min end
function Graph:get_x_max() return self._x_max end
function Graph:get_y_min() return self._y_min end
function Graph:get_y_max() return self._y_max end

function Graph:set_x_min(x_min)
  if x_min then self._x_min = x_min end
  recalculate_screen_coords(self)
end
function Graph:set_x_max(x_max)
  if x_max then self._x_max = x_max end
  recalculate_screen_coords(self)
end
function Graph:set_y_min(y_min)
  if y_min then self._y_min = y_min end
  recalculate_screen_coords(self)
end
function Graph:set_y_max(y_max)
  if y_max then self._y_max = y_max end
  recalculate_screen_coords(self)
end

function Graph:get_style() return self._style end

function Graph:set_style(style)
  self._style = style or "line"
  self._lines_dirty = true
end



-------- Point methods --------

function Graph:get_point(index)
  return self._points[index]
end

-- curve defaults to 0, points will be added to the end if index is omitted
function Graph:add_point(px, py, curve, highlight, index)
  local point = {x = util.clamp(px or 0, self._x_min, self._x_max), y = util.clamp(py or 0, self._y_min, self._y_max), curve = curve or "lin", highlight = highlight or false}
  point.sx, point.sy = graph_to_screen(self, point.x, point.y)
  if index then table.insert(self._points, index, point)
  else table.insert(self._points, point) end
  self._lines_dirty = true
end

function Graph:edit_point(index, px, py, curve, highlight)
  if not self._points[index] then return end
  if px then self._points[index].x = util.clamp(px, self._x_min, self._x_max) end
  if py then self._points[index].y = util.clamp(py, self._y_min, self._y_max) end
  if px or py then self._points[index].sx, self._points[index].sy = graph_to_screen(self, self._points[index].x, self._points[index].y) end
  if curve then self._points[index].curve = curve end
  if highlight ~= nil then self._points[index].highlight = highlight end
  if px or py or curve then self._lines_dirty = true end
end

function Graph:remove_point(index)
  table.remove(self._points, index)
  self._lines_dirty = true
end

function Graph:remove_all_points()
  self._points = {}
  self._lines_dirty = true
end

function Graph:highlight_point(index)
  self._points[index].highlight = true
end

function Graph:highlight_exclusive_point(index)
  for i = 1, #self._points do
    if i == index then
      self._points[i].highlight = true
    else
      self._points[i].highlight = false
    end
  end
end

function Graph:clear_highlight(index)
  self._points[index].highlight = false
end

function Graph:clear_all_highlights()
  for i = 1, #self._points do
    self._points[i].highlight = false
  end
end



-------- Function methods --------

function Graph:get_function(index)
  return self._functions[index].func
end

function Graph:add_function(func, sample_quality, index)
  if func(1) == nil then return end
  local quality = sample_quality or 1
  if index then
    table.insert(self._functions, index, {func = func, sample_quality = quality})
  else
    table.insert(self._functions, {func = func, sample_quality = quality})
  end
  self._lines_dirty = true
end

function Graph:edit_function(index, func)
  if not self._functions[index] then return end
  if func(1) ~= nil then self._functions[index].func = func end
  self._lines_dirty = true
end

function Graph:update_functions()
  self._lines_dirty = true
end

function Graph:remove_function(index)
  table.remove(self._functions, index)
  self._lines_dirty = true
end

function Graph:remove_all_functions()
  self._functions = {}
  self._lines_dirty = true
end



-------- Private line generation methods --------

local function generate_line_from_points(self)
  
  if #self._points < 2 or self._style ~= "line" then return end
  
  local line_path = {}
  local px, py, prev_px, prev_py, sx, sy, prev_sx, prev_sy
  
  px, py = self._points[1].x, self._points[1].y
  sx, sy = self._points[1].sx, self._points[1].sy
  
  table.insert(line_path, {x = sx, y = sy})
  
  for i = 2, #self._points do
    
    prev_px, prev_py = px, py
    prev_sx, prev_sy = sx, sy
    px, py = self._points[i].x, self._points[i].y
    sx, sy = self._points[i].sx, self._points[i].sy
    
    -- Exponential or curve value
    local curve = self._points[i].curve
    if curve == "exp" or ( type(curve) == "number" and math.abs(curve) > 0.01) then
      
      local sx_distance = sx - prev_sx
      
      if sx_distance <= 1 or prev_sy == sy then
        -- Draw a straight line
        table.insert(line_path, {x = sx, y = sy})
        
      else
        
        local grow, a
        if type(curve) == "number" then
          grow = math.exp(curve)
          a = 1 / (1.0 - grow)
        end
        
        for sample_x = prev_sx + 1, sx - 1 do
          local sample_x_progress = (sample_x - prev_sx) / sx_distance
          if self._x_warp == "exp" then
            local sample_graph_x = util.linexp(self._x_min, self._x_max, self._x_min, self._x_max, prev_px + (px - prev_px) * sample_x_progress)
            local prev_px_exp = util.linexp(self._x_min, self._x_max, self._x_min, self._x_max, prev_px)
            local px_exp = util.linexp(self._x_min, self._x_max, self._x_min, self._x_max, px)
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
          
          if self._y_warp == "exp" then
            sy_section = util.explin(self._y_min, self._y_max, self._y + self._h - 1, self._y, sy_section)
          else
            sy_section = util.linlin(self._y_min, self._y_max, self._y + self._h - 1, self._y, sy_section)
          end
          
          table.insert(line_path, {x = sample_x, y = sy_section})
        end
        table.insert(line_path, {x = sx, y = sy})
      end
      
    -- Linear
    else
      table.insert(line_path, {x = sx, y = sy})
      
    end
  end
  table.insert(self._lines, line_path)
end

local function generate_lines_from_functions(self)
  for i = 1, #self._functions do
    local line_path = {}
    table.insert(line_path, {x = self._x, y = util.linlin(self._y_min, self._y_max, self._y + self._h - 1, self._y, self._functions[i].func(self._x_min))})
    for sx = self._x, self._x + self._w - 1, 1 / self._functions[i].sample_quality do
      local y = self._functions[i].func(util.linlin(self._x, self._x + self._w - 1, self._x_min, self._x_max, sx))
      table.insert(line_path, {x = sx, y = util.linlin(self._y_min, self._y_max, self._y + self._h - 1, self._y, y)})
    end
    table.insert(self._lines, line_path)
  end
end



-------- Private drawing methods --------

local function draw_axes(self)
  if self.show_x_axis then
    screen.level(3)
    screen.move(self._x, self.origin_sy + 0.5)
    screen.line(self._x + self._w, self.origin_sy + 0.5)
    screen.stroke()
  end
  if self.show_y_axis then
    screen.level(1) -- This looks the same as the x line at level 3 for some reason
    screen.move(self.origin_sx + 0.5, self._y)
    screen.line(self.origin_sx + 0.5, self._y + self._h)
    screen.stroke()
  end
end

local function draw_points(self)
  
  local px, py, prev_px, prev_py, sx, sy, prev_sx, prev_sy
  
  for i = 1, #self._points do
    
    prev_px, prev_py = px, py
    px, py = self._points[i].x, self._points[i].y
    prev_sx, prev_sy = sx, sy
    sx, sy = self._points[i].sx, self._points[i].sy
    
    -- Bar style
    if self._style == "bar" then
      
      if self._points[i].highlight then
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
    
    -- Points
    else
      screen.rect(sx - 1, sy - 1, 3, 3)
      if self.active then screen.level(15) else screen.level(5) end
      screen.fill()
      
      if self._points[i].highlight then
        screen.rect(sx - 2.5, sy - 2.5, 6, 6)
        screen.stroke()
      end
    end
    
  end
end

local function draw_lines(self)
  
  if self._style ~= "line" and #self._functions == 0 then return end
  
  if self._lines_dirty then
    self._lines = {}
    generate_line_from_points(self)
    generate_lines_from_functions(self)
    self._lines_dirty = false
  end
  
  screen.line_join("round")
  if self.active then screen.level(15) else screen.level(5) end
  for l = 1, #self._lines do
    screen.move(self._lines[l][1].x + 0.5, self._lines[l][1].y + 0.5)
    for i = 2, #self._lines[l] do
      screen.line(self._lines[l][i].x + 0.5, self._lines[l][i].y + 0.5)
    end
    screen.stroke()
  end
  screen.line_join("miter")
end



-------- Redraw --------

function Graph:redraw()
  
  screen.line_width(1)
  
  draw_axes(self)
  draw_lines(self)
  draw_points(self)
end


return Graph
