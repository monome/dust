-- MLR
--
-- /////////
-- ////
-- ////////////
-- //////////
-- ///////
-- /
-- ////
-- //
-- /////////
-- ///
-- /
--
-- ////
-- /
--
-- /
--
--

engine.name = "SoftCut"

TRACKS = 4
FADE = 0.01

vREC = 1
vCUT = 2 
vTIME = 15

-- events
eCUT = 1
eSTOP = 2
eSTART = 3
eLOOP = 4
eSPEED = 5
eREV = 6

quantize = 0
q = metro[10]
q.time = 0.125
q.count = -1
q.callback = event_q_clock

quantize_init = function()
  q:start()
end

update_tempo = function()
  local t = params:get("tempo")
  local d = params:get("quant_div")
  local interval = (60/t) / d
  print("q > "..interval)
  q.time = interval
  for i=1,4 do
    if params:get("tempo_map"..i) == 1 then

    end
  end
end


event = function(e)
  if quantize == 1 then
    event_q(e)
  else 
    for i=1,4 do
      if pattern[i].rec == 1 then
        pattern_rec_event(i,e)
      end
    end 
    event_exec(e)
  end
end

quantize_events = {}

event_q = function(e)
  table.insert(quantize_events,e)
end

event_q_clock = function()
  if #quantize_events > 0 then
    for k,e in pairs(quantize_events) do
      for i=1,4 do
        if pattern[i].rec == 1 then
          pattern_rec_event(i,e)
        end
      end 
      event_exec(e)
    end
    quantize_events = {}
  end
end


event_exec = function(e) 
  if e.t==eCUT then
    if track[e.i].loop == 1 then
      track[e.i].loop = 0
      engine.loop_start(e.i,track[e.i].clip_start)
      engine.loop_end(e.i,track[e.i].clip_end)
    end
    local cut = (e.pos/16)*track[e.i].clip_len + track[e.i].clip_start 
    engine.pos(e.i,cut)
    engine.reset(e.i)
    if track[e.i].play == 0 then
      track[e.i].play = 1
      engine.start(e.i)
    end 
  elseif e.t==eSTOP then
    track[e.i].play = 0
    track[e.i].pos_grid = -1
    engine.stop(e.i) 
    gridredraw()
  elseif e.t==eSTART then
    track[e.i].play = 1
    engine.start(e.i)
    gridredraw()
  elseif e.t==eLOOP then
    track[e.i].loop = 1
    track[e.i].loop_start = e.loop_start
    track[e.i].loop_end = e.loop_end
    --print("LOOP "..track[e.i].loop_start.." "..track[e.i].loop_end)
    local lstart = track[e.i].clip_start + (track[e.i].loop_start-1)/16*track[e.i].clip_len
    local lend = track[e.i].clip_start + (track[e.i].loop_end)/16*track[e.i].clip_len
    --print(">>>> "..lstart.." "..lend)
    engine.loop_start(e.i,lstart)
    engine.loop_end(e.i,lend) 
    if view == vCUT then gridredraw() end
  elseif e.t==eSPEED then
    track[e.i].speed = e.speed
    n = math.pow(2,track[e.i].speed + params:get("speed_mod"..e.i))
    if track[e.i].rev == 1 then n = -n end
    engine.rate(e.i,n) 
    if view == vREC then gridredraw() end
  elseif e.t==eREV then
    track[e.i].rev = e.rev
    n = math.pow(2,track[e.i].speed + params:get("speed_mod"..e.i))
    if track[e.i].rev == 1 then n = -n end
    engine.rate(e.i,n) 
    if view == vREC then gridredraw() end
  end
end

  

------ patterns
pattern = {}

pattern_init = function()
  for i=1,4 do
    pattern[i] = {}
    pattern_clear(i)
  end
end 

pattern_clear = function(x)
  print("clear pattern "..x)
  pattern[x].rec = 0
  pattern[x].play = 0
  pattern[x].prev_time = 0
  pattern[x].event = {}
  pattern[x].time = {}
  pattern[x].count = 0
  pattern[x].step = 0

  pattern[x].metro = metro[x]
  pattern[x].metro.count = 1
  pattern[x].metro.callback = function(n) pattern_next(x) end
