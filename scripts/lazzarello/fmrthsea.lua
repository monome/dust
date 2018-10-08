-- fmrthsea
--
-- FM polysynth
-- controlled by grid or MIDI
--
-- grid pattern player:
-- 1 1 record toggle
-- 1 2 play toggle
-- 1 8 transpose mode
-- 1 3-7 toggle encoders into modulation modes
-- enc 1: frequency
-- enc 2: phase
-- enc 3: amplitude

local tab = require 'tabutil'
local pattern_time = require 'pattern_time'

local g = grid.connect()

local mode_transpose = 0
local root = { x=5, y=5 }
local trans = { x=5, y=5 }
local lit = {}
local encoder_mode = 1

local screen_framerate = 15
local screen_refresh_metro

local ripple_repeat_rate = 1 / 0.3 / screen_framerate
local ripple_decay_rate = 1 / 0.5 / screen_framerate
local ripple_growth_rate = 1 / 0.02 / screen_framerate
local screen_notes = {}

local MAX_NUM_VOICES = 16

engine.name = 'FM7'

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

local function getEncoderMode()
  return encoder_mode
end

local function setEncoderMode(mode)
  encoder_mode = mode
end


local ctrl_functions = {
  function(arg) engine.hz1(arg) end,
  function(arg) engine.hz2(arg) end,
  function(arg) engine.hz3(arg) end,
  function(arg) engine.hz4(arg) end,
  function(arg) engine.hz5(arg) end,
  function(arg) engine.hz6(arg) end,
  function(arg) engine.phase1(arg) end,
  function(arg) engine.phase2(arg) end,
  function(arg) engine.phase3(arg) end,
  function(arg) engine.phase4(arg) end,
  function(arg) engine.phase5(arg) end,
  function(arg) engine.phase6(arg) end,
  function(arg) engine.amp1(arg) end,
  function(arg) engine.amp2(arg) end,
  function(arg) engine.amp3(arg) end,
  function(arg) engine.amp4(arg) end,
  function(arg) engine.amp5(arg) end,
  function(arg) engine.amp6(arg) end,
}

