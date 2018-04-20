-- SOFTREPEAT (looper)
--
-- K1 held = load file
-- K2 start stop
-- K3 hold clears records
--          until release
-- E1 vol
-- E2 loop len
-- E3 speed

fs = require "fileselect"

engine.name = "SoftCut"

init = function()
  print("============================== mlr")
  engine.recRun(1,1)
  engine.adc_rec(1,1,0)
  engine.play_dac(1,1,1)
  engine.loopStart(1,0)
  engine.loopEnd(1,1)
  engine.loopFlag(1,1)
  engine.rec(1,1)
  engine.pre(1,1)
  engine.amp(1,1)
  engine.start(1)
  running = true

  params:add_control("amp")
  set_amp = function(x) engine.amp(1,x) end
  params:set_action("amp",set_amp) 
  params:set("amp",1)

  params:add_control("loop_end")
  set_llen = function(x) engine.loopEnd(1,x) end
  params:set_action("loop_end",set_llen) 
  params:set("loop_end",1)

  params:add_control("rate", controlspec.BIPOLAR)
  set_rate = function(x) engine.rate(1,x) end
  params:set_action("rate",set_rate)
  params:set("rate",1)

  p = poll.set('phase_1', new_pos)
  p.time = 0.5;
  --p:start()
  pos = 0
end

key = function(n,z)
  if n==3 then
    if z == 1 then
      engine.clear(1)
      engine.adc_rec(1,1,1)
      engine.start(1)
      running = true
    else
      engine.adc_rec(1,1,0)
    end
  elseif n==2 then
    if z==1 and running then
      engine.stop(1)
      running = false
    elseif z==1 then
      engine.reset(1)
      engine.start(1)
      running = true
    end
  elseif n==1 and z==1 then
    fs.enter("/home/pi/dust", newfile)
  end
end

newfile = function(what)
  if what ~= "cancel" then
    engine.clear(1)
    engine.read(1,what)
  end
end

enc = function(n,d)
  if n==1 then params:delta("amp",d*3)
  elseif n==2 then params:delta("loop_end",d)
  elseif n==3 then params:delta("rate",d)
  end
  redraw()
end

redraw = function()
  screen.clear()
  screen.level(15)
  screen.font_face(9)
  screen.font_size(24)
  screen.move(10,30)
  screen.text(params:get("loop_end"))
  screen.update()
  screen.font_size(10)
  screen.move(10,50)
  screen.text("loop")
  screen.font_size(24)
  screen.move(70,30)
  screen.text(params:get("rate"))
  screen.font_size(10)
  screen.move(70,50)
  screen.text("rate")
  screen.update()
end

-- poll callback
new_pos = function(x)
  pos = x
  --redraw()
end

cleanup = function()
  p:stop()
end