end

pattern_rec_start = function(x)
  print("pattern rec start "..x)
  pattern[x].rec = 1
end

pattern_rec_stop = function(x)
  if pattern[x].rec == 1 then
    pattern[x].rec = 0
    if pattern[x].count ~= 0 then
      print("count "..pattern[x].count)
      local t = pattern[x].prev_time
      pattern[x].prev_time = util.time()
      pattern[x].time[pattern[x].count] = pattern[x].prev_time - t
      --tab.print(pattern[x].time)
    else
      print("no events recorded")
    end 
  else print("not recording")
  end
end

pattern_rec_event = function(x,e)
  local c = pattern[x].count + 1
  if c == 1 then
    pattern[x].prev_time = util.time() 
    --print("first event")
  else
    local t = pattern[x].prev_time
    pattern[x].prev_time = util.time()
    pattern[x].time[c-1] = pattern[x].prev_time - t
    --print(pattern[x].time[c-1])
  end
  pattern[x].count = c
  pattern[x].event[c] = e
end

pattern_start = function(x)
  print("start pattern "..x)
  pattern[x].play = 1
  pattern[x].step = 1
  pattern[x].metro.time = pattern[x].time[1]
  pattern[x].metro:start() 
end 

pattern_next = function(x)
  if pattern[x].step == pattern[x].count then pattern[x].step = 1
  else pattern[x].step = pattern[x].step + 1 end 
  --print("next step "..pattern[x].step)
  event_exec(pattern[x].event[pattern[x].step])
  pattern[x].metro.time = pattern[x].time[pattern[x].step]
  --print("next time "..pattern[x].metro.time)
  pattern[x].metro:start() 
end

pattern_stop = function(x)
  if pattern[x].play == 1 then
    print("stop pattern "..x)
    pattern[x].play = 0
    pattern[x].metro:stop()
  else print("not playing") end
end
  

view = vREC
view_prev = view

v = {}
v.key = {}
v.enc = {}
v.redraw = {}
v.gridkey = {}
v.gridredraw = {}

viewinfo = {}
viewinfo[vREC] = 0
viewinfo[vCUT] = 0
viewinfo[vTIME] = 0

focus = 1
alt = 0

track = {}
for i=1,4 do
  track[i] = {}
  track[i].play = 0
  track[i].rec = 0
  track[i].rec_level = 1
  track[i].pre_level = 0
  track[i].length = 4
  track[i].loop = 0
  track[i].loop_start = 0
  track[i].loop_end = 16 
  track[i].clip_start = 1 + (i-1)*10
  track[i].clip_len = 4
  track[i].clip_end = track[i].clip_start + track[i].clip_len
  track[i].step_time = 0.25
  track[i].pos = 0
  track[i].pos_grid = -1
  track[i].speed = 0
  track[i].rev = 0 
  track[i].tempo_map = 0
  track[i].bpm = 1
end

calc_quant = function(i)
  local q = (track[i].clip_len/16)
  track[i].step_time = q
  print("q > "..q)
  return q
end

calc_quant_off = function(i, q)
  local off = q
  while off < track[i].clip_start do
    off = off + q
  end
  off = off - track[i].clip_start
  print("off > "..off)
  return off
end

set_clip_length = function(i, len)
  track[i].clip_len = len
  track[i].clip_end = track[i].clip_start + len
  engine.loop_end(i,track[i].clip_end) 
  local q = calc_quant(i)
  local off = calc_quant_off(i, q)
  engine.quant(i,q)
  engine.quant_offset(i,off)
end


held = {}
heldmax = {}
done = {}
first = {}
for i = 1,8 do
  held[i] = 0
  heldmax[i] = 0
  done[i] = 0
  first[i] = 0
end


key = function(n,z) _key(n,z) end
enc = function(n,d) _enc(n,d) end
redraw = function() _redraw() end
gridkey = function(x,y,z) _gridkey(x,y,z) end

