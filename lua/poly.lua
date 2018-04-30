-- subtractive polysynth
-- controlled by midi or grid
-- knob 2 selects param
-- knob 3 changes selected param

local tab = require 'tabutil'

engine.name = 'PolySub'

-- pythagorean minor/major, kinda
local ratios = { 1, 9/8, 6/5, 5/4, 4/3, 3/2, 27/16, 16/9 }
local base = 27.5 -- low A

local getHz = function ( deg, oct )
  return base * ratios[deg] * (2^oct)
end

local getHzET = function ( note )
  return 55*2^(note/12)
end

-- table of param values indexed by name
local params = {
  shape = 0.0,
  timbre = 0.5,
  noise =  0.0,
  cut = 8.0,
  ampAtk = 0.05,
  ampDec = 0.1,
  ampSus = 1.0, ampRel = 1.0, ampCurve =  -1.0,
  cutAtk = 0.0, cutDec = 0.0, cutSus = 1.0, cutRel = 1.0,
  cutCurve =  -1.0, cutEnvAmt = 0.0,
  fgain = 0.0,
  detune = 0,
  delTime = 0.2, delMix = 0.0, delFb = 0.0,
  delSpread = 0.0,
  width = 0.5,
  thresh = 0.6,
  atk = 0.01,
  rel = 0.1,
  slope = 8.0,
  compMix = 1.0,
  room=0.5,
  damp=0.0,
  verbMix=0.0
}

-- FIXME: i guess we need to set up some range / scaling / warping descriptor system. arg!
local param_ranges = {
  shape = {0, 1 },
  timbre = {0, 1 },
  noise =  {0, 1 },
  cut = { 1.0, 32.0 },
  ampAtk = { 0.01, 8.0 },
  ampDec = { 0.0, 2.0 },
  ampSus = { 0.0, 1.0 },
  ampRel = { 0.01, 10.0 },
  ampCurve =  {-1.0, },

  --- not sure about filter env working...
  cutAtk = { 0.0, 1.0 },
  cutDec = {0.0, 1.0 },
  cutSus = {0.0, 1.0, },
  cutRel = {0.0, 1.0 },
  cutCurve = { -4.0, 4.0 },
  cutEnvAmt = {0.0, 1.0 },

  fgain = { 0.0, 4.0 },
  detune = { 0.0, 2.0 },
  delTime = { 0.0, 0.8 },
  delMix = { 0.0, 1.0 },
  delFb = { 0.0, 0.9 },
  delSpread = { 0.0, 0.4 },
  width = { 0.0, 1.0 },
  thresh = { 0.2, 1.0 },
  atk = { 0.0, 0.5 },
  rel = { 0.0, 0.5 },
  slope = { 1.0, 24.0 },
  compMix = { 0.0, 1.0 },
  room= { 0.0, 1.0 },
  damp= { 0.0, 1.0 },
  verbMix= { 0.0, 1.0 },
}

local param_names = tab.sort(params)

-- current selected parameter
local cur_param_id = 1

-- current count of active voices
local nvoices = 0

local incParam = function(name, delta)
  print("inc " .. name .. " " .. delta)
  local val = params[name] + delta
  if val < param_ranges[name][1] then val = param_ranges[name][1] end
  if val > param_ranges[name][2] then val = param_ranges[name][2] end
  params[name] = val
  engine[name](val)
end

init = function()
  if g ~= nil then
    g:all(1)
    g:refresh()
  end
  engine.level(0.05)
  engine.stopAll()
  print("grid/poly")
end

gridkey = function(x, y, state)
  --- FIXME: implement voice stealing?
  --if x < 9 and y < 8 then
  local id = x*8 + y
  local note = ((7-y)*5) + x
  if state > 0 then
    if nvoices < 6 then
     --engine.start(id, getHz(x, y-1))
     print("grid > "..id.." "..note)
     engine.start(id, getHzET(note))
      g:led(x, y, 10)
     nvoices = nvoices + 1
    end
  else
    engine.stop(id)
    g:led(x, y, 0)
    nvoices = nvoices - 1
  end
  g:refresh()
  --end
end

enc = function(n,delta)
  if n==2 then
    cur_param_id = util.clamp(cur_param_id + delta,1,tab.count(params))
  elseif n==3 then
    incParam(param_names[cur_param_id], delta * 0.01)
  end
   redraw()
end

key = function(n,z)
--[[
   if n==2 then
     -- TODO: randomize params or something
   elseif n == 3
     -- TODO: try solo mode or something
   end
   --]]
end

redraw = function()
   screen.clear()
   screen.line_width(1)
   screen.level(15)
   screen.move(0,10)
   screen.text(param_names[cur_param_id] .. " = " .. params[param_names[cur_param_id]])

   screen.update()
end



cleanup = function()
  -- nothing to do
end

norns.midi.event = function(id, data)
  tab.print(data)
  if data[1] == 144 then
    --[[
    if data1 == 0 then
    return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
    end
    ]]
    note_on(data[2], data[3])
  elseif data[1] == 128 then
    --[[
    if data1 == 0 then
    return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
    end
    ]]
    note_off(data[2])
  elseif status == 176 then
    --cc(data1, data2)
  elseif status == 224 then
    --bend(data1, data2)
  end
end

nvoices = 0

note_on = function(note, vel)
  if nvoices < 6 then
    --engine.start(id, getHz(x, y-1))
    engine.start(note, getHzET(note))
    nvoices = nvoices + 1
  end
end

note_off = function(note, vel)
  engine.stop(note)
  nvoices = nvoices - 1
end
