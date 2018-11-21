-- UI Demo
--
-- UI widgets demo.
--
-- ENC1/KEY2 : Change page
-- KEY3 : Change tab
-- ENC2/3 : Adjust controls
--
-- v1.0.0 Mark Eats
--


local UI = require "mark_eats/ui"

local SCREEN_FRAMERATE = 15
local screen_refresh_metro
local screen_dirty = true

local pages
local tabs
local dial_l
local dial_r
local slider_l
local slider_r
local scrolling_list
local message

local list_content = {"The Genesis", "N.Y. State of Mind", "Life's a Bitch", "The World Is Yours", "Halftime", "Memory Lane (Sittin' in...)", "One Love", "One Time 4 Your Mind", "Represent", "It Ain't Hard to Tell"}
local message_result = ""


-- Init
function init()
  
  screen.aa(1)
  
  -- Init UI
  pages = UI.Pages.new(1, 3)
  tabs = UI.Tabs.new(1, {"Tab A", "Tab B"})
  
  dial_l = UI.Dial.new(9, 19, 22, 25, 0, 100, 1)
  dial_r = UI.Dial.new(34, 34, 22, 0.3, 0, 2, 0.01)
  
  slider_l = UI.Slider.new(86, 18, 3, 44, 0.25, 0, 1, {0.84})
  slider_r = UI.Slider.new(102, 18, 3, 44, 0.25, 0, 1, {0.84})
  slider_l.active = false
  slider_r.active = false
  
  scrolling_list = UI.ScrollingList.new(8, 8, 1, list_content)
  
  -- Start drawing to screen
  screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  
end


-- Encoder input
function enc(n, delta)
  
  if n == 1 then
    -- Page scroll
    pages:set_index_delta(util.clamp(delta, -1, 1), false)
  end
  
  if pages.index == 1 then
      if tabs.index == 1 then
        -- Tab A
        if n == 2 then
          dial_l:set_value_delta(delta)
        elseif n == 3 then
          dial_r:set_value_delta(delta / 50)
        end
      else
        -- Tab B
        if n == 2 then
          slider_l:set_value_delta(delta / 100)
        elseif n == 3 then
          slider_r:set_value_delta(delta / 100)
        end
      end
      
  elseif pages.index == 2 then
    if n == 2 then
      scrolling_list:set_index_delta(util.clamp(delta, -1, 1))
    end
    
  end
  
  screen_dirty = true
end

-- Key input
function key(n, z)
  if z == 1 then
    
    if n == 2 then
      
      if message then
        message = nil
        message_result = "Cancelled."
        
      else
        pages:set_index_delta(1, true)
      end
      
    elseif n == 3 then
      
      if message then
        message = nil
        message_result = "Confirmed!"
      
      elseif pages.index == 1 then
        tabs:set_index_delta(1, true)
        dial_l.active = tabs.index == 1
        dial_r.active = tabs.index == 1
        slider_l.active = tabs.index == 2
        slider_r.active = tabs.index == 2
        
      elseif pages.index == 3 then
        message = UI.Message.new({"This is a message.", "", "KEY2 to cancel", "KEY3 to confirm"})
      end
      
    end
    
    screen_dirty = true
  end
end


-- Redraw
function redraw()
  screen.clear()
  
  if message then
    message:redraw()
      
  else
    
    pages:redraw()
    
    if pages.index == 1 then
      tabs:redraw()
      dial_l:redraw()
      dial_r:redraw()
      slider_l:redraw()
      slider_r:redraw()
      
    elseif pages.index == 2 then
      scrolling_list:redraw()
      
    elseif pages.index == 3 then
      screen.move(8, 24)
      screen.level(15)
      screen.text("Press KEY3 to")
      screen.move(8, 35)
      screen.text("display a message.")
      screen.move(8, 50)
      screen.level(3)
      screen.text(message_result)
      screen.fill()
      
    end
    
  end
  
  screen.update()
end