set_view = function(x)
  --print("set view: "..x)
  if x == -1 then x = view_prev end 
  view_prev = view
  view = x
  _key = v.key[x]
  _enc = v.enc[x]
  _redraw = v.redraw[x]
  _gridkey = v.gridkey[x]
  gridredraw = v.gridredraw[x]
  redraw()
  gridredraw()
end 

UP1 = controlspec.new(0, 1, 'lin', 0, 1, "")

-------------------- init
init = function() 
  params:add_number("tempo",40,240,92)
  params:set_action("tempo", function(x) set_tempo(x) end)
  params:add_number("quant_div",1,32,4)
  params:set_action("quant_div",function(x) set_div(x) end)
  p = {}
  for i=1,TRACKS do
    engine.pre(i,track[i].pre_level)
    engine.pre_lag(i,0.25)
    engine.fade_pre(i,FADE)
    engine.amp(i,1)
    engine.rec_on(i,0)
    engine.rec(i,track[i].rec_level)
    engine.rec_lag(i,0.25)
    engine.fade_rec(i,FADE)

    engine.adc_rec(1,i,0.8)
    engine.adc_rec(2,i,0.8)
    engine.play_dac(i,1,1)
    engine.play_dac(i,2,1)

    engine.loop_start(i,track[i].clip_start)
    engine.loop_end(i,track[i].clip_end)
    engine.loop_on(i,1)
    engine.quant(i,calc_quant(i))

    engine.fade_rec(i,0.1)
    engine.fade(i,FADE)
    engine.env_time(i,0.1)

    engine.rate_lag(i,0)

    --engine.reset(i)

    p[i] = poll.set("phase_quant_"..i, function(x) phase(i,x) end)
    p[i]:start()

    params:add_control("vol"..i,UP1)
    params:set_action("vol"..i, function(x) engine.amp(i,x) end)
    params:add_control("rec"..i,UP1)
    params:set_action("rec"..i, function(x) engine.rec(i,x) end)
    params:add_control("pre"..i,controlspec.UNIPOLAR)
    params:set_action("pre"..i, function(x) engine.pre(i,x) end)
    params:add_control("speed_mod"..i, controlspec.BIPOLAR)
    params:set_action("speed_mod"..i, function() speed_mod(i) end)
  end 

  quantize_init()
  pattern_init()
  set_view(vREC)
  gridredraw()
end

-- poll callback
phase = function(n, x)
  --if n == 1 then print(x) end
  local pp = ((x - track[n].clip_start) / track[n].clip_len)-- * 16 --TODO 16=div
  --x = math.floor(track[n].pos*16)
  --if n==1 then print("> "..x.." "..pp) end
  x = math.floor(pp * 16)
  if x ~= track[n].pos_grid then
    track[n].pos_grid = x
    if view == vCUT then gridredraw() end
  end 
end 


speed_mod = function(i)
  local n = math.pow(2,track[i].speed + params:get("speed_mod"..i))
  if track[i].rev == 1 then n = -n end
  if track[i].tempo_map == 1 then
    local bpmmod = track[i].bpm / params:get("tempo")
    print("bpmmod: "..bpmmod)
    n = n * bpmmod 
  end
  engine.rate(i,n) 
  if view == vREC then redraw() end 
end

  

gridkey_nav = function(x,z)
  if z==1 then
    if x==1 then set_view(vREC)
    elseif x>4 and x <9 then
      i = x - 4 
      if alt == 1 then
        pattern_rec_stop(i)
        pattern_stop(i)
        pattern_clear(i)
      elseif pattern[i].rec == 1 then
        pattern_rec_stop(i)
      elseif pattern[i].count == 0 then
        pattern_rec_start(i)
      elseif pattern[i].play == 1 then
        pattern_stop(i)
      else pattern_start(i)
      end 
    elseif x==2 then set_view(vCUT)
    elseif x==15 and alt == 0 then 
      quantize = 1 - quantize
      if quantize == 0 then q:stop()
      else q:start()
      end 
    elseif x==15 and alt == 1 then
      set_view(vTIME)
    elseif x==16 then alt = 1
    end
  elseif z==0 then
    if x==16 then alt = 0 end
    if x==15 and view == vTIME then set_view(-1) end
  end
  gridredraw()
