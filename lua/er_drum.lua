-- euclidean drummer
--
--

require 'er'

engine.name = 'Ack'

function reer(i)
  if track[i].k == 0 then
    for n=1,32 do track[i].s[n] = false end
  else
    track[i].s = er(track[i].k,track[i].n)
  end
end

track = {}
for i=1,4 do
  track[i] = {}
  track[i].k = 1
  track[i].n = 4
  track[i].pos = 1
  reer(i)
end
track_edit = 1

init = function()
  print("er")
  t = metro.alloc()
  t.count = -1
  t.time = 0.25
  t.callback = function()
    for i=1,4 do
      track[i].pos = track[i].pos + 1
      if track[i].pos > track[i].n then track[i].pos = 1 end
    end
    redraw()
  end
  t:start()
end

key = function(n,z)
  if n==3 and z==1 then
    track_edit = track_edit + 1
    if track_edit == 5 then track_edit = 1 end
  end
  redraw() 
end


enc = function(n,d) 
  if n == 2 then
    track[track_edit].k = util.clamp(track[track_edit].k+d,0,track[track_edit].n)
  elseif n==3 then 
    track[track_edit].n = util.clamp(track[track_edit].n+d,0,32)
    track[track_edit].k = util.clamp(track[track_edit].k,0,track[track_edit].n)
  end
  reer(track_edit)
  redraw()
end

redraw = function()
  screen.aa(0)
  screen.clear()
  for i=1,4 do
    screen.level((i == track_edit) and 15 or 4)
    screen.move(5, i*10 + 10)
    screen.text_center(track[i].k)
    screen.move(20,i*10 + 10)
    screen.text_center(track[i].n)

    for x=1,track[i].n do
      screen.level(track[i].pos==x and 15 or 2)
      screen.move(x*3 + 30, i*10 + 10)
      if track[i].s[x] then
        screen.line_rel(0,-8)
      else
        screen.line_rel(0,-2)
      end 
      screen.stroke() 
    end
  end
  screen.update()
end

