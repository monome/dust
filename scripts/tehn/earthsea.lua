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

local screen_framerate = 15
local screen_refresh_metro

local ripple_timeout = 0.5
local ripple_growth_rate = 50 / screen_framerate
local ripple_fade_rate = 1 / ripple_timeout / screen_framerate
local screen_notes = {}

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
  stop_all_screen_notes()

  params:read("earthsea.pset")

  params:bang()

  if g then gridredraw() end
  
  screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function(stage)
    redraw()
  end
  screen_refresh_metro:start(1 / screen_framerate)
  
  local startup_ani_count = 1
  local startup_ani_metro = metro.alloc()
  startup_ani_metro.callback = function(stage)
    start_screen_note(-startup_ani_count)
    stop_screen_note(-startup_ani_count)
    startup_ani_count = startup_ani_count + 1
  end
  startup_ani_metro:start( 0.1, 3 )
  
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
        stop_all_screen_notes()
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
        stop_all_screen_notes()
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
  local note = ((7-e.y)*5) + e.x
  if e.state > 0 then
    if nvoices < 6 then
      --engine.start(id, getHz(x, y-1))
      --print("grid > "..id.." "..note)
      engine.start(e.id, getHzET(note))
      start_screen_note(note)
      lit[e.id] = {}
      lit[e.id].x = e.x
      lit[e.id].y = e.y
      nvoices = nvoices + 1
    end
  else
    engine.stop(e.id)
    stop_screen_note(note)
    lit[e.id] = nil
    nvoices = nvoices - 1
  end 
  gridredraw()
end

function grid_note_trans(e)
  local note = ((7-e.y+(root.y-trans.y))*5) + e.x + (trans.x-root.x)
  if e.state > 0 then
    if nvoices < 6 then
      --engine.start(id, getHz(x, y-1))
      --print("grid > "..id.." "..note)
      engine.start(e.id, getHzET(note))
      start_screen_note(note)
      lit[e.id] = {}
      lit[e.id].x = e.x + trans.x - root.x
      lit[e.id].y = e.y + trans.y - root.y
      nvoices = nvoices + 1
    end
  else
    engine.stop(e.id)
    stop_screen_note(note)
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

function start_screen_note(note)
  if #screen_notes > 8 then return end
  
  local screen_note
  
  -- Get an existing screen_note if it exists
  local found = false;
  for key, val in pairs(screen_notes) do
    if val.note == note then
      screen_note = val
      screen_note.metro:start()
      found = true;
      break
    end
  end
  
  -- If not, add a new screen_note
  if not found then
    screen_note = {note = note, x = math.random(128), y = math.random(64), init_radius = math.random(8,18), ripples = {}, metro = metro.alloc() }
    screen_note.metro.time = 0.4
    screen_note.metro.callback = function(stage)
      local ripple = {radius = screen_note.init_radius, alpha = 1}
      table.insert(screen_note.ripples, ripple)
    end
    screen_note.metro:start()
    table.insert(screen_notes, screen_note)
  end
  
  -- Add a ripple
  local ripple = {radius = screen_note.init_radius, alpha = 1}
  table.insert(screen_note.ripples, ripple)
  
end

function stop_screen_note(note)
  for key, val in pairs(screen_notes) do
    if val.note == note then
      metro.free(val.metro.id)
      break
    end
  end
end

function stop_all_screen_notes()
  for key, val in pairs(screen_notes) do
    metro.free(val.metro.id)
  end
end

function redraw()
  screen.clear()
  screen.aa(0)
  screen.line_width(1)
  
  for n_key, n_val in pairs(screen_notes) do
    for r_key, r_val in pairs(n_val.ripples) do
      screen.level(math.max(1,math.floor(r_val.alpha * 15 + 0.5)))
      screen.circle(n_val.x, n_val.y, r_val.radius)
      screen.stroke()
      
      r_val.radius = r_val.radius + ripple_growth_rate
      r_val.alpha = r_val.alpha - ripple_fade_rate
      
      if r_val.alpha <= 0 then
        n_val.ripples[r_key] = nil
      end
    end
    if #n_val.ripples == 0 and not n_val.metro.is_running then
      screen_notes[n_key] = nil
    end
  end
  
  screen.update()
end

local function note_on(note, vel)
  if nvoices < 6 then
    --engine.start(id, getHz(x, y-1))
    engine.start(note, getHzET(note))
    start_screen_note(note)
    nvoices = nvoices + 1
  end
end

local function note_off(note, vel)
  engine.stop(note)
  stop_screen_note(note)
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
  stop_all_screen_notes()
  pat:stop()
  pat = nil
  for id,dev in pairs(midi.devices) do
    dev.event = nil
  end
end
