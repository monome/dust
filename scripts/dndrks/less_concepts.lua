-- hold key 1: start/stop seq.
-- enc 1: scale
-- (hold key 2) enc 2: seed
-- (hold key 2) enc 3: rule
--
-- press key 3: menu nav.
-- enc 2 + 3: change menu val.
-- params: midi, +/- st, timbre
--
-- plug in grid
-- (1,1) to (8,2): bits
-- (10,1) to (16,2): octaves
-- (1,3) to (16,3): randomize
-- (1,4) to (16,5): low
-- (1,6) to (16,7): high
-- (16,8): take snapshot
-- (15,8): clear snapshots
-- (1,8) to (8,8): snapshots
--
-- seek.
-- think.
-- discover.


local seed = 0
local rule = 0
local next_seed = nil
local new_low = 1
local new_high = 14
local coll = 1
local new_seed = seed
local new_rule = rule
local automatic = 0
local KEY2 = false
local KEY3 = false
local KEY3_toggle = 0
local v1_bit = 0
local v2_bit = 0
local v1_octave = 0
local v2_octave = 0
local ch_1 = 1
local ch_2 = 1
local semi = 0
local presets = {}
local preset_count = 0
local active_notes_v1 = {}
local active_notes_v2 = {}

beatclock = require 'beatclock'
clk = beatclock.new()
clk_midi = midi.connect()
clk_midi.event = clk.process_midi

engine.name = "Passersby"
passersby = require "mark_eats/passersby"

-- this section is all maths + computational events

-- maths: translate the seed integer to binary
function seed_to_binary()
  seed_as_binary = {}
  for i = 0,7 do
    table.insert(seed_as_binary, (seed & (2 ^ i)) >> i)
  end
end

-- maths: translate the rule integer to binary
function rule_to_binary()
  rule_as_binary = {}
  for i = 0,7 do
    table.insert(rule_as_binary, (rule & (2 ^ i)) >> i)
  end
end

-- maths: basic compare function, used in bang()
function compare (s, n)
  if type(s) == type(n) then
        if type(s) == "table" then
                  for loop=1, 3 do
                    if compare (s[loop], n[loop]) == false then
                        return false
                    end
                  end

                return true
        else
            return s == n
        end
    end
    return false
end

-- maths: scale seeds to the note pool + range selected
function scale(lo, hi, received)
  scaled = math.floor(((((received-1) / (256-1)) * (hi - lo) + lo)))
end

-- pack the seeds into clusters, compare these against neighborhoods to determine gates in iterate()
function bang()
  redraw()
  seed_to_binary()
  rule_to_binary()
  seed_pack1 = {seed_as_binary[1], seed_as_binary[8], seed_as_binary[7]}
  seed_pack2 = {seed_as_binary[8], seed_as_binary[7], seed_as_binary[6]}
  seed_pack3 = {seed_as_binary[7], seed_as_binary[6], seed_as_binary[5]}
  seed_pack4 = {seed_as_binary[6], seed_as_binary[5], seed_as_binary[4]}
  seed_pack5 = {seed_as_binary[5], seed_as_binary[4], seed_as_binary[3]}
  seed_pack6 = {seed_as_binary[4], seed_as_binary[3], seed_as_binary[2]}
  seed_pack7 = {seed_as_binary[3], seed_as_binary[2], seed_as_binary[1]}
  seed_pack8 = {seed_as_binary[2], seed_as_binary[1], seed_as_binary[8]}

neighborhoods1 = {1,1,1}
neighborhoods2 = {1,1,0}
neighborhoods3 = {1,0,1}
neighborhoods4 = {1,0,0}
neighborhoods5 = {0,1,1}
neighborhoods6 = {0,1,0}
neighborhoods7 = {0,0,1}
neighborhoods8 = {0,0,0}