end

gridredraw_nav = function()
  -- indicate view
  g:led(view,1,15)
  if alt==1 then g:led(16,1,9) end
  if quantize==1 then g:led(15,1,9) end
  for i=1,4 do
    if pattern[i].rec == 1 then g:led(i+4,1,15)
    elseif pattern[i].play == 1 then g:led(i+4,1,9)
    elseif pattern[i].count > 0 then g:led(i+4,1,5)
    else g:led(i+4,1,3) end
  end 
end

-------------------- REC
function fileselect_callback(path)
  if path ~= "cancel" then
    print("file > "..focus.." "..path.." "..track[focus].clip_start)
    engine.read(path, track[focus].clip_start, 1000) -- FIXME 1000 seconds to load
    local ch, len = sound_file_inspect(path)
    print("file length > "..len)
    set_clip_length(focus,len / 48000) 
    local bpm = 60 / (len/48000)
    while bpm < 60 do 
      bpm = bpm * 2
      print("bpm > "..bpm)
    end
    track[focus].bpm = bpm

  end
end 

v.key[vREC] = function(n,z)
  if n==1 and z==1 then
    fileselect.enter("/home/pi/dust", fileselect_callback)
  elseif n==2 and z==1 then
    viewinfo[vREC] = 1 - viewinfo[vREC]
    redraw()
  end
end

v.enc[vREC] = function(n,d)
  if viewinfo[vREC] == 0 then
    if n==2 then
      params:delta("vol"..focus,d)
    elseif n==3 then
      params:delta("speed_mod"..focus,d)
    end 
  else 
    if n==2 then
      params:delta("rec"..focus,d)
    elseif n==3 then
      params:delta("pre"..focus,d)
    end 
  end
  redraw()
end

v.redraw[vREC] = function()
  screen.clear()
  screen.level(15)
  screen.move(10,30)
  screen.text("REC > "..focus)
  if viewinfo[vREC] == 0 then
    screen.move(10,50)
    screen.text(params:get("vol"..focus))
    screen.move(70,50)
    screen.text(params:get("speed_mod"..focus))
    screen.level(3)
    screen.move(10,60)
    screen.text("volume")
    screen.move(70,60)
    screen.text("speed mod")
  else
    screen.move(10,50)
    screen.text(params:get("rec"..focus))
    screen.move(70,50)
    screen.text(params:get("pre"..focus))
    screen.level(3)
    screen.move(10,60)
    screen.text("rec level")
    screen.move(70,60)
    screen.text("overdub") 
  end
  screen.update()
end

v.gridkey[vREC] = function(x, y, z)
  if y == 1 then gridkey_nav(x,z)
  else
    if z == 1 then 
      i = y-1
      if x>2 and x<5 then
        if alt == 1 then
          track[i].tempo_map = 1 - track[i].tempo_map
          speed_mod(i) 
          gridredraw()
        elseif focus ~= i then 
          focus = i
          redraw()
          gridredraw()
        end 
      elseif x==1 and y<6 then 
        track[i].rec = 1 - track[i].rec
        print("REC "..track[i].rec)
        engine.rec_on(i,track[i].rec)
        gridredraw()
      elseif x==16 and y<6 then
        if track[i].play == 1 then
          e = {}
          e.t = eSTOP
          e.i = i
          event(e)
        else
          e = {}
          e.t = eSTART
          e.i = i
          event(e)
        end 
        gridredraw()
      elseif x>8 and x<16 and y<6 then
        n = x-12
        e = {} e.t = eSPEED e.i = i e.speed = n
        event(e)
      elseif x==8 and y<6 then
        n = 1 - track[i].rev
        e = {} e.t = eREV e.i = i e.rev = n
        event(e)
      end 
    end 
  end
end

