-- awake: time changes 
-- (grid optional)
--
-- top sequence plays.
-- bottom sequence adds
-- modifies note played.
--
-- ENC1 = tempo
-- ENC2 = nav
-- ENC3 = edit
-- KEY2 = morph
-- KEY3 = toggle edit
--
-- KEY3 hold + KEY2 = reset pos
-- KEY3 hold + ENC1 = transpose
-- KEY3 hold + ENC2/3 = lengths
--
-- KEY1 hold = ALT
-- ALT+ENC1 = scale mode
-- ALT+ENC2 = filter
-- ALT+ENC3 = release
--
-- modify sound params in
-- SYSTEM > AUDIO menu

local cs = require 'controlspec'

engine.name = 'PolyPerc'

local KEY3 = false
local alt = false

local one = {
  pos = 0,
  length = 8,
  data = {0,0,6,4,7,3,0,0,0,0,0,0,0,0,0,0}
}
local two = {
  pos = 0,
  length = 7,
  data = {6,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
}

local scale_degrees = {2,1,2,2,2,1,2}
local notes = {}
local freqs = {}

local edit_mode = 1
local edit_pos = 1

local BeatClock = require 'beatclock'
local clk = BeatClock.new()


function build_scale()
  local n = 0
  for i=1,16 do
    notes[i] = n
    n = n + scale_degrees[(params:get("scale mode") + i)%7 + 1]
  end
  --tab.print(notes)
  for i=1,16 do freqs[i] = 110*2^((notes[i]+params:get("trans"))/12) end
  --tab.print(freqs) 
end 

function init()
  print("grid/seek")
  
  clk.on_step = step
  clk.on_select_internal = function() clk:start() end
  clk.on_select_external = reset_pattern
  clk:add_clock_params()
  params:add_separator()

  params:add_number("scale mode",1,7,3)
  params:set_action("scale mode", function(n) 
    build_scale()
  end) 
  params:add_number("trans",-12,24,0)
  params:set_action("trans", function(n) 
    build_scale()
  end)
  params:add_separator()

  cs.AMP = cs.new(0,1,'lin',0,0.5,'')
  params:add_control("amp",cs.AMP)
  params:set_action("amp",
  function(x) engine.amp(x) end) 

  cs.PW = cs.new(0,100,'lin',0,50,'%')
  params:add_control("pw",cs.PW)
  params:set_action("pw",
  function(x) engine.pw(x/100) end) 

  cs.REL = cs.new(0.1,3.2,'lin',0,1.2,'s') 
  params:add_control("release",cs.REL)
  params:set_action("release",
  function(x) engine.release(x) end) 

  cs.CUT = cs.new(50,5000,'exp',0,555,'hz')
  params:add_control("cutoff",cs.CUT)
  params:set_action("cutoff",
  function(x) engine.cutoff(x) end) 

  cs.GAIN = cs.new(0,4,'lin',0,1,'')
  params:add_control("gain",cs.GAIN)
  params:set_action("gain",
  function(x) engine.gain(x) end) 

  params:read("tehn/awake.pset")
  params:bang()
  
  clk:start()
  
end
 
function step()
    
  one.pos = one.pos + 1
  if one.pos > one.length then one.pos = 1 end
  two.pos = two.pos + 1
  if two.pos > two.length then two.pos = 1 end

  if one.data[one.pos] > 0 then engine.hz(freqs[one.data[one.pos]+two.data[two.pos]]) end
  if g then
    gridredraw()
  end
  redraw()
end

function reset_pattern()
  one.pos = 0
  two.pos = 0
  clk:reset()
end

function gridkey(x, y, z)
  if z > 0 then
    if edit_mode == 1 then
      if one.data[x] == 9-y then
        one.data[x] = 0
      else
        one.data[x] = 9-y
      end
    else
      if two.data[x] == 9-y then
        two.data[x] = 0
      else
        two.data[x] = 9-y
      end 
    end
    gridredraw()
    redraw()
  end 
end

function gridredraw()
  g:all(0) 
  if edit_mode == 1 then
    for x = 1, 16 do
      if one.data[x] > 0 then g:led(x, 9-one.data[x], 5) end
    end
    if one.data[one.pos] > 0 then
      g:led(one.pos, 9-one.data[one.pos], 15)
    else
      g:led(one.pos, 1, 3)
    end
  else 
    for x = 1, 16 do
      if two.data[x] > 0 then g:led(x, 9-two.data[x], 5) end
    end
    if two.data[two.pos] > 0 then
      g:led(two.pos, 9-two.data[two.pos], 15)
    else
      g:led(two.pos, 1, 3)
    end
  end 
  g:refresh()
end

function enc(n, delta)
  if alt and n==1 then
    params:delta("scale mode",delta)
  elseif KEY3 and n==1 then
    params:delta("trans",delta)
  elseif n == 1 then
    params:delta("bpm",delta)
  elseif alt and n == 2 then
    params:delta("cutoff",delta)
  elseif alt and n == 3 then
    params:delta("release",delta)
  elseif KEY3 and n==2 then
    one.length = util.clamp(one.length+delta,1,16)
  elseif KEY3 and n==3 then
    two.length = util.clamp(two.length+delta,1,16)
  elseif n==3 then
    if edit_mode == 1 then
      one.data[edit_pos] = util.clamp(one.data[edit_pos]+delta,0,8) 
    else
      two.data[edit_pos] = util.clamp(two.data[edit_pos]+delta,0,8) 
    end
  elseif n==2 then
    local p = (edit_mode == 1) and one.length or two.length
    edit_pos = util.clamp(edit_pos+delta,1,p) 
  end 
  redraw()
end

function key(n,z)
  if n==1 then
    alt = z==1
  elseif n == 3 and z == 1 then
    KEY3 = true
    if edit_mode == 1 then
      edit_mode = 2
      if edit_pos > two.length then edit_pos = two.length end
    else
      edit_mode = 1
      if edit_pos > one.length then edit_pos = one.length end
    end
  elseif n==3 and z==0 then
    KEY3 = false
  elseif n == 2 and z == 1 then
    if KEY3 then
      reset_pattern()
    else
      if edit_mode == 1 then
        for i=1,one.length do
          if one.data[i] > 0 then
            one.data[i] = util.clamp(one.data[i]+math.floor(math.random()*3)-1,0,8)
          end
        end
      else
        for i=1,two.length do
          if two.data[i] > 0 then
            two.data[i] = util.clamp(two.data[i]+math.floor(math.random()*3)-1,0,8)
          end
        end
      end 
    end
  end
end

function redraw()
  screen.clear()
  screen.line_width(1)
  screen.aa(0)
  screen.move(26 + edit_pos*6, edit_mode==1 and 33 or 63)
  screen.line_rel(4,0)
  screen.level(15)
  screen.stroke()
  screen.move(32,30)
  screen.line_rel(one.length*6-2,0)
  screen.level(2)
  screen.stroke()
  screen.move(32,60)
  screen.line_rel(two.length*6-2,0)
  screen.level(2)
  screen.stroke()
  for i=1,one.length do
    if one.data[i] > 0 then
      screen.move(26 + i*6, 30 - one.data[i]*3)
      screen.line_rel(4,0)
      screen.level(i == one.pos and 15 or (edit_mode == 1 and 4 or 1))
      screen.stroke()
    end
  end
  for i=1,two.length do
    if two.data[i] > 0 then
      screen.move(26 + i*6, 60 - two.data[i]*3)
      screen.line_rel(4,0)
      screen.level(i == two.pos and 15 or (edit_mode == 2 and 4 or 1))
      screen.stroke()
    end
  end
  screen.level((not alt and not KEY3) and 15 or 4)
  screen.move(0,10)
  screen.text("TM:"..params:get("bpm"))
  screen.level(alt and 15 or 4)
  screen.move(0,20)
  screen.text("SM:"..params:get("scale mode"))
  screen.level(KEY3 and 15 or 4)
  screen.move(0,30)
  screen.text("TR:"..params:get("trans"))

  screen.level(4)
  screen.move(0,60)
  if alt then screen.text("SND")
  elseif KEY3 then screen.text("LOOP") end 
  screen.update()
end

midi.add = function(dev)
  print('awake: midi device added', dev.id, dev.name)
  midi_device = dev
end
midi.remove = function(dev)
  print('awake: midi device removed', dev.id, dev.name)
  midi_device = nil
end
