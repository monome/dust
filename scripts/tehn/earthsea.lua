-- earthsea
--
-- subtractive polysynth
-- controlled by midi or grid
-- 
-- grid pattern player:
-- 1 1 record toggle
-- 1 2 play toggle
-- 1 8 transpose mode

local tab = require 'tabutil'
local pattern_time = require 'pattern_time'

local mode_transpose = 0
local root = { x=5, y=5 }
local trans = { x=5, y=5 }
local lit = {}

engine.name = 'PolySub'

-- pythagorean minor/major, kinda
local ratios = { 1, 9/8, 6/5, 5/4, 4/3, 3/2, 27/16, 16/9 }
local base = 27.5 -- low A

local function getHz(deg,oct)
  return base * ratios[deg] * (2^oct)
end

local function getHzET(note)
  return 55*2^(note/12)
end
-- current count of active voices
local nvoices = 0

function init()
  pat = pattern_time.new()
  pat.process = grid_note_trans

  params:add_control("shape", controlspec.new(0,1,"lin",0,0,""))
  params:set_action("shape", function(x) engine.shape(x) end)

  params:add_control("timbre", controlspec.new(0,1,"lin",0,0.5,""))
  params:set_action("timbre", function(x) engine.timbre(x) end)

  params:add_control("noise", controlspec.new(0,1,"lin",0,0,""))
  params:set_action("noise", function(x) engine.noise(x) end)

  params:add_control("cut", controlspec.new(0,32,"lin",0,8,""))
  params:set_action("cut", function(x) engine.cut(x) end)
  
  params:add_control("fgain", controlspec.new(0,6,"lin",0,0,""))
  params:set_action("fgain", function(x) engine.fgain(x) end)

  params:add_control("cutEnvAmt", controlspec.new(0,1,"lin",0,0,""))
  params:set_action("cutEnvAmt", function(x) engine.cutEnvAmt(x) end)

  params:add_control("detune", controlspec.new(0,1,"lin",0,0,""))
  params:set_action("detune", function(x) engine.detune(x) end)

  params:add_control("ampAtk", controlspec.new(0.01,10,"lin",0,0.05,""))
  params:set_action("ampAtk", function(x) engine.ampAtk(x) end)

  params:add_control("ampDec", controlspec.new(0,2,"lin",0,0.1,""))
  params:set_action("ampDec", function(x) engine.ampDec(x) end)

  params:add_control("ampSus", controlspec.new(0,1,"lin",0,1,""))
  params:set_action("ampSus", function(x) engine.ampSus(x) end)

  params:add_control("ampRel", controlspec.new(0.01,10,"lin",0,1,""))
  params:set_action("ampRel", function(x) engine.ampRel(x) end)

  params:add_control("cutAtk", controlspec.new(0.01,10,"lin",0,0.05,""))
  params:set_action("cutAtk", function(x) engine.cutAtk(x) end)

  params:add_control("cutDec", controlspec.new(0,2,"lin",0,0.1,""))
  params:set_action("cutDec", function(x) engine.cutDec(x) end)

  params:add_control("cutSus", controlspec.new(0,1,"lin",0,1,""))
  params:set_action("cutSus", function(x) engine.cutSus(x) end)

  params:add_control("cutRel", controlspec.new(0.01,10,"lin",0,1,""))
  params:set_action("cutRel", function(x) engine.cutRel(x) end)


  engine.level(0.05)
  engine.stopAll()

  params:read("tehn/earthsea.pset")

  params:bang()

  if g then gridredraw() end
end

function gridkey(x, y, z)
  if x == 1 then
    if z == 1 then
      if y == 1 and pat.rec == 0 then
        mode_transpose = 0
        trans.x = 5
        trans.y = 5 
        pat:stop()
        engine.stopAll()
        pat:clear()
        pat:rec_start()
      elseif y == 1 and pat.rec == 1 then
        pat:rec_stop()
        if pat.count > 0 then
          root.x = pat.event[1].x
          root.y = pat.event[1].y
          trans.x = root.x
          trans.y = root.y
          pat:start()
        end
      elseif y == 2 and pat.play == 0 and pat.count > 0 then
        if pat.rec == 1 then
          pat:rec_stop()
        end
        pat:start()
      elseif y == 2 and pat.play == 1 then
        pat:stop()
        engine.stopAll()
        nvoices = 0
        lit = {}
      elseif y == 8 then
        mode_transpose = 1 - mode_transpose
      end
    end
  else
    if mode_transpose == 0 then
      local e = {}
      e.id = x*8 + y
      e.x = x
      e.y = y 
      e.state = z 
      pat:watch(e)
      grid_note(e)
    else
      trans.x = x
      trans.y = y 
    end
  end
  gridredraw()
end


function grid_note(e)
  if e.state > 0 then
    if nvoices < 6 then
      --engine.start(id, getHz(x, y-1))
      --print("grid > "..id.." "..note)
      local note = ((7-e.y)*5) + e.x
      engine.start(e.id, getHzET(note))
      lit[e.id] = {}
      lit[e.id].x = e.x
      lit[e.id].y = e.y
      nvoices = nvoices + 1
      redraw()
    end
  else
    engine.stop(e.id)
    lit[e.id] = nil
    nvoices = nvoices - 1
  end 
  gridredraw()
end

function grid_note_trans(e)
  if e.state > 0 then
    if nvoices < 6 then
      --engine.start(id, getHz(x, y-1))
      --print("grid > "..id.." "..note)
      local note = ((7-e.y+(root.y-trans.y))*5) + e.x + (trans.x-root.x)
      engine.start(e.id, getHzET(note))
      lit[e.id] = {}
      lit[e.id].x = e.x + trans.x - root.x
      lit[e.id].y = e.y + trans.y - root.y
      nvoices = nvoices + 1
      redraw()
    end
  else
    engine.stop(e.id)
    lit[e.id] = nil
    nvoices = nvoices - 1
  end 
  gridredraw()
end

function gridredraw()
  g:all(0)
  g:led(1,1,2 + pat.rec * 10)
  g:led(1,2,2 + pat.play * 10)
  g:led(1,8,2 + mode_transpose * 10) 

  if mode_transpose == 1 then g:led(trans.x, trans.y, 4) end
  for i,e in pairs(lit) do
    g:led(e.x, e.y,15)
  end

  g:refresh()
end



function enc(n,delta)
  if n == 1 then
    mix:delta("output", delta)
  end
end

function key(n,z)
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.line_width(1)
  screen.level(15)
  screen.circle(math.random()*128,math.random()*64,math.random()*30)
  screen.stroke()
  screen.update()
end

local function note_on(note, vel)
  if nvoices < 6 then
    --engine.start(id, getHz(x, y-1))
    engine.start(note, getHzET(note))
    nvoices = nvoices + 1
    redraw()
  end
end

local function note_off(note, vel)
  engine.stop(note)
  nvoices = nvoices - 1
end

local function midi_event(data)
  if data[1] == 144 then
    note_on(data[2], data[3])
  elseif data[1] == 128 then
    note_off(data[2])
  elseif status == 176 then
    --cc(data1, data2)
  elseif status == 224 then
    --bend(data1, data2)
  end
end

midi.add = function(dev)
  print('earthsea: midi device added', dev.id, dev.name)
  dev.event = midi_event
end

function cleanup()
  engine.stopAll()
  pat:stop()
  pat = nil
  for id,dev in pairs(midi.devices) do
    dev.event = nil
  end
end
