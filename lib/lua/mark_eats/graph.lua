--- Graph drawing module.
-- Flexible graph drawing for waves, points, bars, etc.
--
-- @module Graph
-- @release v1.0.0
-- @author Mark Eats

local Graph = {}
Graph.__index = Graph



-------- Private utility methods --------

local function graph_to_screen(self, x, y)
  if self._x_warp == "exp" then
    x = util.explin(self._x_min, self._x_max, self._x, self._x + self._w - 1, x)
  else
    x = util.linlin(self._x_min, self._x_max, self._x, self._x + self._w - 1, x)
  end
  if self._y_warp == "exp" then
    y = util.explin(self._y_min, self._y_max, self._y + self._h - 1, self._y, y)
  else
    y = util.linlin(self._y_min, self._y_max, self._y + self._h - 1, self._y, y)
  end
  return util.round(x), util.round(y)
end

local function recalculate_screen_coords(self)
  self.origin_sx = util.round(util.linlin(self._x_min, self._x_max, self._x, self._x + self._w - 1, 0))
  self.origin_sy = util.round(util.linlin(self._y_min, self._y_max, self._y + self._h - 1, self._y, 0))
  for i = 1, #self._points do
    self._points[i].sx, self._points[i].sy = graph_to_screen(self, self._points[i].x, self._points[i].y)
  end
  self._lines_dirty = true
end

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
  local width = self._w - 1
  
  for i = 1, #self._functions do
    local line_path = {}
    local step = 1 / self._functions[i].sample_quality
    if width % step ~= 0 then
      step = (width - 0.000001) / math.modf(width / step)
    end
    
    for sx = self._x, self._x + width, step do
      local x, y
      if self._x_warp == "exp" then
        x = util.explin(self._x, self._x + width, self._x_min, self._x_max, sx)
      else
        x = util.linlin(self._x, self._x + width, self._x_min, self._x_max, sx)
      end
      y = self._functions[i].func(x)
      if self._y_warp == "exp" then
        y = util.explin(self._y_min, self._y_max, self._y + self._h - 1, self._y, y)
      else
        y = util.linlin(self._y_min, self._y_max, self._y + self._h - 1, self._y, y)
      end
      table.insert(line_path, {x = sx, y = y})
    end
    
    table.insert(self._lines, line_path)
  end
end



-------- Setup methods --------

--- Create a new Graph object. 
-- All arguments optional.
-- @param x_min Minimum value for x axis, defaults to 0.
-- @param x_max Maximum value for x axis, defaults to 1.
-- @param x_warp String defines warping for x axis, accepts "lin" or "exp", defaults to "lin".
-- @param y_min Minimum value for y axis, defaults to 0.
-- @param y_max Maximum value for y axis, defaults to 1.
-- @param y_warp String defines warping for y axis, accepts "lin" or "exp", defaults to "lin".
-- @param style String defines visual style, accepts "line", "point" or "bar", defaults to "line".
-- @param show_x_axis Display the x axis if set to true, defaults to false.
-- @param show_y_axis Display the y axis if set to true, defaults to false.
-- @return Instance of Graph.
function Graph.new(x_min, x_max, x_warp, y_min, y_max, y_warp, style, show_x_axis, show_y_axis)
  local graph = {}
  graph._x_min = x_min or 0
  graph._x_max = x_max or 1
  graph._x_warp = x_warp or "lin"
  graph._y_min = y_min or 0
  graph._y_max = y_max or 1
  graph._y_warp = y_warp or "lin"
  graph._style = style or "line"
  graph._show_x_axis = show_x_axis == nil and false or show_x_axis
  graph._show_y_axis = show_y_axis == nil and false or show_y_axis
  graph._functions = {}
  graph._points = {}
  graph._lines = {}
  graph._lines_dirty = false
  graph._active = true
  setmetatable(graph, Graph)
  graph:set_position_and_size(10, 10, 108, 44)
  return graph
end

--- Set graph's position and size.
-- All arguments optional.
-- @param x x position in pixels.
-- @param y y position in pixels.
-- @param w Width in pixels.
-- @param h Height in pixels.
function Graph:set_position_and_size(x, y, w, h)
  if x then self._x = x end
  if y then self._y = y end
  if w then self._w = w end
  if h then self._h = h end
  recalculate_screen_coords(self)
end

--- Get graph's x position.
-- @return y position.
function Graph:get_x() return self._x end

--- Set graph's x position.
-- @param x y position in pixels.
function Graph:set_x(x)
  if x then self._x = x end
  recalculate_screen_coords(self)
end

--- Get graph's y position.
-- @return y position.
function Graph:get_y() return self._y end

--- Set graph's y position.
-- @param y y position in pixels.
function Graph:set_y(y)
  if y then self._y = y end
  recalculate_screen_coords(self)
end

--- Get graph's width.
-- @return Width.
function Graph:get_width() return self._w end