function com1()
if compare (seed_pack1,neighborhoods1) then
    out1 = (rule_as_binary[8] << 7) & 128
  elseif compare (seed_pack1, neighborhoods2) then
    out1 = (rule_as_binary[7] << 7) & 128
  elseif compare (seed_pack1, neighborhoods3) then
    out1 = (rule_as_binary[6] << 7) & 128
  elseif compare (seed_pack1, neighborhoods4) then
    out1 = (rule_as_binary[5] << 7) & 128
  elseif compare (seed_pack1, neighborhoods5) then
    out1 = (rule_as_binary[4] << 7) & 128
  elseif compare (seed_pack1, neighborhoods6) then
    out1 = (rule_as_binary[3] << 7) & 128
  elseif compare (seed_pack1, neighborhoods7) then
    out1 = (rule_as_binary[2] << 7) & 128
  elseif compare (seed_pack1, neighborhoods8) then
    out1 = (rule_as_binary[1] << 7) & 128
  else out1 = (0 << 7) & 128
  end
end

function com2()
if compare (seed_pack2,neighborhoods1) then
    out2 = (rule_as_binary[8] << 6) & 64
  elseif compare (seed_pack2, neighborhoods2) then
    out2 = (rule_as_binary[7] << 6) & 64
  elseif compare (seed_pack2, neighborhoods3) then
    out2 = (rule_as_binary[6] << 6) & 64
  elseif compare (seed_pack2, neighborhoods4) then
    out2 = (rule_as_binary[5] << 6) & 64
  elseif compare (seed_pack2, neighborhoods5) then
    out2 = (rule_as_binary[4] << 6) & 64
  elseif compare (seed_pack2, neighborhoods6) then
    out2 = (rule_as_binary[3] << 6) & 64
  elseif compare (seed_pack2, neighborhoods7) then
    out2 = (rule_as_binary[2] << 6) & 64
  elseif compare (seed_pack2, neighborhoods8) then
    out2 = (rule_as_binary[1] << 6) & 64
  else out2 = (0 << 6) & 64
  end
end

function com3()
if compare (seed_pack3,neighborhoods1) then
    out3 = (rule_as_binary[8] << 5) & 32
  elseif compare (seed_pack3, neighborhoods2) then
    out3 = (rule_as_binary[7] << 5) & 32
  elseif compare (seed_pack3, neighborhoods3) then
    out3 = (rule_as_binary[6] << 5) & 32
  elseif compare (seed_pack3, neighborhoods4) then
    out3 = (rule_as_binary[5] << 5) & 32
  elseif compare (seed_pack3, neighborhoods5) then
    out3 = (rule_as_binary[4] << 5) & 32
  elseif compare (seed_pack3, neighborhoods6) then
    out3 = (rule_as_binary[3] << 5) & 32
  elseif compare (seed_pack3, neighborhoods7) then
    out3 = (rule_as_binary[2] << 5) & 32
  elseif compare (seed_pack3, neighborhoods8) then
    out3 = (rule_as_binary[1] << 5) & 32
  else out3 = (0 << 5) & 32
  end
end

function com4()
if compare (seed_pack4,neighborhoods1) then
    out4 = (rule_as_binary[8] << 4) & 16
  elseif compare (seed_pack4, neighborhoods2) then
    out4 = (rule_as_binary[7] << 4) & 16
  elseif compare (seed_pack4, neighborhoods3) then
    out4 = (rule_as_binary[6] << 4) & 16
  elseif compare (seed_pack4, neighborhoods4) then
    out4 = (rule_as_binary[5] << 4) & 16
  elseif compare (seed_pack4, neighborhoods5) then
    out4 = (rule_as_binary[4] << 4) & 16
  elseif compare (seed_pack4, neighborhoods6) then
    out4 = (rule_as_binary[3] << 4) & 16
  elseif compare (seed_pack4, neighborhoods7) then
    out4 = (rule_as_binary[2] << 4) & 16
  elseif compare (seed_pack4, neighborhoods8) then
    out4 = (rule_as_binary[1] << 4) & 16
  else out4 = (0 << 4) & 16
  end
end

