-- Quadrangularis
--
-- Just-Intonation instrument
-- inspired by the fabled
-- 'tonality diamond'. This
-- thing is more of a 'tonality
-- square', but you can play
-- it!  Plug in a 128 grid, it
-- should light up a square
-- representing the tonality
-- diamond - mash the glowing
-- keys (plus the dim diagonal
-- of root notes), rock out to
-- those wild sounds hidden
-- between your guitar's frets.
--
-- It's (innacurately) named
-- after the Quadrangularis
-- Reversum, which is
-- (according to wikipedia) the
-- name of that crazy looking
-- marimba thing on the page
-- https://en.wikipedia.org/wiki
-- /Tonality_diamond.
--
-- Utonalities are in the top
-- right, otonalities in bottom
-- left.  All the ratios are
-- calculated inside this
-- program from first
-- principles, and the
-- generated fractions were
-- checked against the values
-- quoted by wikipedia...
--
-- Note this is *almost* a port
-- of a similar patch from the
-- aleph.  Luckily norns comes
-- with a bunch of polyphonic
-- synths ready to rock, so we
-- immediately experiment with
-- more than two tones...
-- still, that aleph patch had
-- onboard drum machine / white
-- whale to jam with... watch
-- this space!

local g = grid.connect()


local inc = 1
local b = 0

engine.name = 'PolyPerc'


function init()
  color = 3
  number = 84
  mode = 0
  grid_redraw()
  g.refresh()
  counter:start()
end


oct = 1
function key(n,z)
  if (n == 3) then
    if (z > 0) then
      oct = 2
    else
      oct = 1
    end
  end
  if (n == 2) then
    if (z > 0) then
      oct = 0.5
    else
      oct = 1
    end
  end
  redraw()
end

rel=1.0
function enc1(d)
  if(d > 0) then
    rel = rel * 1.05
  else
    rel = rel * 0.95
  end
  if (rel > 20.0) then
    rel = 20.0
  end
  if (rel < 0.2) then
    rel = 0.2
  end
  engine.release(rel)
end
pw = 0.5
function enc2(d)
  if(d > 0) then
    pw = pw + 0.02
  else
    pw = pw - 0.02
  end
  if (pw > 0.95) then
    pw = 0.95
  end
  if (pw < 0.5) then
    pw = 0.5
  end
  engine.pw(pw)
end

co =1.5
function enc3(d)
  if(d > 0) then
    co = co + 0.05
  else
    co = co - 0.05
  end
  if (co > 10.0) then
    co = 10.0
  end
  if (co < 0.5) then
    co = 0.5
  end
end

function enc(n,d)
  number = number + d
  redraw()
  if(n == 1) then
    enc1(d)
  end
  if(n == 2) then
    enc2(d)
  end
  if(n == 3) then
    enc3(d)
  end
end
function redraw()
  if mode == 0 then
    screen.clear()
    screen.level(color)
    screen.font_face(10)
    screen.font_size(15)
    screen.move(0,15)
    screen.text("release: " .. rel)
    screen.move(0,30)
    screen.text("cutoff: " .. co)
    screen.move(0,45)
    screen.text("pw: " .. pw)
    screen.move(0,60)
    screen.text("octave: " .. oct)
    screen.update()
  elseif mode == 1 then
    screen.clear()
    screen.move(0,20)
    screen.text("WILD")
    screen.aa(1)
    screen.line_width(2)
    screen.move(60,30)
    screen.line(80,40)
    screen.line(90,10)
    screen.close()
    screen.stroke()
    screen.update()
  end
end

nondividing_harmonics = function (limit, octave)
   res = {}
   for i = 12,limit,1 do
      print(i)
      if not isint(i / octave) then
	 table.insert(res, i)
      end
   end
   return res
end

tab = {}

function mapn(func, ...)
  local new_array = {}
  local i=1
  local arg_length = table.getn(arg)
  while true do
    local arg_list = map(function(arr) return arr[i] end, arg)
    if table.getn(arg_list) < arg_length then return new_array end
    new_array[i] = func(unpack(arg_list))
    i = i+1
  end
end
function map(func, array)
  local new_array = {}
  for i,v in ipairs(array) do
    new_array[i] = func(v)
  end
  return new_array
end

function table_concat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end
--- print the contents of a table
-- @param t table to print
tab.print = function(t)
   for k,v in pairs(t) do print(k .. '\t' .. tostring(v)) end
end

isint = function (n)
  return n==math.floor(n)
end

function inverse(n)
   return 1 / n
end

function nondividing_harmonics (limit, octave)
   res = {}
   for i = 2,limit,1 do
      if not isint(i / octave) then
	 table.insert(res, i)
      end
   end
   return res
end

function reduce_to_octave (n, octave)
   if (n >= octave) then
      return reduce_to_octave(n / octave, octave)
   else
      return n
   end
end

function increase_to_octave (n, octave)
   if (n * 2 <= octave) then
      return increase_to_octave(n * octave, octave)
   else
      return n
   end
end

function build_utonalities (limit, octave)
   res = map(function(n)
	 return increase_to_octave(n, 2)
	     end,
      map(inverse, nondividing_harmonics(11, 2)))
   table.sort(res, function(a,b) return a > b end)
   return table_concat({1}, res)
end

function build_otonalities (limit, octave)
   res = map(function(n)
	 return reduce_to_octave(n, 2)
	     end,
      nondividing_harmonics(11, 2))
   table.sort(res, function(a,b) return a < b end)
   return table_concat({1}, res)
end

print "utonalities:"
tab.print(build_utonalities(11, 2))
print "otonalities:"
tab.print(build_otonalities(11, 2))

function build_tonality_diamond (limit, octave)
   octave = octave or 2
   return map(function(ot)
	 return map (function (ut) return reduce_to_octave(ut * ot, octave) end,
	    build_utonalities(limit, octave))
	      end,
      build_otonalities(limit, octave))
end

-- print "tonality diamond:"
-- map(function(row)
--       map(function(el)
-- 	    io.write(el)
-- 	    io.write(", ")
-- 	  end,
-- 	 row)
--       io.write("\n")
--     end,
--    build_tonality_diamond(limit, octave))

d = build_tonality_diamond(11, 2)

function grid_redraw()
  for i=1,6,1 do
    for j=1,6,1 do
      if (i == j) then
        g.led(i,j,0)
      else
        g.led(i,j,8)
      end
    end
  end
end


g.event = function(x,y,z)
  if z==1 then
    engine.cutoff(440*d[x][y] * oct * co )
    engine.hz(440*d[x][y] * oct)
    g.led(x,y,z*15)
    g.refresh()
  else
    grid_redraw()
    g.refresh()
  end
end

counter = metro.alloc()
counter.time = 0.1
counter.count = -1
--counter.callback = grid_redraw