--- Set graph's width.
-- @param w Width in pixels.
function Graph:set_width(w)
  if w then self._w = w end
  recalculate_screen_coords(self)
end

--- Get graph's height.
-- @return Height.
function Graph:get_height() return self._h end

--- Set graph's height.
-- @param h Height in pixels.
function Graph:set_height(h)
  if h then self._h = h end
  recalculate_screen_coords(self)
end

--- Get minimum value of x axis.
-- @return Minimum value of x axis.
function Graph:get_x_min() return self._x_min end

--- Set minimum value of x axis.
-- @param x_min Minimum value of x axis.
function Graph:set_x_min(x_min)
  if x_min then self._x_min = x_min end
  recalculate_screen_coords(self)
end

--- Get maximum value of x axis.
-- @return Maximum value of x axis.
function Graph:get_x_max() return self._x_max end

--- Set maximum value of x axis.
-- @param x_max Maximum value of x axis.
function Graph:set_x_max(x_max)
  if x_max then self._x_max = x_max end
  recalculate_screen_coords(self)
end

--- Get x warp.
-- @return x warp string.
function Graph:get_x_warp() return self._x_warp end

--- Set x warp.
-- @param warp Warp string, accepts "lin" or "exp".
function Graph:set_x_warp(warp)
  if warp == "exp" then self._x_warp = warp
  else self._x_warp = "lin" end
  recalculate_screen_coords(self)
end

--- Get minimum value of y axis.
-- @return Minimum value of y axis.
function Graph:get_y_min() return self._y_min end

--- Set minimum value of y axis.
-- @param y_min Minimum value of y axis.
function Graph:set_y_min(y_min)
  if y_min then self._y_min = y_min end
  recalculate_screen_coords(self)
end

--- Get maximum value of y axis.
-- @return Maximum value of y axis.
function Graph:get_y_max() return self._y_max end
--- Set maximum value of y axis.
-- @param y_max Maximum value of y axis.
function Graph:set_y_max(y_max)
  if y_max then self._y_max = y_max end
  recalculate_screen_coords(self)
end

--- Get y warp.
-- @return y warp string.
function Graph:get_y_warp() return self._y_warp end

--- Set y warp.
-- @param warp Warp string, accepts "lin" or "exp".
function Graph:set_y_warp(warp)
  if warp == "exp" then self._y_warp = warp
  else self._y_warp = "lin" end
  recalculate_screen_coords(self)
end

--- Get style.
-- @return Style string.
function Graph:get_style() return self._style end

--- Set style.
-- @param style Style string, accepts "line", "point" or "bar".
function Graph:set_style(style)
  self._style = style or "line"
  self._lines_dirty = true
end

--- Get show x axis.
-- @return Show x axis boolean.
function Graph:get_show_x_axis() return self._show_x_axis end

--- Set show x axis.
-- @param bool Boolean, display the x axis if set to true.
function Graph:set_show_x_axis(bool)
  self._show_x_axis = bool == nil and false or bool
end

--- Get show y axis.
-- @return Show y axis boolean.
function Graph:get_show_y_axis() return self._show_y_axis end

--- Set show y axis.
-- @param bool Boolean, display the y axis if set to true.
function Graph:set_show_y_axis(bool)
  self._show_y_axis = bool == nil and false or bool
end

--- Get active.
-- @return Active boolean.
function Graph:get_active() return self._active end

--- Set active.
-- @param bool Boolean, darkens the graph appearance when set to false.
function Graph:set_active(bool)
  self._active = bool == nil and false or bool
end



-------- Point methods --------

--- Get point at index.
-- @param index Index of point.
-- @return Point table.
function Graph:get_point(index)
  return self._points[index]
end

--- Add a point to the graph.
-- @param px Point's x position.
-- @param py Point's y position.
-- @param[opt] curve Curve of previous line segment, accepts "lin", "exp" or a number where 0 is linear and positive and negative numbers curve the envelope up and down, defaults to "lin".
-- @param[opt] highlight Highlights the point if set to true, defaults to false.
-- @param[opt] index Index to add point at, defaults to the end of the list.
function Graph:add_point(px, py, curve, highlight, index)
  local point = {x = util.clamp(px or 0, self._x_min, self._x_max), y = util.clamp(py or 0, self._y_min, self._y_max), curve = curve or "lin", highlight = highlight or false}
  point.sx, point.sy = graph_to_screen(self, point.x, point.y)
  if index then table.insert(self._points, index, point)
  else table.insert(self._points, point) end
  self._lines_dirty = true
end

--- Edit point at index.
-- @param index Index of point to edit.
-- @param[opt] px Point's x position.
-- @param[opt] py Point's y position.
-- @param[opt] curve Curve of previous line segment, accepts "lin", "exp" or a number where 0 is linear and positive and negative numbers curve the envelope up and down.
-- @param[opt] highlight Highlights the point if set to true.
function Graph:edit_point(index, px, py, curve, highlight)
  if not self._points[index] then return end
  if px then self._points[index].x = util.clamp(px, self._x_min, self._x_max) end
  if py then self._points[index].y = util.clamp(py, self._y_min, self._y_max) end
  if px or py then self._points[index].sx, self._points[index].sy = graph_to_screen(self, self._points[index].x, self._points[index].y) end
  if curve then self._points[index].curve = curve end
  if highlight ~= nil then self._points[index].highlight = highlight end
  if px or py or curve then self._lines_dirty = true end
