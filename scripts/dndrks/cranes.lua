-- cranes
-- one buffer, two voices.
-- ---------------------
-- at start:
-- press key 2 to rec.
-- then:
-- press key 2 to play.
-- ..
-- listen: it's voice 1.
--
-- ////
-- head to params to find
-- speed + vol.
-- \\\\
--
-- *** back home: ***
-- key 1 (hold) = toggle loop pts
--    for voice 2
-- key 2 (after loop playing) =
--    toggle overwrite
-- key 3 = ~~ / 0.5 / 1.5 / 2
--    (see params)
-- key 3 + key 1 (hold) = erase
-- enc 1 = overwrite (see key 2)
--    (0 = add, 1 = clear)
-- enc 2/3 = vox 1 + 2 loop pts
--

engine.name = "SoftCut"

-- counting ms between key 2 taps
-- sets loop length
function count()
  rec_time = rec_time + 0.01
end

-- track recording state
rec = 0

function init()

  engine.loop_start(1,0)
  engine.loop_end(1,60)
  engine.loop_on(1,1)
  engine.pre(1,1)
  engine.amp(1,1)
  engine.rec_on(1,1)
  engine.rec(1,1)
  engine.adc_rec(1,1,1)
  engine.adc_rec(1,2,1)
  engine.play_dac(1,1,1)
  engine.play_dac(1,2,1)
  engine.rate(1,1)
  engine.rate_lag(1,0.6)
  engine.reset(1)

  engine.play_rec(1, 2, 1)
  engine.play_dac(2, 1, 1)
  engine.play_dac(2, 2, 1)
  engine.rec(2, 0)
  engine.pre(2, 1)
  engine.amp(2, 1)
  engine.rec_on(2, 1)
  engine.loop_on(2, 1)
  engine.loop_start(2, 0)
  engine.loop_end(2, 60)
  engine.reset(2)
  engine.rate(2,1)
  engine.rate_lag(2,0.35)

  engine.clear()
  engine.stop(1)
  engine.stop(2)

  params:add_option("speed_voice_1","speed voice 1", speedlist)
  params:set("speed_voice_1", 3)
  params:set_action("speed_voice_1", function(x) engine.rate(1, speedlist[params:get("speed_voice_1")]) end)
  params:add_option("speed_voice_2","speed voice 2", speedlist)
  params:set_action("speed_voice_2", function(x) engine.rate(2, speedlist[params:get("speed_voice_2")]) end)
  params:set("speed_voice_2", 3)
  params:add_control("vol_1","vol voice 1",controlspec.new(0,1,'lin',0,1,''))
  params:set_action("vol_1", function(x) engine.amp(1, x) end)
  params:add_control("vol_2","vol voice 2",controlspec.new(0,1,'lin',0,1,''))
  params:set_action("vol_2", function(x) engine.amp(2, x) end)
  params:set("vol_2", 0.0)

  params:add_number("KEY3","KEY3 ( ~~, 0.5, 1.5, 2 )",0,3,0)
  params:set_action("KEY3", function(x) KEY3 = x end)

  counter = metro.alloc(count, 0.01, -1)
  rec_time = 0

  KEY3_hold = false
  KEY1_hold = false
  local edit_mode = 2
end

function warble()
  local bufSpeed1 = speedlist[params:get("speed_voice_1")]
  if bufSpeed1 > 1.99 then
      ray = bufSpeed1 + (math.random(-15,15)/1000)
    elseif bufSpeed1 >= 1.0 then
      ray = bufSpeed1 + (math.random(-10,10)/1000)
    elseif bufSpeed1 >= 0.50 then
      ray = bufSpeed1 + (math.random(-4,5)/1000)
    else
      ray = bufSpeed1 + (math.random(-2,2)/1000)
  end
    engine.rate_lag(1,0.6 + (math.random(-30,10)/100))
    engine.rate(1,ray)
    screen.move(0,30)
    screen.text(ray)
    screen.update()
end

