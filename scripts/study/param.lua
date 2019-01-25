-- param test
-- see menu > parameters
-- hold key1 inside menu to read/write

engine.name = 'TestSine'

function init()
  engine.amp(0.1)
  params:add_number("num", "num")
  params:add_option("output", "output", {"MIDI", "OSC", "SYNTH", "CV"})
  params:add_control("something", "something",controlspec.UNIPOLAR)
  params:add_control("freq", "freq",controlspec.FREQ)
  params:set_action("freq",engine.hz)
  params:add_file("sample", "sample")
  
  params:read("ptest.pset")
end

function key(n,z)
  if z==1 then
    if n == 2 then
      params:read("ptest.pset")
    elseif n==3 then
      params:write("ptest.pset")
    end
  end
  redraw()
end

function enc(n,d)
  if n == 2 then
    params:delta("freq",d/10)
  elseif n==3 then
    params:delta("freq",d)
  end
  redraw()
end

function redraw()
  screen.clear()
  screen.move(0,10)
  screen.level(15)
  screen.text("freq: "..params:string("freq"))
  screen.update()
end


function cleanup() 
  params:write("ptest.pset")
end
