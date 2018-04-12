engine.name = 'TestSine'

init = function()
  params:add_number("num")
  params:add_option("output",{"MIDI","OSC","SYNTH","CV"})
  params:add_control("something",controlspec.unipolar())
  params:add_control("freq",controlspec.freq())
  params:set_action("freq",engine.hz)
  
  params:read("ptest.pset")
end

key = function(n,z)
  if z==1 then
    if n == 2 then
      params:read("ptest.pset")
    elseif n==3 then
      params:write("ptest.pset")
    end
  end
  redraw()
end

enc = function(n,d)
  if n == 2 then
    params:delta("freq",d/10)
  elseif n==3 then
    params:delta("freq",d)
  end
  redraw()
end

redraw = function()
  screen.clear()
  screen.move(0,10)
  screen.level(15)
  screen.text("freq: "..params:string("freq"))
  screen.update()
end


cleanup = function() 
  params:write("ptest.pset")
end