function half_speed()
  ray = speedlist[params:get("speed_voice_1")] / 2
  engine.rate_lag(1,0.6 + (math.random(-30,10)/100))
  engine.rate(1,ray)
  screen.move(0,30)
  screen.text(ray)
  screen.update()
end

function oneandahalf_speed()
  ray = speedlist[params:get("speed_voice_1")] * 1.5
  engine.rate_lag(1,0.6 + (math.random(-30,10)/100))
  engine.rate(1,ray)
  screen.move(0,30)
  screen.text(ray)
  screen.update()
end

function double_speed()
  ray = speedlist[params:get("speed_voice_1")] * 2
  engine.rate_lag(1,0.6 + (math.random(-30,10)/100))
  engine.rate(1,ray)
  screen.move(0,30)
  screen.text(ray)
  screen.update()
end

function restore_speed()
  ray = speedlist[params:get("speed_voice_1")]
  engine.rate_lag(1,0.6)
  engine.rate(1,speedlist[params:get("speed_voice_1")])
  redraw()
end

function clear_all()
  engine.stop(1)
  engine.stop(2)
  engine.clear()
  ray = speedlist[params:get("speed_voice_1")]
  engine.loop_start(1,0)
  engine.loop_end(1,60)
  engine.loop_start(2,0)
  engine.loop_end(2,60)
  start_point_1 = 0
  start_point_2 = 0
  end_point_1 = 60
  clear = 1
  rec_time = 0
  rec = 0
  crane_redraw = 0
  crane2_redraw = 0
  c2 = math.random(4,15)
  restore_speed()
  redraw()
  KEY3_hold = false
end

-- variable dump
-- do any of these need to be 'local'?
down_time = 0
hold_time = 0
speedlist = {0.25, 0.5, 1.0, 2.0}
start_point_1 = 0
start_point_2 = 0
end_point_1 = 60
end_point_2 = 60
over = 0
clear = 1
ray = 0.0
KEY3 = 0
crane_redraw = 0
crane2_redraw = 0
c2 = math.random(4,12)

-- key hardware interaction
function key(n,z)
  -- KEY 2
  if n == 2 and z == 1 then
      rec = rec + 1
        -- if the buffer is clear and key 2 is pressed:
        -- main recording will enable
        if rec % 2 == 1 and clear == 1 then
          engine.clear()
          engine.reset(1)
          engine.rec_on(1,1)
          engine.start(1)
          engine.start(2)
          crane_redraw = 1
          redraw()
          counter:start()
        -- if the buffer is clear and key 2 is pressed again:
        -- main recording will disable, loop points set
        elseif rec % 2 == 0 and clear == 1 then
          clear = 0
          engine.reset(1)
          engine.rec_on(1,0)
          counter:stop()
          print("loop length: "..rec_time)
          end_point_1 = rec_time
          end_point_2 = end_point_1
          engine.loop_end(1,end_point_1)
          engine.loop_end(2,end_point_1)
          crane_redraw = 0
          redraw()
          rec_time = 0
        end
        -- if the buffer is NOT clear and key 2 is pressed:
        -- overwrite/overdub behavior will enable
        if rec % 2 == 1 and clear == 0 then
          engine.rec_on(1,1)
          crane_redraw = 1
          crane2_redraw = 1
          redraw()
        -- if the buffer is NOT clear and key 2 is pressed again:
        -- overwrite/overdub behavior will disable
        elseif rec % 2 == 0 and clear == 0 then
          engine.rec_on(1,0)
          crane_redraw = 0
          crane2_redraw = 0
          redraw()
        end
  end

  -- KEY 3
  -- all based on Parameter choice
  if n == 3 and z == 1 and KEY3 == 0 then
    KEY3_hold = true
    warble()
  elseif n == 3 and z == 1 and KEY3 == 1 then
    KEY3_hold = true
    half_speed()
  elseif n == 3 and z == 1 and KEY3 == 2 then
    KEY3_hold = true
    oneandahalf_speed()
  elseif n == 3 and z == 1 and KEY3 == 3 then
    KEY3_hold = true
    double_speed()
  elseif n == 3 and z == 0 then
    KEY3_hold = false
    restore_speed()
  end

  -- KEY 1
  -- hold key 1 to clear the buffers
  if n == 1 and z == 1 and KEY3_hold == true then
    clear_all()
    KEY1_hold = false
  elseif n == 1 and z == 1 then
    KEY1_hold = true
    redraw()
  elseif n == 1 and z == 0 then
    KEY1_hold = false
    redraw()
  end
