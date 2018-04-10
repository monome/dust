engine = 'TestSine'

init = function()
  p:add_number("num")
  p:add_option("output",{"MIDI","OSC","SYNTH","CV"})
  p:add_param("something",controlspec.unipolar())
  p:add_param("freq",controlspec.freq())
  p:set_action("freq",e.hz)
  
  p:read("ptest.pset")
end

key = function(n,z)
  if z==1 then
    if n == 2 then
      p:read("ptest.pset")
    elseif n==3 then
      p:write("ptest.pset")
    end
  end
  redraw()
end

enc = function(n,d)
  if n == 2 then
    p:delta("freq",d/10)
  elseif n==3 then
    p:delta("freq",d)
  end
  redraw()
end

redraw = function()
  s.clear()
  s.move(0,10)
  s.level(15)
  s.text("freq: "..p:string("freq"))
  s.update()
end


cleanup = function() 
  p:write("ptest.pset")
end
