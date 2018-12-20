-- Sway - live processing 
--  environment
-- 
-- Concept and Code by 
--   Carl Testa (2018)
--
-- analysis-driven live 
-- processing, play into 
-- input 1 (L), processing
-- will gradually change
--
-- key 2 toggles processing map
-- and analysis values view
-- 
-- greater control available
-- within parameter menu
--
-- more info @
-- http://sway.carltesta.net

local amp = 0
local density = 0
local clarity = 0
local x_coord = 0.5
local y_coord = 0.5
local processingtext =""
local screen_number = 0
local quadrants = {1,2,8,3,4}
local q0,q1,q2,q3,q4

engine.name = 'Sway'

function init()
   print("Sway")
   a = poll.set("avg_amp")
   a.callback = function(val) amp = val end
   a:start()
   
   o = poll.set("avg_onsets")
   o.callback = function(val) density = string.format("%.2f",val*10) end
   o:start()
   
   c = poll.set("avg_clarity")
   c.callback = function(val) clarity = string.format("%.2f",val*100) end
   c:start()
   
   x = poll.set("x_coord")
   x.callback = function(val) x_coord = string.format("%.2f",val) end
   x:start()
   
   y = poll.set("y_coord")
   y.callback = function(val) y_coord = string.format("%.2f",val) end
   y:start()
   
   z = poll.set("current_processing")
   z.callback = function(val) processingtext = decode(val) end
   z:start()
   
   q0 = poll.set("quadrant0")
   q0.callback = function(val) quadrants[1] = val end
   q0:start()
   
   q1 = poll.set("quadrant1")
   q1.callback = function(val) quadrants[2] = val end
   q1:start()
   
   q2 = poll.set("quadrant2")
   q2.callback = function(val) quadrants[3] = val end
   q2:start()
   
   q3 = poll.set("quadrant3")
   q3.callback = function(val) quadrants[4] = val end
   q3:start()
   
   q4 = poll.set("quadrant4")
   q4.callback = function(val) quadrants[5] = val end
   q4:start()
   
  t = metro.alloc()
  t.count = 0
  t.time = 1
  t.callback = function(stage)
    redraw()
  end
  
  params:add{type="number", id="amp_threshold", min=0, max=40,default=4,
    action=function(x) engine.amp_thresh(x) end}
  
  params:add{type="number", id="density_threshold", min=0, max=80, default=40,
    action=function(x) engine.density_thresh(x/10) end}
  
  params:add{type="number", id="clarity_threshold", min=0, max=100, default=70,
    action=function(x) engine.clarity_thresh(x/100) end}
  
  params:add_separator()
  
  params:add{type="option", id="analysis", name="analysis", options={"on", "off"},
    action=function(val) engine.analysis_on(val) if val==1 then params:set("processing_type", 1) end end}
  
  params:add{type="number", id="fadetime", min=2, max=120, default=30,
    action=function(x) engine.fadetime(x) end}
   
  params:add{type="option", id="panning", name="panning", options={"on", "off"},
    action=function(val) engine.panning_on(val) end}
  
  params:add{type="option", id="processing_type", name="processing_type", options={"---","reverb", "delay", "amp mod", "freeze", "pitchbend", "filter", "cascade"},
    action=function(val) if params:get("analysis")==2 then
      if val==1 then engine.silence(val) end
      if val==2 then engine.reverb(val) end
      if val==3 then engine.delay(val) end
      if val==4 then engine.ampmod(val) end
      if val==5 then engine.freeze(val) end
      if val==6 then engine.pitchbend(val) end
      if val==7 then engine.filter(val) end
      if val==8 then engine.cascade(val) end
      end
    end}
    
  params:add{type="option", id="polarity", name="polarity", default=2, options={"on", "off"},
    action=function(val) engine.polarity(val) end}
  
  params:add_separator()
  
  params:add{type="option", id="evolver", name="evolver", options={"on", "off"},
    action=function(val) engine.tracker_on(val) end}
  
  params:add{type="number", id="time_limit", min=30, max=500, default=100,
    action=function(x) engine.timelimit(x) end}
  
  params:add_separator()
    
  params:add{type="option", id="center", name="center", default=1, options={"silence","reverb", "delay", "amp mod", "freeze", "pitchbend", "filter", "cascade"},
    action=function(val)
      if val==1 then engine.map_quadrant(0,1) end
      if val==2 then engine.map_quadrant(0,3) end
      if val==3 then engine.map_quadrant(0,2) end
      if val==4 then engine.map_quadrant(0,4) end
      if val==5 then engine.map_quadrant(0,8) end
      if val==6 then engine.map_quadrant(0,5) end
      if val==7 then engine.map_quadrant(0,7) end
      if val==8 then engine.map_quadrant(0,6) end
      end}
      
    params:add{type="option", id="quadrant_1", name="quadrant_1", default=3, options={"silence","reverb", "delay", "amp mod", "freeze", "pitchbend", "filter", "cascade"},
    action=function(val)
      if val==1 then engine.map_quadrant(1,1) end
      if val==2 then engine.map_quadrant(1,3) end
      if val==3 then engine.map_quadrant(1,2) end
      if val==4 then engine.map_quadrant(1,4) end
      if val==5 then engine.map_quadrant(1,8) end
      if val==6 then engine.map_quadrant(1,5) end
      if val==7 then engine.map_quadrant(1,7) end
      if val==8 then engine.map_quadrant(1,6) end
      end}
      
    params:add{type="option", id="quadrant_2", name="quadrant_2", default=5, options={"silence","reverb", "delay", "amp mod", "freeze", "pitchbend", "filter", "cascade"},
    action=function(val)
      if val==1 then engine.map_quadrant(2,1) end
      if val==2 then engine.map_quadrant(2,3) end
      if val==3 then engine.map_quadrant(2,2) end
      if val==4 then engine.map_quadrant(2,4) end
      if val==5 then engine.map_quadrant(2,8) end
      if val==6 then engine.map_quadrant(2,5) end
      if val==7 then engine.map_quadrant(2,7) end
      if val==8 then engine.map_quadrant(2,6) end
      end}
      
    params:add{type="option", id="quadrant_3", name="quadrant_3", default=2, options={"silence","reverb", "delay", "amp mod", "freeze", "pitchbend", "filter", "cascade"},
    action=function(val)
      if val==1 then engine.map_quadrant(3,1) end
      if val==2 then engine.map_quadrant(3,3) end
      if val==3 then engine.map_quadrant(3,2) end
      if val==4 then engine.map_quadrant(3,4) end
      if val==5 then engine.map_quadrant(3,8) end
      if val==6 then engine.map_quadrant(3,5) end
      if val==7 then engine.map_quadrant(3,7) end
      if val==8 then engine.map_quadrant(3,6) end
      end}
      
    params:add{type="option", id="quadrant_4", name="quadrant_4", default=4, options={"silence","reverb", "delay", "amp mod", "freeze", "pitchbend", "filter", "cascade"},
    action=function(val)
      if val==1 then engine.map_quadrant(4,1) end
      if val==2 then engine.map_quadrant(4,3) end
      if val==3 then engine.map_quadrant(4,2) end
      if val==4 then engine.map_quadrant(4,4) end
      if val==5 then engine.map_quadrant(4,8) end
      if val==6 then engine.map_quadrant(4,5) end
      if val==7 then engine.map_quadrant(4,7) end
      if val==8 then engine.map_quadrant(4,6) end
      end}
  t:start()
   