function com5()
if compare (seed_pack5,neighborhoods1) then
    out5 = (rule_as_binary[8] << 3) & 8
  elseif compare (seed_pack5, neighborhoods2) then
    out5 = (rule_as_binary[7] << 3) & 8
  elseif compare (seed_pack5, neighborhoods3) then
    out5 = (rule_as_binary[6] << 3) & 8
  elseif compare (seed_pack5, neighborhoods4) then
    out5 = (rule_as_binary[5] << 3) & 8
  elseif compare (seed_pack5, neighborhoods5) then
    out5 = (rule_as_binary[4] << 3) & 8
  elseif compare (seed_pack5, neighborhoods6) then
    out5 = (rule_as_binary[3] << 3) & 8
  elseif compare (seed_pack5, neighborhoods7) then
    out5 = (rule_as_binary[2] << 3) & 8
  elseif compare (seed_pack5, neighborhoods8) then
    out5 = (rule_as_binary[1] << 3) & 8
  else out5 = (0 << 3) & 8
  end
end

function com6()
if compare (seed_pack6,neighborhoods1) then
    out6 = (rule_as_binary[8] << 2) & 4
  elseif compare (seed_pack6, neighborhoods2) then
    out6 = (rule_as_binary[7] << 2) & 4
  elseif compare (seed_pack6, neighborhoods3) then
    out6 = (rule_as_binary[6] << 2) & 4
  elseif compare (seed_pack6, neighborhoods4) then
    out6 = (rule_as_binary[5] << 2) & 4
  elseif compare (seed_pack6, neighborhoods5) then
    out6 = (rule_as_binary[4] << 2) & 4
  elseif compare (seed_pack6, neighborhoods6) then
    out6 = (rule_as_binary[3] << 2) & 4
  elseif compare (seed_pack6, neighborhoods7) then
    out6 = (rule_as_binary[2] << 2) & 4
  elseif compare (seed_pack6, neighborhoods8) then
    out6 = (rule_as_binary[1] << 2) & 4
  else out6 = (0 << 2) & 4
  end
end

function com7()
if compare (seed_pack7,neighborhoods1) then
    out7 = (rule_as_binary[8] << 1) & 2
  elseif compare (seed_pack7, neighborhoods2) then
    out7 = (rule_as_binary[7] << 1) & 2
  elseif compare (seed_pack7, neighborhoods3) then
    out7 = (rule_as_binary[6] << 1) & 2
  elseif compare (seed_pack7, neighborhoods4) then
    out7 = (rule_as_binary[5] << 1) & 2
  elseif compare (seed_pack7, neighborhoods5) then
    out7 = (rule_as_binary[4] << 1) & 2
  elseif compare (seed_pack7, neighborhoods6) then
    out7 = (rule_as_binary[3] << 1) & 2
  elseif compare (seed_pack7, neighborhoods7) then
    out7 = (rule_as_binary[2] << 1) & 2
  elseif compare (seed_pack7, neighborhoods8) then
    out7 = (rule_as_binary[1] << 1) & 2
  else out7 = (0 << 1) & 2
  end
end

function com8()
if compare (seed_pack8,neighborhoods1) then
    out8 = rule_as_binary[8] & 1
  elseif compare (seed_pack8, neighborhoods2) then
    out8 = rule_as_binary[7] & 1
  elseif compare (seed_pack8, neighborhoods3) then
    out8 = rule_as_binary[6] & 1
  elseif compare (seed_pack8, neighborhoods4) then
    out8 = rule_as_binary[5] & 1
  elseif compare (seed_pack8, neighborhoods5) then
    out8 = rule_as_binary[4] & 1
  elseif compare (seed_pack8, neighborhoods6) then
    out8 = rule_as_binary[3] & 1
  elseif compare (seed_pack8, neighborhoods7) then
    out8 = rule_as_binary[2] & 1
  elseif compare (seed_pack8, neighborhoods8) then
    out8 = rule_as_binary[1] & 1
  else out8 = 0 & 1
  end
end

com1()
com2()
com3()
com4()
com5()
com6()
com7()
com8()

next_seed = out1+out2+out3+out4+out5+out6+out7+out8

end

function notes_off_v1()
  for i=1,#active_notes_v1 do
    m.note_off(active_notes_v1[i],0,ch_1)
  end
  active_notes_v1 = {}
end

function notes_off_v2()
  for i=1,#active_notes_v2 do
    m.note_off(active_notes_v2[i],0,ch_2)
  end
  active_notes_v2 = {}
end

