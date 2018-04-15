fs = require "fileselect"

engine.name = "SoftCut"

init = function()
  print("============================== mlr")
  engine.recRun(1,1)
  engine.start(1)
  engine.reset(1)
  engine.adc_rec(1,1,1)
  engine.play_dac(1,1,1)
  --engine.play_rec(1,1,0)
  engine.loopStart(1,0)
  engine.loopEnd(1,0.4)
  engine.loopFlag(1,1)
  engine.rec(1,1)
  engine.pre(1,0.5)
  engine.amp(1,1)


  params:add_control("feedback")
  set_feedback = function(x) engine.pre(1,x) end
  params:set_action("feedback", set_feedback)

  params:add_control("llen")
  set_llen = function(x) engine.loopEnd(1,x) end
  params:set_action("llen",set_llen) 

  params:add_control("rate")
  set_rate = function(x) engine.rate(1,x) end
  params:set_action("rate",set_rate)

  p = poll.set('phase_1', new_pos)
  p.time = 0.5;
  p:start()
  pos = 0
end

key = function(n,z)
  if n==3 then
    if z == 1 then
      engine.clear(1)
      engine.rec(1,1)
      engine.adc_rec(1,1,1)
      --norns.audio.monitor_level(0.2)
    else
      engine.rec(1,0)
      engine.adc_rec(1,1,0)
      --norns.audio.monitor_level(0)
    end
  elseif n==2 then
    if z ==1 then engine.stop(1)
    else engine.start(1) end
  elseif n==1 and z==1 then
    fs.enter("/home/pi/dust", newfile)
  end
end

newfile = function(what)
  print(what)
end

enc = function(n,d)
  if n==2 then params:delta("llen",d)
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
  screen.text(params:get("rate"))
  screen.update()
  screen.move(70,30)
  screen.text(params:get("llen"))
  screen.update()
end

new_pos = function(x)
  pos = x
  --redraw()
end

cleanup = function()
  p:stop()
end