end

--- Remove point at index.
-- Following indexes will change after removing a point.
-- @param index Index of point to remove.
function Graph:remove_point(index)
  table.remove(self._points, index)
  self._lines_dirty = true
end

--- Remove all points.
function Graph:remove_all_points()
  self._points = {}
  self._lines_dirty = true
end

--- Highlight point at index.
-- @param index Index of point to highlight.
function Graph:highlight_point(index)
  self._points[index].highlight = true
end

--- Highlight point at index exclusively.
-- Other points will have highlight set to false.
-- @param index Index of point to highlight.
function Graph:highlight_exclusive_point(index)
  for i = 1, #self._points do
    if i == index then
      self._points[i].highlight = true
    else
      self._points[i].highlight = false
    end
  end
end

--- Clear highlight from point at index.
-- @param index Index of point to clear highlight from.
function Graph:clear_highlight(index)
  self._points[index].highlight = false
end

--- Clear highlights from all points.
function Graph:clear_all_highlights()
  for i = 1, #self._points do
    self._points[i].highlight = false
  end
end



-------- Function methods --------

--- Get function at index.
-- @param index Index of function.
-- @return Function.
function Graph:get_function(index)
  return self._functions[index].func
end

--- Add a new y function to the graph.
-- Add a function that will be used to generate a line.
-- @param func A function that should return the value of y for any given value of x. For example, 'function(x) return math.sin(x) end'
-- @param[opt] sample_quality Quality to sample the graph function at. Values less than 1 will sample less than once per pixel, values higher than 1 can help reduce jitter of graphs with high frequency changes at the cost of performance. Recommended range 0.25 to 4, defaults to 1.
-- @param[opt] index Index to add function at, defaults to the end of the list.
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

--- Edit function at index.
-- @param index Index of function to edit.
-- @param func A function that should return the value of y for any given value of x.
-- @param[opt] sample_quality Quality to sample the graph function at, defaults to 1.
function Graph:edit_function(index, func, sample_quality)
  if not self._functions[index] then return end
  if func(1) ~= nil then self._functions[index].func = func end
  if sample_quality then self._functions[index].sample_quality = sample_quality end
  self._lines_dirty = true
end

--- Update all functions.
-- Call when a function's output has changed to redraw its line.
function Graph:update_functions()
  self._lines_dirty = true
end

--- Remove function at index.
-- Following indexes will change after removing a function.
-- @param index Index of function to remove.
function Graph:remove_function(index)
  table.remove(self._functions, index)
  self._lines_dirty = true
end

--- Remove all functions.
function Graph:remove_all_functions()
  self._functions = {}
  self._lines_dirty = true
end



-------- Private drawing methods --------

local function draw_axes(self)
  if self._show_x_axis then
    screen.level(3)
    screen.move(self._x, self.origin_sy + 0.5)
    screen.line(self._x + self._w, self.origin_sy + 0.5)
    screen.stroke()
  end
  if self._show_y_axis then
    screen.level(1) -- This looks the same as the x line at level 3 for some reason
    screen.move(self.origin_sx + 0.5, self._y)
    screen.line(self.origin_sx + 0.5, self._y + self._h)
    screen.stroke()
  end
end

local function draw_points(self)
  
  if self._style == "bar" then return end
  
  for i = 1, #self._points do
    local sx, sy = self._points[i].sx, self._points[i].sy
    
    screen.rect(sx - 1, sy - 1, 3, 3)
    if self._active then screen.level(15) else screen.level(5) end
    screen.fill()
    
    if self._points[i].highlight then
      screen.rect(sx - 2.5, sy - 2.5, 6, 6)
      screen.stroke()
    end
  end
end

local function draw_bars(self)
  
  if self._style ~= "bar" then return end
  
  for i = 1, #self._points do
    local sx, sy = self._points[i].sx, self._points[i].sy
    
    if self._points[i].highlight then
      if sy < self.origin_sy then
        screen.rect(sx - 1, sy, 3, math.max(1, self.origin_sy - sy + 1))
      else
        screen.rect(sx - 1, self.origin_sy, 3, math.max(1, sy - self.origin_sy + 1))
      end
      if self._active then screen.level(15) else screen.level(3) end
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
  if self._active then screen.level(15) else screen.level(5) end
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

--- Redraw the graph.
-- Call whenever graph data or settings have been changed.
function Graph:redraw()
  
  screen.line_width(1)
  
  draw_axes(self)
  draw_lines(self)
  draw_points(self)
  draw_bars(self)
end


return Graph