-- if user-defined bit in the binary version of a seed equals 1, then note event [aka, bit-wise gating]
function iterate()
  notes_off_v1()
  notes_off_v2()
  seed = next_seed
    bang()
    scale(new_low,new_high,seed)
    if seed_as_binary[v1_bit] == 1 then
      engine.noteOn(1,midi_to_hz((notes[coll][scaled])+(48+(v1_octave * 12)+semi)),127)
      m.note_on((notes[coll][scaled])+(36+(v1_octave*12)+semi),127,ch_1)
      table.insert(active_notes_v1,(notes[coll][scaled])+(36+(v1_octave*12)+semi))
    end
    if seed_as_binary[v2_bit] == 1 then
      engine.noteOn(2,midi_to_hz((notes[coll][scaled])+(48+(v2_octave * 12)+semi)),127)
      m.note_on((notes[coll][scaled])+(36+(v2_octave*12)+semi),127,ch_2)
      table.insert(active_notes_v2,(notes[coll][scaled])+(36+(v2_octave*12)+semi))
    end
    redraw()
    grid_redraw()
end

-- convert midi note to hz for Passersby engine
function midi_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end

-- allow user to define the MIDI channel voice 1 sends on
function midi_vox_1(channel)
  ch_1 = channel
end

-- allow user to define the MIDI channel voice 2 sends on
function midi_vox_2(channel)
  ch_2 = channel
end

-- allow user to define the transposition of voice 1 and voice 2, simultaneous changes to MIDI and Passersby engine
function transpose(semitone)
  semi = semitone
end

-- everything that happens when the script is first loaded
function init()
  math.randomseed(os.time())
  math.random(); math.random(); math.random()
  seed_to_binary()
  rule_to_binary()
  g = grid.connect()
  g.led(new_low,4,15)
  g.led(new_high,6,15)
  g.led(v1_octave+13,1,15)
  g.led(v2_octave+13,2,15)
  grid_redraw()
  g.refresh()
  m = midi.connect()
  clk.on_step = function() iterate() end
  clk.on_select_internal = function() clk:start() end
  clk.on_select_external = function() print("external") end
  clk:add_clock_params()
  params:add_number("midi ch vox 1", "midi ch vox 1", 1,16,1)
  params:set_action("midi ch vox 1", function (x) midi_vox_1(x) end)
  params:add_number("midi ch vox 2", "midi ch vox 2", 1,16,1)
  params:set_action("midi ch vox 2", function (x) midi_vox_2(x) end)
  params:add_number("global transpose", "global transpose", -24,24,0)
  params:set_action("global transpose", function (x) transpose(x) end)
  params:add_separator()
  passersby.add_params()
  bang()

notes = { {0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48},
          {0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48},
          {0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48},
          {0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48},
          {0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48},
          {0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48},
          {0,3,5,7,10,12,15,17,19,22,24,27,29,31,34,36,39,41,43,46,48,51,53,55,58,60,63,65,67},
          {0,2,4,7,9,12,14,16,19,21,24,26,28,31,33,36,38,40,43,45,48,50,52,55,57,60,62,64,67},
          {0,2,5,7,10,12,14,17,19,22,24,26,29,31,34,36,38,41,43,46,48,50,53,55,58,60,62,65,67},
          {0,3,5,8,10,12,15,17,20,22,24,27,29,32,34,36,39,41,44,46,48,51,53,56,58,60,63,65,68},
          {0,2,5,7,9,12,14,17,19,21,24,26,29,31,33,36,38,41,43,45,48,50,53,55,57,60,62,65,67},
          {0,1,3,6,7,8,11,12,13,15,18,19,20,23,24,25,27,30,31,32,35,36,37,39,42,43,44,47,48},
          {0,1,4,6,7,8,11,12,13,16,18,19,20,23,24,25,28,30,31,32,35,36,37,40,42,43,44,47,48},
          {0,1,4,6,7,9,11,12,13,16,18,19,21,23,24,25,28,30,31,33,35,36,37,40,42,43,45,47,48},
          {0,1,4,5,7,8,11,12,13,16,17,19,20,23,24,25,28,29,31,32,35,36,37,40,41,43,44,47,48},
          {0,1,4,5,7,9,10,12,13,16,17,19,21,22,24,25,28,29,31,33,35,36,37,40,41,43,45,47,48},
          {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28} }

