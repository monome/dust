local Scroll = {}
Scroll.__index = Scroll

Scroll.SCREEN_ROWS = 7
Scroll.SELECTED_PARAM_LEVEL = 15
Scroll.PARAM_LEVEL = 4
Scroll.TEXT_LEVEL = 4

function Scroll.new()
  local instance = setmetatable({}, Scroll)
  instance.content = {}
  instance.size = 0
  instance.top = 1
  return instance
end

function Scroll:print()
  for k,v in pairs(self) do
    print('>> ', k, v)
  end
end

function Scroll:push(thing) -- TODO: pushing nil to scroll freaks it out, handle this case
  lineno = self.size + 1
  self.content[lineno] = thing
  -- TODO: there was some error here
  if type(thing) ~= 'string' and self.selected_param == nil then
    -- line assumed to be a Param instance
    self:select_param_at_line(lineno)
  end
  self.size = lineno
end

function Scroll:pop(thing)
  self.size = self.size - 1
  local line = self.content[self.size]
  if self.selected_param == line then
    self:remove_param_selection()
  end
  self.content[self.size] = nil
end

function Scroll:redraw(s)
  s.clear()
  --[[
  print("--------------") -- 
  print("new screen") -- 
  if self.selected_param then -- 
    print("selected_param: "..(self.selected_param.name)) -- 
  end -- 
  print("--------------") -- 
  ]]
  for i=1,Scroll.SCREEN_ROWS do
    local scroll_i = self.top+i-1
    s.move(0, i*8)
    -- io.write("row: "..(scroll_i)..", ") -- 
    if scroll_i >= self.size then
      return
    else
      local str;
      local line = self.content[scroll_i]
      if type(line) == 'string' then
        s.level(Scroll.TEXT_LEVEL)
        -- io.write("level "..Scroll.TEXT_LEVEL..": ") -- 
        str = line
      else -- Param assumed
        if self.selected_param == line then
          s.level(Scroll.SELECTED_PARAM_LEVEL)
          -- io.write("level "..Scroll.SELECTED_PARAM_LEVEL..": ") -- 
        else
          s.level(Scroll.PARAM_LEVEL)
          -- io.write("level "..Scroll.PARAM_LEVEL..": ") -- 
        end
        str = line:string()
      end
      s.text(str)
      -- print(str) --
    end
  end
end

function Scroll:redraw_old()
  -- s.clear()
  print("--------------")
  print("new screen")
  if self.selected_param then
    print("selected_param: "..(self.selected_param.name))
  end
  print("--------------")
  for i=1,Scroll.SCREEN_ROWS do
    scroll_i = self.top+i
    -- s.move(0, i*8)
    io.write("row: "..(scroll_i)..", ")
    if scroll_i >= self.size then
      return
    else
      local str;
      line = self.content[scroll_i]
      if type(line) == 'string' then
        -- s.level(Scroll.TEXT_LEVEL)
        io.write("level "..Scroll.TEXT_LEVEL..": ")
        str = line
      else -- Param assumed
        if self.selected_param == line then
          -- s.level(Scroll.SELECTED_PARAM_LEVEL)
          io.write("level "..Scroll.SELECTED_PARAM_LEVEL..": ")
        else
          -- s.level(Scroll.PARAM_LEVEL)
          io.write("level "..Scroll.PARAM_LEVEL..": ")
        end
        str = line:string(0.01)
      end
      -- s.text(str)
      print(str)
    end
  end
end

function Scroll:select_param_at_line(lineno)
  local param = self.content[lineno]
  if type(param) ~= 'string' then
    self.selected_param = param
    self.selected_lineno = lineno
  end
end

function Scroll:remove_param_selection(lineno)
  self.selected_param = nil -- TODO: this should lookup and refer to visible param above after pop, if any
  self.selected_lineno = nil -- TODO: this should lookup and refer to visible param above after pop, if any
end

function Scroll:is_param_line(lineno)
  return type(self.content[lineno]) ~= 'string' -- TODO: loose assumption
end

function Scroll:line_is_visible(lineno)
  for i=self.top,self.top+Scroll.SCREEN_ROWS do
    if lineno == i then
      return true
    end
  end
end

function Scroll:lineno_of_visible_param_at_or_after(lineno)
  for i=(lineno),self.top+Scroll.SCREEN_ROWS-1 do
    if self:is_param_line(i) then
      return i
    end
  end
end

function Scroll:lineno_of_visible_param_before(lineno)
  for i=(lineno-1),self.top,-1 do
    if self:is_param_line(i) then
      return i
    end
  end
end

function Scroll:lookup_lineno(thing)
  for i,t in ipairs(self.content) do
    if t == thing then
      return i
    end
  end
end

function Scroll:navigate_to_lineno(lineno)
  new_top = lineno
  if new_top >= 1 and (new_top + Scroll.SCREEN_ROWS) <= self.size then
    if (new_top + Scroll.SCREEN_ROWS) > self.size then
      new_top = self.size - Scroll.SCREEN_ROWS
    end
    self.top = new_top
    new_selected_param_lineno = self:lineno_of_visible_param_at_or_after(new_top)
    if new_selected_param_lineno then
      self:select_param_at_line(new_selected_param_lineno)
    elseif self.selected_lineno then
      if not self:line_is_visible(self.selected_lineno) then
        self:remove_param_selection()
      end
    end
  end
end

function Scroll:navigate(delta)
  local new_selected_param_lineno

  if self.selected_lineno then
    if delta < 0 then
      new_selected_param_lineno = self:lineno_of_visible_param_before(self.selected_lineno)
    elseif delta > 0 then
      new_selected_param_lineno = self:lineno_of_visible_param_at_or_after(self.selected_lineno+1)
    end
  end

  new_top = self.top + delta
  if new_selected_param_lineno then
    self:select_param_at_line(new_selected_param_lineno)
  elseif new_top >= 1 and (new_top + Scroll.SCREEN_ROWS) <= self.size then
    -- TODO print(self.size..":"..new_top)
    self.top = new_top
    if self.selected_lineno then
      if delta < 0 then
        new_selected_param_lineno = self:lineno_of_visible_param_before(self.selected_lineno)
      elseif delta > 0 then
        new_selected_param_lineno = self:lineno_of_visible_param_at_or_after(self.selected_lineno+1)
      end
    else
      if delta < 0 and self:is_param_line(new_top) then
        new_selected_param_lineno = new_top
      elseif delta > 0 and self:is_param_line(new_top+Scroll.SCREEN_ROWS-1) then
        new_selected_param_lineno = new_top+Scroll.SCREEN_ROWS-1
      end
    end
    if new_selected_param_lineno then
      self:select_param_at_line(new_selected_param_lineno)
    elseif self.selected_lineno then
      if not self:line_is_visible(self.selected_lineno) then
        self:remove_param_selection()
      end
    end
  end
end

return Scroll