end

function draw_screen()
  if screen_number==1 then
  screen.move(0, 24)
  screen.text("amp: ".. amp) 
  screen.move(0, 32)
  screen.text("density: ".. density) 
  screen.move(0, 40)
  screen.text("clarity: ".. clarity) 
  screen.move(0, 48)
  screen.text("X: ".. x_coord) 
  screen.move(32, 48)
  screen.text("Y: ".. y_coord)
  screen.move(0, 58)
  screen.text("Processing: ".. processingtext) 
  end
  if screen_number==0 then
    screen.move(0,18)
    screen.text("C: "..decode(quadrants[1]))
    screen.move(0,26)
    screen.text("1: "..decode(quadrants[2]))
    screen.move(0,34)
    screen.text("2: "..decode(quadrants[3]))
    screen.move(0,42)
    screen.text("3: "..decode(quadrants[4]))
    screen.move(0,50)
    screen.text("4: "..decode(quadrants[5]))
    screen.move(0,60)
    screen.text("P: "..processingtext)
    screen.rect(63,0,32,32)
    screen.level(8)
    screen.stroke()
    screen.rect(95,0,32,32)
    screen.level(8)
    screen.stroke()
    screen.rect(63,32,32,32)
    screen.level(8)
    screen.stroke()
    screen.rect(95,32,32,32)
    screen.level(8)
    screen.stroke()
    screen.rect(convertX(x_coord),convertY(y_coord),2,2)
    screen.level(16)
    screen.stroke()
    end
end

function convertX (val)
  return (val-0)/(1-0) * (124-65) + 65
end

function convertY (val)
  return (val-0)/(1-0) * (2-61) + 61
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("SWAY")
  draw_screen()
  screen.update()
end

function decode(num)
  if num==1 then
  return "Silence"
  end
    if num ==2 then
    return "Delay"
    end
      if num ==3 then
      return "Reverb"
      end
        if num ==4 then
        return "Amp Mod"
        end
              if num ==5 then
              return "Pitchbend"
              end
                if num ==6 then
                return "Cascade"
                end
                  if num ==7 then
                  return "Filter"
                  end
                    if num ==8 then
                    return "Freeze"
                    end
end
  
function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  end
end

function key(n,z)
  if n == 2 and z== 1 then
    if screen_number==0 then
    screen_number = 1
    else
      screen_number=0
      end
    end
end