names = {"ionian","aeolian", "dorian", "phrygian", "lydian", "mixolydian", "major_pent", "minor_pent", "shang", "jiao", "zhi", "todi", "purvi", "marva", "bhairav", "ahirbhairav", "chromatic"}

clk:stop()

end

-- this section is all hardware stuff

-- hardware: key interaction
function key(n,z)
  if n == 1 and z == 1 then
    automatic = automatic + 1
    if automatic % 2 == 1 then
      clk:start()
    elseif automatic % 2 == 0 then
      clk:stop()
    end
  end
  if n == 2 and z == 1 then
    KEY2 = true
    bang()
    redraw()
  elseif n == 2 and z == 0 then
    KEY2 = false
    seed = new_seed
    rule = new_rule
    bang()
    redraw()
  end
  if n == 3 and z == 1 then
    KEY3 = true
    KEY3_toggle = KEY3_toggle + 1
    bang()
    redraw()
  elseif n == 3 and z == 0 then
    KEY3 = false
    bang()
    redraw()
  end
end

-- hardware: encoder interaction
function enc(n,d)
  if n == 1 and KEY3 == false and KEY2 == false then
    coll = math.min(17,(math.max(coll + d,1)))
  end
  if n == 2 and KEY3 == false and KEY2 == false and KEY3_toggle % 3 == 1 then
    new_low = math.min(29,(math.max(new_low + d,1)))
    for i=1,16 do
      g.led(i,4,0)
      g.led(i,5,0)
      if new_low < 17 then
        g.led(new_low,4,15)
      elseif new_low > 16 then
        g.led(new_low-16,5,15)
      end
      g.refresh()
    end
  elseif n == 2 and KEY3 == false and KEY2 == false and KEY3_toggle % 3 == 2 then
    v1_octave = math.min(3,(math.max(v1_octave + d,-3)))
    for i=10,16 do
      g.led(i,1,0)
      g.led(v1_octave+13,1,15)
      g.refresh()
    end
  elseif n == 2 and KEY2 == false and KEY3_toggle %3 == 0 then
    v1_bit = math.min(8,(math.max(v1_bit + d,0)))
  elseif n == 2 and KEY2 then
    new_seed = math.min(255,(math.max(new_seed + d,0)))
  end
  if n == 3 and KEY3 == false and KEY2 == false and KEY3_toggle % 3 == 1 then
    new_high = math.min(29,(math.max(new_high + d,1)))
    for i=1,16 do
      g.led(i,6,0)
      g.led(i,7,0)
      if new_high < 17 then
        g.led(new_high,6,15)
      elseif new_high > 16 then
        g.led(new_high-16,7,15)
      end
      g.refresh()
    end
  elseif n == 3 and KEY3 == false and KEY2 == false and KEY3_toggle % 3 == 2 then
    v2_octave = math.min(3,(math.max(v2_octave + d,-3)))
    for i=10,16 do
      g.led(i,2,0)
      g.led(v2_octave+13,2,15)
      g.refresh()
    end
  elseif n == 3 and KEY2 == false and KEY3_toggle %3 == 0 then
    v2_bit = math.min(8,(math.max(v2_bit + d,0)))
  elseif n == 3 and KEY2 then
    new_rule = math.min(255,(math.max(new_rule + d,0)))
  end
  redraw()
end

-- hardware: screen redraw
function redraw()
  screen.clear()
  screen.level(15)
  screen.move(0,10)
  screen.text("seed: "..new_seed.." // rule: "..new_rule)
  screen.move(0,20)
  if KEY3_toggle % 3 == 0 then
    screen.level(15)
    screen.text("vox 1 bit: "..v1_bit.." // vox 2 bit: "..v2_bit)
  elseif KEY3_toggle % 3 == 1 or 2 then
    screen.level(1)
    screen.text("vox 1 bit: "..v1_bit.." // vox 2 bit: "..v2_bit)
  end
  screen.move(0,30)
  if KEY3_toggle % 3 == 1 then
    screen.level(15)
    screen.text("low: "..new_low.." // high: "..new_high)
  elseif KEY3_toggle % 3 == 2 or 0 then
    screen.level(1)
    screen.text("low: "..new_low.." // high: "..new_high)
  end
  screen.move(0,40)
  if KEY3_toggle % 3 == 2 then
    screen.level(15)
    screen.text("vox 1 oct: "..v1_octave)
    screen.move(57,40)
    screen.text("// vox 2 oct: "..v2_octave)
  elseif KEY3_toggle % 3 == 0 or 1 then
    screen.level(1)
    screen.text("vox 1 oct: "..v1_octave)
    screen.move(57,40)
    screen.text("// vox 2 oct: "..v2_octave)
  end
  screen.level(15)
  screen.move(0,50)
  screen.text("scale: "..names[coll])
  screen.move(0,60)
  screen.text("current: "..seed)
  screen.move(60,60)
  screen.text("next: "..next_seed)
  screen.update()