v.gridredraw[vREC] = function()
  if not g then return end
  g:all(0)
  g:led(3,focus+1,7)
  g:led(4,focus+1,7)
  for i=1,4 do
    local y = i+1
    g:led(1,y,3)--rec
    if track[i].rec == 1 then g:led(1,y,9) end
    if track[i].tempo_map == 1 then g:led(5,y,7) end -- tempo.map
    g:led(8,y,3)--rev
    g:led(16,y,3)--stop
    g:led(12,y,3)--speed=1
    g:led(12+track[i].speed,y,9)
    if track[i].rev == 1 then g:led(8,y,7) end
    if track[i].play == 1 then g:led(16,y,15) end 
  end
  gridredraw_nav()
  g:refresh();
end

--------------------CUT
v.key[vCUT] = function(n,z)
  print("CUT key")
end

v.enc[vCUT] = function(n,d)
  if n==2 then
    params:delta("vol"..focus,d)
  end 
  redraw()
end

v.redraw[vCUT] = function()
  screen.clear()
  screen.level(15)
  screen.move(10,30)
  screen.text("CUT > "..focus)
  if viewinfo[vCUT] == 0 then
    screen.move(10,50)
    screen.text(params:get("vol"..focus))
    --screen.move(70,50)
    --screen.text(params:get("loop_mod"..focus))
    screen.level(3)
    screen.move(10,60)
    screen.text("volume")
    --screen.move(70,60)
    --screen.text("speed mod")
  else
    screen.move(10,50)
    screen.text(params:get("rec"..focus))
    screen.move(70,50)
    screen.text(params:get("pre"..focus))
    screen.level(3)
    screen.move(10,60)
    screen.text("rec level")
    screen.move(70,60)
    screen.text("overdub") 
  end
  screen.update()
end

v.gridkey[vCUT] = function(x, y, z)
  if z==1 and held[y] then heldmax[y] = 0 end
  held[y] = held[y] + (z*2-1)
  if held[y] > heldmax[y] then heldmax[y] = held[y] end
  --print(held[y])

  if y == 1 then gridkey_nav(x,z)
  else
    i = y-1
    if z == 1 then 
      if focus ~= i then 
        focus = i
        redraw()
      end
      if alt == 1 and y<6 then
        e = {} e.t = eSTOP e.i = i
        event(e)
      elseif y<6 and held[y]==1 then
        first[y] = x
        local cut = x-1
        --print("pos > "..cut)
        e = {} e.t = eCUT e.i = i e.pos = cut
        event(e)
      end 
    elseif z==0 then
      if y<6 and held[y] == 1 and heldmax[y]==2 then
        e = {}
        e.t = eLOOP
        e.i = i
        e.loop = 1
        e.loop_start = first[y]
        e.loop_end = x
        event(e)
      end
    end 
  end
end

v.gridredraw[vCUT] = function()
  if not g then return end
  g:all(0)
  gridredraw_nav()
  for i=1,4 do
    if track[i].loop == 1 then
      for x=track[i].loop_start,track[i].loop_end do
        g:led(x,i+1,4)
      end
    end 
    if track[i].play == 1 then
      g:led((track[i].pos_grid+1)%16, i+1, 15)
    end
  end
  g:refresh();
end




--------------------TIME
v.key[vTIME] = function(n,z)
  print("TIME key")
end

v.enc[vTIME] = function(n,d)
  if n==2 then
    params:delta("tempo",d)
  elseif n==3 then
    params:delta("quant_div",d)
  end 
  redraw()
end

v.redraw[vTIME] = function()
  screen.clear()
  screen.level(15)
  screen.move(10,30)
  screen.text("TIME")
  if viewinfo[vTIME] == 0 then
    screen.move(10,50)
    screen.text(params:get("tempo"))
    screen.move(70,50)
    screen.text(params:get("quant_div"))
    screen.level(3)
    screen.move(10,60)
    screen.text("tempo")
    screen.move(70,60)
    screen.text("quant div")
  end
  screen.update()
end

v.gridkey[vTIME] = function(x, y, z)
  if y == 1 then gridkey_nav(x,z)
  elseif z == 0 and y < 6 then
      quantize_set_time(track[y-1].step_time)
  end 
end

v.gridredraw[vTIME] = function()
  if not g then return end
  g:all(0)
  gridredraw_nav()
  g:refresh();
end




cleanup = function()
  p1:stop()
  p2:stop()
  p3:stop()
  p4:stop()
  q:stop()
end 
