-- EnvGraph
-- Subclass of Graph for drawing common envelope graphs. Includes DADSR, ADSR, ASR, AR (Perc).
-- v1.0.0 by Mark Eats

local EnvGraph = {}
EnvGraph.__index = EnvGraph

-- Hack to force require to reload
function unrequire(name) 
   package.loaded[name] = nil
   _G[name] = nil
end
unrequire("mark_eats/graph")

local Graph = require "mark_eats/graph"



-------- Private utility methods --------

local function new_env_graph(x_min, x_max, y_min, y_max)
  local graph = Graph.new(x_min, x_max, "lin", y_min, y_max, "lin", "line", false, false)
  setmetatable(EnvGraph, {__index = Graph})
  setmetatable(graph, EnvGraph)
  return graph
end



-------- Public methods --------

-- DADSR
function EnvGraph.new_dadsr(x_min, x_max, y_min, y_max, delay, attack, decay, sustain, release, level, curve)
  local graph = new_env_graph(x_min, x_max, y_min, y_max)
  local dl = math.max(0, delay or 0.1)
  local a = math.max(0, attack or 0.01)
  local d = math.max(0, decay or 0.3)
  graph._env_sustain = util.clamp(sustain or 0.5, 0, 1)
  local r = math.max(0, release or 1)
  local l = util.clamp(level or 1, graph._y_min, graph._y_max)
  local curve = curve or -4
  graph:add_point(0, 0)
  graph:add_point(dl, 0)
  graph:add_point(dl + a, l, curve)
  graph:add_point(dl + a + d, l * graph.__env_sustain, curve)
  graph:add_point(graph._x_max - r, l * graph._env_sustain, curve)
  graph:add_point(graph._x_max, 0, curve)
  return graph
end

function EnvGraph:edit_dadsr(delay, attack, decay, sustain, release, level, curve)
  if #self._points ~= 6 then return end
  local dl = math.max(0, delay or self._points[2].x)
  local a = math.max(0, attack or self._points[3].x - self._points[2].x)
  local d = math.max(0, decay or self._points[4].x - self._points[3].x)
  if sustain then self._env_sustain = util.clamp(sustain, 0, 1) end
  local r = math.max(0, release or self._x_max - self._points[5].x)
  local l = util.clamp(level or self._points[3].y, self._y_min, self._y_max)
  self:edit_point(2, dl)
  self:edit_point(3, dl + a, l)
  self:edit_point(4, dl + a + d, l * self._env_sustain)
  self:edit_point(5, self._x_max - r, l * self._env_sustain)
  if curve ~= nil then
    for i = 3, 6 do
      self:edit_point(i, nil, nil, curve)
    end
  end
end

-- ADSR
function EnvGraph.new_adsr(x_min, x_max, y_min, y_max, attack, decay, sustain, release, level, curve)
  local graph = new_env_graph(x_min, x_max, y_min, y_max)
  local a = math.max(0, attack or 0.01)
  local d = math.max(0, decay or 0.3)
  graph._env_sustain = util.clamp(sustain or 0.5, 0, 1)
  local r = math.max(0, release or 1)
  local l = util.clamp(level or 1, graph._y_min, graph._y_max)
  local curve = curve or -4
  graph:add_point(0, 0)
  graph:add_point(a, l, curve)
  graph:add_point(a + d, l * graph._env_sustain, curve)
  graph:add_point(graph._x_max - r, l * graph._env_sustain, curve)
  graph:add_point(graph._x_max, 0, curve)
  return graph
end

function EnvGraph:edit_adsr(attack, decay, sustain, release, level, curve)
  if #self._points ~= 5 then return end
  local a = math.max(0, attack or self._points[2].x)
  local d = math.max(0, decay or self._points[3].x - self._points[2].x)
  if sustain then self._env_sustain = util.clamp(sustain, 0, 1) end
  local r = math.max(0, release or self._x_max - self._points[5].x)
  local l = util.clamp(level or self._points[2].y, self._y_min, self._y_max)
  self:edit_point(2, a, l)
  self:edit_point(3, a + d, l * self._env_sustain)
  self:edit_point(4, self._x_max - r, l * self._env_sustain)
  if curve ~= nil then
    for i = 2, 5 do
      self:edit_point(i, nil, nil, curve)
    end
  end
end


-- ASR
function EnvGraph.new_asr(x_min, x_max, y_min, y_max, attack, release, level, curve)
  local graph = new_env_graph(x_min, x_max, y_min, y_max)
  local a = math.max(0, attack or 0.01)
  local r = math.max(0, release or 1)
  local l = util.clamp(level or 1, graph._y_min, graph._y_max)
  local curve = curve or -4
  graph:add_point(0, 0)
  graph:add_point(a, l, curve)
  graph:add_point(graph._x_max - r, l, curve)
  graph:add_point(graph._x_max, 0, curve)
  return graph
end

function EnvGraph:edit_asr(attack, release, level, curve)
  if #self._points ~= 4 then return end
  local a = math.max(0, attack or self._points[2].x)
  local r = math.max(0, release or self._x_max - self._points[3].x)
  local l = util.clamp(level or self._points[2].y, self._y_min, self._y_max)
  self:edit_point(2, a, l)
  self:edit_point(3, self._x_max - r, l)
  if curve ~= nil then
    for i = 2, 4 do
      self:edit_point(i, nil, nil, curve)
    end
  end
end

-- AR (Perc)
function EnvGraph.new_ar(x_min, x_max, y_min, y_max, attack, release, level, curve)
  local graph = new_env_graph(x_min, x_max, y_min, y_max)
  local a = math.max(0, attack or 0.01)
  local r = math.max(0, release or 1)
  local l = util.clamp(level or 1, graph._y_min, graph._y_max)
  local curve = curve or -4
  graph:add_point(0, 0)
  graph:add_point(a, l, curve)
  graph:add_point(a + r, 0, curve)
  return graph
end

function EnvGraph:edit_ar(attack, release, level, curve)
  if #self._points ~= 3 then return end
  local a = math.max(0, attack or self._points[2].x)
  local r = math.max(0, release or self._points[3].x - self._points[2].x)
  local l = util.clamp(level or self._points[2].y, self._y_min, self._y_max)
  self:edit_point(2, a, l)
  self:edit_point(3, a + r)
  if curve ~= nil then
    for i = 2, 3 do
      self:edit_point(i, nil, nil, curve)
    end
  end
end


return EnvGraph