end

-- hardware: grid connect
g = grid.connect()
-- hardware: grid event (eg 'what happens when a button is pressed')
g.event = function(x,y,z)
  if y == 1 and x < 9 then
    g.led(x,y,z*15)
    g.refresh()
    v1_bit = x
    bang()
    redraw()
  end
  if y == 1 and x > 9 and z == 1 then
    for i=10,16 do
      g.led(i,1,0)
    end
    g.led(x,y,z*15)
    v1_octave = x-13
    redraw()
    g.refresh()
  end
  if y == 2 and x < 9 then
    g.led(x,y,z*15)
    g.refresh()
    v2_bit = x
    bang()
    redraw()
  end
  if y == 2 and x > 9 and z == 1 then
    for i=10,16 do
      g.led(i,2,0)
    end
    g.led(x,y,z*15)
    v2_octave = x-13
    redraw()
    g.refresh()
  end
  if y == 4 and z == 1 then
    for i=1,16 do
      g.led(i,4,0)
      g.led(i,5,0)
    end
    g.led(x,y,z*15)
    new_low = x
    redraw()
    g.refresh()
  end
  if y == 5 and z == 1 then
    for i=1,16 do
      g.led(i,4,0)
      g.led(i,5,0)
    end
    g.led(x,y,z*15)
    new_low = x+16
    redraw()
    g.refresh()
  end
  if y == 6 and z == 1 then
    for i=1,16 do
      g.led(i,6,0)
      g.led(i,7,0)
    end
    g.led(x,y,z*15)
    new_high = x
    redraw()
    g.refresh()
  end
  if y == 7 and z == 1 then
    for i=1,16 do
      g.led(i,6,0)
      g.led(i,7,0)
    end
    g.led(x,y,z*15)
    new_high = x+16
    redraw()
    g.refresh()
  end
  if y == 3 and z == 1 then
    if x == 1 then
      seed = math.random(0,255)
      new_seed = seed
    elseif x == 2 then
      rule = math.random(0,255)
      new_rule = rule
    elseif x == 4 then
      v1_bit = math.random(0,8)
    elseif x == 5 then
      v2_bit = math.random(0,8)
    elseif x == 7 or x == 8 or x == 10 or x == 11 then
      if x == 7 then
        new_low = math.random(1,29)
      end
      if x == 8 then
        new_high = math.random(1,29)
      end
      if x == 10 then
        v1_octave = math.random(-2,2)
      end
      if x == 11 then
        v2_octave = math.random(-2,2)
      end
      g.all(0)
      g.led(v1_octave+13,1,15)
      g.led(v2_octave+13,2,15)
      if new_low < 17 then
        g.led(new_low,4,15)
      else
        g.led(new_low-16,5,15)
      end
      if new_high < 17 then
        g.led(new_high,6,15)
      else
        g.led(new_high-16,7,15)
      end
    elseif x == 10 then
      v1_octave = math.random(-2,2)
    elseif x == 11 then
      v2_octave = math.random(-2,2)
    elseif x == 16 then
      randomize_all()
    end
    bang()
    redraw()
    grid_redraw()
    g.refresh()
  end
  if y == 8 and z == 1 then
    if x < 9 then
      preset_unpack(x)
    elseif x == 15 then
      presets = {}
      preset_pool = {}
      preset_count = 0
      for i=1,8 do
        g.led(i,8,0)
      end
      grid_redraw()
    elseif x == 16 then
      preset_pack()
      if preset_count < 8 then
      preset_count = preset_count + 1
      grid_redraw()
      end
    end
  end
