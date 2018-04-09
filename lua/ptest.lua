engine = 'TestSine'

spec = controlspec.new(0, 100, 'lin', 1, 0, "bits", false, 1, 1)

init = function()
  p.number = param.new("number")
  p.something = param.new("something",spec)
  p.freq = param.new("freq",controlspec.freq())
  p.freq.action = e.hz
  p.bi = param.new("bi",controlspec.bipolar())
  local l = {"true", "false"}
  p.news = option.new("news",l)
  p.news.action = function(i) print(p.news:string()) end
  p.mode = option.new("mode",{"MIDI","OSC","SYNTH","CV"})
  paramset.read(p,"ptest.pset")
  paramset.bang(p)
end

key = function(n,z)
  if z==1 then
    if n == 2 then
      print("-- "..p.freq:get())
    elseif n==3 then
      p.news:delta(1)
    end
  end
end

enc = function(n,d)
  if n == 2 then
    p.freq:delta(d/10)
  elseif n==1 then
    p.news:delta(d)
  end
end


cleanup = function() 
  paramset.write(p,"ptest.pset")
end