end

-- encoder hardware interaction
function enc(n,d)

  -- encoder 3: voice 1's loop end point
  if n == 3 and KEY1_hold == false then
    end_point_1 = util.clamp((end_point_1 + d/100),0.0,60.0)
    print("voice 1 loop end "..end_point_1)
    engine.loop_end(1,end_point_1)
    redraw()

  -- encoder 2: voice 1's loop start point
  elseif n == 2 and KEY1_hold == false then
    start_point_1 = util.clamp((start_point_1 + d/100),0.0,60.0)
    print("voice 1 loop start "..start_point_1)
    engine.loop_start(1,start_point_1)
    redraw()

  elseif n == 3 and KEY1_hold == true then
    end_point_2 = util.clamp((end_point_2 + d/100),0.0,60.0)
    print("voice 2 loop end "..end_point_2)
    engine.loop_end(2,end_point_2)
    redraw()

  elseif n == 2 and KEY1_hold == true then
    start_point_2 = util.clamp((start_point_2 + d/100),0.0,60.0)
    print("voice 2 loop start "..start_point_2)
    engine.loop_start(2,start_point_2)
    redraw()

  -- encoder 1: voice 1's overwrite/overdub amount
  -- 0 is full overdub
  -- 1 is full overwrite
  elseif n == 1 then
    over = util.clamp((over + d/100), 0.0,1.0)
    print("overdub: "..over)
    engine.pre(1,math.abs(over-1))
    redraw()
  end
end

-- displaying stuff on the screen
function redraw()
  screen.clear()
  screen.level(15)
  screen.move(0,50)
    if KEY1_hold == true then
      screen.text("S2: "..start_point_2)
    elseif KEY1_hold == false then
      screen.text("S1: "..start_point_1)
    end
  screen.move(0,60)
    if KEY1_hold == true then
      screen.text("E2: "..math.ceil(end_point_2 * (10^2))/(10^2))
    elseif KEY1_hold == false then
      screen.text("E1: "..math.ceil(end_point_1 * (10^2))/(10^2))
    end
  screen.move(0,40)
  screen.text("OVER: "..over)
  if crane_redraw == 1 then
    if crane2_redraw == 0 then
      crane()
    else
      crane2()
    end
  end
  screen.update()
  end

-- ALL JUST CRANE DRAWING FROM HERE TO END!
function crane()
  screen.level(13)
  screen.aa(1)
  screen.line_width(0.5)
  screen.move(50,60)
  screen.line(65,40)
  screen.move(65,40)
  screen.line(100,50)
  screen.move(100,50)
  screen.line(50,60)
  screen.move(60,47)
  screen.line(48,15)
  screen.move(48,15)
  screen.line(75,40)
  screen.move(73,43)
  screen.line(85,35)
  screen.move(85,35)
  screen.line(100,50)
  screen.move(100,50)
  screen.line(105,25)
  screen.move(105,25)
  screen.line(117,35)
  screen.move(117,35)
  screen.line(104,30)
  screen.move(105,25)
  screen.line(100,30)
  screen.move(100,30)
  screen.line(95,45)
  screen.move(97,40)
  screen.line(80,20)
  screen.move(80,20)
  screen.line(70,35)
  screen.stroke()
  screen.update()
end

function crane2()
  screen.level(3)
  screen.aa(1)
  screen.line_width(0.5)
  screen.move(100-c2+(c2/2),60-c2)
  if c2 > 30 then
    screen.text("/ - /")
  elseif c2 < 20 then
    screen.text(" | - / ")
  else
    screen.text("crane")
  end
  screen.move(65-c2,40-c2)
  screen.stroke()
  screen.update()
  c2 = math.random(4,40)
end