end

-- hardware: grid redraw
function grid_redraw()
  for i=1,8 do
    g.led(i,1,0)
    g.led(i,2,0)
  end
  if seed_as_binary[v1_bit] == 1 then
    g.led(v1_bit,1,15)
  end
  if seed_as_binary[v2_bit] == 1 then
    g.led(v2_bit,2,15)
  end
  g.led(1,3,4)
  g.led(2,3,4)
  g.led(4,3,4)
  g.led(5,3,4)
  g.led(7,3,4)
  g.led(8,3,4)
  g.led(10,3,4)
  g.led(11,3,4)
  g.led(16,3,4)
  for i=1,preset_count do
    g.led(i,8,6)
  end
  g.led(15,8,2)
  g.led(16,8,6)
  g.led(v1_octave+13,1,15)
  g.led(v2_octave+13,2,15)
  g.refresh()
end

-- this section is all performative stuff

-- randomize all maths paramaters (does not affect scale or engine, for ease of use)
function randomize_all()
  seed = math.random(0,255)
  new_seed = seed
  rule = math.random(0,255)
  new_rule = rule
  v1_bit = math.random(0,8)
  v2_bit = math.random(0,8)
  new_low = math.random(1,29)
  new_high = math.random(1,29)
  v1_octave = math.random(-2,2)
  v2_octave = math.random(-2,2)
  bang()
  redraw()
  g.all(0)
  g.led(v1_octave+13,1,15)
  g.led(v2_octave+13,2,15)
  if new_low < 17 then
    g.led(new_low,4,15)
  elseif new_low > 16 then
    g.led(new_low-16,5,15)
  end
  if new_high < 17 then
    g.led(new_high,6,15)
  elseif new_high > 16 then
    g.led(new_high-16,7,15)
  end
  grid_redraw()
  g.refresh()
end

-- pack all maths parameters into a volatile preset
function preset_pack()
  table.insert(presets, new_seed)
  table.insert(presets, new_rule)
  table.insert(presets, v1_bit)
  table.insert(presets, v2_bit)
  table.insert(presets, new_low)
  table.insert(presets, new_high)
  table.insert(presets, v1_octave)
  table.insert(presets, v2_octave)
  preset_pool = { {presets[1],presets[2],presets[3],presets[4],presets[5],presets[6],presets[7],presets[8]},
                  {presets[9],presets[10],presets[11],presets[12],presets[13],presets[14],presets[15],presets[16]},
                  {presets[17],presets[18],presets[19],presets[20],presets[21],presets[22],presets[23],presets[24]},
                  {presets[25],presets[26],presets[27],presets[28],presets[29],presets[30],presets[31],presets[32]},
                  {presets[33],presets[34],presets[35],presets[36],presets[37],presets[38],presets[39],presets[40]},
                  {presets[41],presets[42],presets[43],presets[44],presets[45],presets[46],presets[47],presets[48]},
                  {presets[49],presets[50],presets[51],presets[52],presets[53],presets[54],presets[55],presets[56]},
                  {presets[57],presets[58],presets[59],presets[60],presets[61],presets[62],presets[63],presets[64]} }
end

-- switch all current maths parameters to a volatile preset
function preset_unpack(set)
  seed = preset_pool[set][1]
  new_seed = seed
  rule = preset_pool[set][2]
  new_rule = rule
  v1_bit = preset_pool[set][3]
  v2_bit = preset_pool[set][4]
  new_low = preset_pool[set][5]
  new_high = preset_pool[set][6]
  v1_octave = preset_pool[set][7]
  v2_octave = preset_pool[set][8]
  bang()
  redraw()
  g.all(0)
  g.led(v1_octave+13,1,15)
  g.led(v2_octave+13,2,15)
  if new_low < 17 then
    g.led(new_low,4,15)
  elseif new_low > 16 then
    g.led(new_low-16,5,15)
  end
  if new_high < 17 then
    g.led(new_high,6,15)
  elseif new_high > 16 then
    g.led(new_high-16,7,15)
  end
  grid_redraw()
  g.refresh()
end