function init()
  pat = pattern_time.new()
  pat.process = grid_note_trans

  params:add_control("ampAtk","ampAtk", controlspec.new(0.01,10,"lin",0,0.05,""))
  params:set_action("ampAtk", function(x) engine.ampAtk(x) end)

  params:add_control("ampDec","ampDec", controlspec.new(0,2,"lin",0,0.1,""))
  params:set_action("ampDec", function(x) engine.ampDec(x) end)

  params:add_control("ampSus","ampSus", controlspec.new(0,1,"lin",0,1,""))
  params:set_action("ampSus", function(x) engine.ampSus(x) end)

  params:add_control("ampRel","ampRel", controlspec.new(0.01,10,"lin",0,1,""))
  params:set_action("ampRel", function(x) engine.ampRel(x) end)

  params:add_control("hz1", "Osc 1 Frequency Multiplier", controlspec.new(0,5, "lin",0,1,""))
  params:set_action("hz1", function(x) engine.hz1(x) end)
  params:add_control("hz2", "Osc 2 Frequency Multiplier", controlspec.new(0,5, "lin",0,1,""))
  params:set_action("hz2", function(x) engine.hz2(x) end)
  params:add_control("hz3", "Osc 3 Frequency Multiplier", controlspec.new(0,5, "lin",0,1,""))
  params:set_action("hz3", function(x) engine.hz3(x) end)
  params:add_control("hz4", "Osc 4 Frequency Multiplier", controlspec.new(0,5, "lin",0,1,""))
  params:set_action("hz4", function(x) engine.hz4(x) end)
  params:add_control("hz5", "Osc 5 Frequency Multiplier", controlspec.new(0,5, "lin",0,1,""))
  params:set_action("hz5", function(x) engine.hz5(x) end)
  params:add_control("hz6", "Osc 6 Frequency Multiplier", controlspec.new(0,5, "lin",0,1,""))
  params:set_action("hz6", function(x) engine.hz6(x) end)

  params:add_control("phase1", "Osc 1 phase", controlspec.new(0,3, "lin",0,0,""))
  params:set_action("phase1", function(x) engine.phase1(x) end)
  params:add_control("phase2", "Osc 2 phase", controlspec.new(0,3, "lin",0,0,""))
  params:set_action("phase2", function(x) engine.phase2(x) end)
  params:add_control("phase3", "Osc 3 phase", controlspec.new(0,3, "lin",0,0,""))
  params:set_action("phase3", function(x) engine.phase3(x) end)
  params:add_control("phase4", "Osc 4 phase", controlspec.new(0,3, "lin",0,0,""))
  params:set_action("phase4", function(x) engine.phase4(x) end)
  params:add_control("phase5", "Osc 5 phase", controlspec.new(0,3, "lin",0,0,""))
  params:set_action("phase5", function(x) engine.phase5(x) end)
  params:add_control("phase6", "Osc 6 phase", controlspec.new(0,3, "lin",0,0,""))
  params:set_action("phase6", function(x) engine.phase6(x) end)

  params:add_control("amp1", "Osc 1 amplitude", controlspec.new(0,1, "exp",0,1,""))
  params:set_action("amp1", function(x) engine.amp1(x) end)
  params:add_control("amp2", "Osc 2 amplitude", controlspec.new(0,1, "exp",0,1,""))
  params:set_action("amp2", function(x) engine.amp2(x) end)
  params:add_control("amp3", "Osc 3 amplitude", controlspec.new(0,1, "exp",0,1,""))
  params:set_action("amp3", function(x) engine.amp3(x) end)
  params:add_control("amp4", "Osc 4 amplitude", controlspec.new(0,1, "exp",0,1,""))
  params:set_action("amp4", function(x) engine.amp4(x) end)
  params:add_control("amp5", "Osc 5 amplitude", controlspec.new(0,1, "exp",0,1,""))
  params:set_action("amp5", function(x) engine.amp5(x) end)
  params:add_control("amp6", "Osc 6 amplitude", controlspec.new(0,1, "exp",0,1,""))
  params:set_action("amp6", function(x) engine.amp6(x) end)

  params:add_control("hz1_to_hz1","Osc1 phase mod Osc1", controlspec.new(0,3,"lin",0,1,""))  
  params:set_action("hz1_to_hz1", function(x) engine.hz1_to_hz1(x) end)

  params:add_control("hz1_to_hz2","Osc1 phase mod Osc2", controlspec.new(0,3,"lin",0,1,""))  
  params:set_action("hz1_to_hz2", function(x) engine.hz1_to_hz2(x) end)

  params:add_control("hz1_to_hz3","Osc1 phase mod Osc3", controlspec.new(0,3,"lin",0,1,""))  
  params:set_action("hz1_to_hz3", function(x) engine.hz1_to_hz3(x) end)

  params:add_control("hz1_to_hz4","Osc1 phase mod Osc4", controlspec.new(0,3,"lin",0,1,""))  
  params:set_action("hz1_to_hz4", function(x) engine.hz1_to_hz4(x) end)

  params:add_control("hz1_to_hz5","Osc1 phase mod Osc5", controlspec.new(0,3,"lin",0,1,""))  
  params:set_action("hz1_to_hz5", function(x) engine.hz1_to_hz5(x) end)

  params:add_control("hz1_to_hz6","Osc1 phase mod Osc6", controlspec.new(0,3,"lin",0,1,""))  
  params:set_action("hz1_to_hz6", function(x) engine.hz1_to_hz6(x) end)

  params:add_control("hz2_to_hz1","Osc2 phase mod Osc1", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz2_to_hz1", function(x) engine.hz2_to_hz1(x) end)

  params:add_control("hz2_to_hz2","Osc2 phase mod Osc2", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz2_to_hz2", function(x) engine.hz2_to_hz2(x) end)

  params:add_control("hz2_to_hz3","Osc2 phase mod Osc3", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz2_to_hz3", function(x) engine.hz2_to_hz3(x) end)

  params:add_control("hz2_to_hz4","Osc2 phase mod Osc4", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz2_to_hz4", function(x) engine.hz2_to_hz4(x) end)

  params:add_control("hz2_to_hz5","Osc2 phase mod Osc5", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz2_to_hz5", function(x) engine.hz2_to_hz5(x) end)

  params:add_control("hz2_to_hz6","Osc2 phase mod Osc6", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz1_to_hz6", function(x) engine.hz2_to_hz6(x) end)

  params:add_control("hz3_to_hz1","Osc3 phase mod Osc1", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz3_to_hz1", function(x) engine.hz3_to_hz1(x) end)

  params:add_control("hz3_to_hz2","Osc3 phase mod Osc2", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz3_to_hz2", function(x) engine.hz3_to_hz2(x) end)

  params:add_control("hz3_to_hz3","Osc3 phase mod Osc3", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz3_to_hz3", function(x) engine.hz3_to_hz3(x) end)

  params:add_control("hz3_to_hz4","Osc3 phase mod Osc4", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz3_to_hz4", function(x) engine.hz3_to_hz4(x) end)

  params:add_control("hz3_to_hz5","Osc3 phase mod Osc5", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz3_to_hz5", function(x) engine.hz3_to_hz5(x) end)

  params:add_control("hz3_to_hz6","Osc3 phase mod Osc6", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz3_to_hz6", function(x) engine.hz3_to_hz6(x) end)

  params:add_control("hz4_to_hz1","Osc4 phase mod Osc1", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz4_to_hz1", function(x) engine.hz4_to_hz1(x) end)

  params:add_control("hz4_to_hz2","Osc4 phase mod Osc2", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz4_to_hz2", function(x) engine.hz4_to_hz2(x) end)

  params:add_control("hz4_to_hz3","Osc4 phase mod Osc3", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz4_to_hz3", function(x) engine.hz4_to_hz3(x) end)

  params:add_control("hz4_to_hz4","Osc4 phase mod Osc4", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz4_to_hz4", function(x) engine.hz4_to_hz4(x) end)

  params:add_control("hz4_to_hz5","Osc4 phase mod Osc5", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz4_to_hz5", function(x) engine.hz4_to_hz5(x) end)

  params:add_control("hz4_to_hz6","Osc4 phase mod Osc6", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz4_to_hz6", function(x) engine.hz4_to_hz6(x) end)

  params:add_control("hz5_to_hz1","Osc5 phase mod Osc1", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz5_to_hz1", function(x) engine.hz5_to_hz1(x) end)

  params:add_control("hz5_to_hz2","Osc5 phase mod Osc2", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz5_to_hz2", function(x) engine.hz5_to_hz2(x) end)

  params:add_control("hz5_to_hz3","Osc5 phase mod Osc3", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz5_to_hz3", function(x) engine.hz5_to_hz3(x) end)

  params:add_control("hz5_to_hz4","Osc5 phase mod Osc4", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz5_to_hz4", function(x) engine.hz5_to_hz4(x) end)

  params:add_control("hz5_to_hz5","Osc5 phase mod Osc5", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz5_to_hz5", function(x) engine.hz5_to_hz5(x) end)

  params:add_control("hz5_to_hz6","Osc5 phase mod Osc6", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz5_to_hz6", function(x) engine.hz5_to_hz6(x) end)

  params:add_control("hz6_to_hz1","Osc6 phase mod Osc1", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz6_to_hz1", function(x) engine.hz6_to_hz1(x) end)

  params:add_control("hz6_to_hz2","Osc6 phase mod Osc2", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz6_to_hz2", function(x) engine.hz6_to_hz2(x) end)

  params:add_control("hz6_to_hz3","Osc6 phase mod Osc3", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz6_to_hz3", function(x) engine.hz6_to_hz3(x) end)

  params:add_control("hz6_to_hz4","Osc6 phase mod Osc4", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz6_to_hz4", function(x) engine.hz6_to_hz4(x) end)

  params:add_control("hz6_to_hz5","Osc6 phase mod Osc5", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz6_to_hz5", function(x) engine.hz6_to_hz5(x) end)

  params:add_control("hz6_to_hz6","Osc6 phase mod Osc6", controlspec.new(0,3,"lin",0,0,""))  
  params:set_action("hz6_to_hz6", function(x) engine.hz6_to_hz6(x) end)

  engine.amp(0.05)
  engine.stopAll()
  stop_all_screen_notes()

  --params:read("tehn/earthsea.pset")

  params:bang()

  if g then gridredraw() end

  screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function(stage)
    update()
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
  ph_position,hz_position,amp_position = 0,0,0
end

function enc(n,delta)
  if n == 1 then
    hz_position = (hz_position + delta) % 1024
    local hz = (hz_position / 1024) * 5
    local mode = getEncoderMode()
    ctrl_functions[mode](hz)
    print("hz" .. mode .. " multiple is " .. hz)
  elseif n == 2 then
    ph_position = (ph_position + delta) % 1024
    local phase = (ph_position / 1024)
    local mode = getEncoderMode()
    ctrl_functions[mode + 6](phase)
    print("phase" .. mode .. " is " .. phase)
  elseif n == 3 then
    amp_position = (amp_position + delta) % 1024
    local amp = (amp_position / 1024)
    local mode = getEncoderMode()
    ctrl_functions[mode + 6*2](amp)
    print("amp" .. mode .. " is " .. amp)
  end
end

function g.event(x, y, z)
  if x == 1 and (y > 2 and y < 8) then
    if z == 1 and getEncoderMode() == y - 1 then
      setEncoderMode(1)
    elseif z == 1 then
      setEncoderMode(y - 1) 
    end
  end

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
    if nvoices < MAX_NUM_VOICES then
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
    if lit[e.id] ~= nil then
      engine.stop(e.id)
      stop_screen_note(note)
      lit[e.id] = nil
      nvoices = nvoices - 1
    end
  end
  gridredraw()
end

function grid_note_trans(e)
  local note = ((7-e.y+(root.y-trans.y))*5) + e.x + (trans.x-root.x)
  if e.state > 0 then
    if nvoices < MAX_NUM_VOICES then
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

local function toggleModLED(mode)
  if mode ~= 1 then
    g.led(1,mode + 1,12)
  end
end

function gridredraw()
  g.all(0)
  g.led(1,1,2 + pat.rec * 10)
  g.led(1,2,2 + pat.play * 10)
  g.led(1,8,2 + mode_transpose * 10)
  toggleModLED(getEncoderMode())

  if mode_transpose == 1 then g.led(trans.x, trans.y, 4) end
  for i,e in pairs(lit) do
    g.led(e.x, e.y,15)
  end

  g:refresh()
end

function key(n,z)
end

function start_screen_note(note)
  local screen_note = nil

  -- Get an existing screen_note if it exists
  local count = 0
  for key, val in pairs(screen_notes) do
    if val.note == note then
      screen_note = val
      break
    end
    count = count + 1
    if count > 8 then return end
  end

  if screen_note then
    screen_note.active = true
  else
    screen_note = {note = note, active = true, repeat_timer = 0, x = math.random(128), y = math.random(64), init_radius = math.random(6,18), ripples = {} }
    table.insert(screen_notes, screen_note)
  end

  add_ripple(screen_note)

end

function stop_screen_note(note)
  for key, val in pairs(screen_notes) do
    if val.note == note then
      val.active = false
      break
    end
  end
end

function stop_all_screen_notes()
  for key, val in pairs(screen_notes) do
    val.active = false
  end
end

function add_ripple(screen_note)
  if tab.count(screen_note.ripples) < 6 then
    local ripple = {radius = screen_note.init_radius, life = 1}
    table.insert(screen_note.ripples, ripple)
  end
end

function update()
  for n_key, n_val in pairs(screen_notes) do

    if n_val.active then
      n_val.repeat_timer = n_val.repeat_timer + ripple_repeat_rate
      if n_val.repeat_timer >= 1 then
        add_ripple(n_val)
        n_val.repeat_timer = 0
      end
    end

    local r_count = 0
    for r_key, r_val in pairs(n_val.ripples) do
      r_val.radius = r_val.radius + ripple_growth_rate
      r_val.life = r_val.life - ripple_decay_rate

      if r_val.life <= 0 then
        n_val.ripples[r_key] = nil
      else
        r_count = r_count + 1
      end
    end

    if r_count == 0 and not n_val.active then
      screen_notes[n_key] = nil
    end
  end
end

function redraw()
  screen.clear()
  screen.aa(0)
  screen.line_width(1)

  local first_ripple = true
  for n_key, n_val in pairs(screen_notes) do
    for r_key, r_val in pairs(n_val.ripples) do
      if first_ripple then -- Avoid extra line when returning from menu
        screen.move(n_val.x + r_val.radius, n_val.y)
        first_ripple = false
      end
      screen.level(math.max(1,math.floor(r_val.life * 15 + 0.5)))
      screen.circle(n_val.x, n_val.y, r_val.radius)
      screen.stroke()
    end
  end

  screen.update()
end

local function note_on(note, vel)
  if nvoices < MAX_NUM_VOICES then
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
    if data[3] == 0 then
      note_off(data[2])
    else
      note_on(data[2], data[3])
    end
  elseif data[1] == 128 then
    note_off(data[2])
  elseif data[1] == 176 then
    --cc(data1, data2)
  elseif data[1] == 224 then
    --bend(data1, data2)
  end
end

midi.add = function(dev)
  print('earthsea: midi device added', dev.id, dev.name)
  dev.event = midi_event
end

function cleanup()
  stop_all_screen_notes()
  pat:stop()
  pat = nil
end
