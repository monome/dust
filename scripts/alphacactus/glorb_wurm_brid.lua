-- glorb, wurm, brid 
-- v1.0 alpha_cactus
--
-- vector based life chain
-- drone machine
--
-- wurms devour glorbs
-- glorbs translocate brids
-- brids displace wurms
--
-- engine mollythepolly by mark_eats
--
-- drift will let glorbs, 
-- wurms, and brids move or
-- stay in place
--
-- key1 shift^
-- key2  add glorb
-- key2^ add wurm
-- key3  add brid
-- key3^ clear screen
-- enc1  drift 
-- enc1^ resonance
-- enc2  push/pull
-- enc2^ lp filter
-- enc3  up/down
-- enc3^ hp filter


local MusicUtil = require "mark_eats/musicutil"

local glorb_scale_notes = {}
function build_glorb_scale()
  local root_note = (params:get("octave")*12) + params:get("root")
  glorb_scale_notes = MusicUtil.generate_scale(root_note, params:get("scale"), 1)
end

local MollyThePoly = require "mark_eats/mollythepoly"
engine.name = "MollyThePoly"

-- return plus or minus one at random
local function random_flip()
  return ((math.random(1,2)*2)-3)
end

Glorb = {id=nil, t=0, x=0, y=0, xv=0, yv=0, xa=0, ya=0, s=8}
local glorbs = {}
local MAX_NUM_GLORBS = 8

-- glorb object
-- t is the type of glorb
-- 0 = glorb
-- 1 = wurm
-- 2 = bird
function Glorb:new(t)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  -- init glorb location, velocity, and acceleration
  o.t = t or 0
  o.x = math.random(120) + 4
  o.y = math.random(56) + 4
  o.xv = 0
  o.yv = 0
  o.xa = math.random() * random_flip()
  o.ya = math.random() * random_flip()

  -- add glorb to table
  -- max 8 glorbs
  if #glorbs < MAX_NUM_GLORBS then
    table.insert(glorbs, o)
    o:play_note()
  end

  return o
end

function Glorb:update()
  -- give glorbs a new random acceleration
  self.xa = math.random() * random_flip() 
  self.ya = math.random() * random_flip()

  -- if drift > 0 then glrobs will move
  local drift = params:get("drift")
  self.xv = util.clamp(self.xv + self.xa, -2*drift, 2*drift)
  self.yv = util.clamp(self.yv + self.ya, -2*drift, 2*drift)

  self.x = util.round(self.x + self.xv, 1)
  self.y = util.round(self.y + self.yv, 1)

  -- check glorb, wurm, brid proximity
  local sx = self.x + self.s
  local sy = self.y + self.s
  if self.t == 0 then
    for i=1,#glorbs do -- glorb eats brids to grow
      local b = glorbs[i]
      if b and b.t == 2 then
        local bx = b.x + b.s
        local by = b.y + b.s

        -- glorb will swap with brid if on same x or y axis
        if math.abs(sx-bx) < self.s or math.abs(sy-by) < self.s then
          self.x, b.x = b.x, self.x
          self.y, b.y = b.y, self.y

          -- play notes for new locations
          b:play_note() 
          self:play_note()
        end
      end
    end
  elseif self.t == 1 then
    for i=1,#glorbs do -- wurm eats glorbs
      local g = glorbs[i]
      if g and g.t == 0 then
        local gx = g.x + g.s
        local gy = g.y + g.s

        -- calculate delta between coordinates
        local dx = math.abs(sx-gx)
        local dy = math.abs(sy-gy)
        -- wurm eats glorb if right next to it
        if dx <= self.s and dy <= self.s then
          -- eat glorb then create new
          engine.noteOff(g.id)
          table.remove(glorbs, i)
          Glorb:new(g.t)

        -- else the wurm will suck the glorb towards it
        elseif dx <= self.s+16 and dy <= self.s+16 then
          -- move glorb towards wurm and play note for new location
          if sx > gx then
            g.x = g.x + 4
          else 
            g.x = g.x - 4
          end

          if sy > gy then
            g.y = g.y + 4
          else
            g.y = g.y - 4
          end
      
          g:play_note()
        end
      end
    end
  elseif self.t == 2 then
    for i=1,#glorbs do -- brid scares away wurms
      local w = glorbs[i]
      if w and w.t == 1 then
        local wx = w.x + w.s
        local wy = w.y + w.s

        -- calculate delta between coordinates
        local dx = math.abs(sx-wx)
        local dy = math.abs(sy-wy)
        -- wurm will run from brid then play new note
        if dx < self.s+16 and dy < self.s+16 then
          if sx > w.x then
            w.x = w.x - 8
          else
            w.x = w.x + 8
          end

          if sy > w.y then
            w.y = w.y - 8
          else
            w.y = w.y + 8
          end

          w:play_note()
        end
      end
    end
  end
end

-- play the glorb note based on its location
function Glorb:play_note()
  if self.id ~= nil then engine.noteOff(self.id) end

  local note = util.round(util.linlin(0, 192, 1, #glorb_scale_notes, self.x+self.y), 1)
  local note_num = glorb_scale_notes[note]
  local freq = MusicUtil.note_num_to_freq(note_num)

  self.id = note_num
  engine.noteOn(self.id, freq, 1)
end

-- draw the glorb, wurm or brid
function Glorb:draw(c)
  screen.level(c)

  local x = self.x + self.s
  local y = self.y + self.s
  screen.move(x, y)

  -- draw glrob
  if self.t == 0 then
    for i=1,self.s do
      screen.line(x+(math.random(self.s)*random_flip()), y+(math.random(self.s)*random_flip()))
    end
    screen.fill()
  -- draw wurm
  elseif self.t == 1 then
    for i=1,self.s do
      screen.arc(x, y, self.s, math.pi*math.random(), 2*math.pi*math.random()) 
    end
  -- draw brid
  else
    for i=1,self.s do
      local r = (self.s/2)*math.random()*random_flip()
      screen.rect(x+r, y-r, r, r)
      screen.rect(x-r, y+r, r, r)
    end
    screen.fill()
  end
end


function init()
  shift = 0

  -- drift
  params:add_control("drift", "drift", controlspec.new(0,1,"lin",0,0.5,""))

  params:add_separator()

  local scales = {}
  for i=1,#MusicUtil.SCALES do
    scales[i] = MusicUtil.SCALES[i].name
  end

  --glorb
  params:add_option("scale", "scale", scales)
  params:set_action("scale", build_glorb_scale)

  params:add_option("root", "root", MusicUtil.NOTE_NAMES)
  params:set_action("root", build_glorb_scale)

  params:add_number("octave", "octave", 1, 8, 3)
  params:set_action("octave", build_glorb_scale)

  build_glorb_scale()

  params:add_separator()

  -- engine
  MollyThePoly.add_params()

  params:set("osc_wave_shape", 2)
  params:set("main_osc_level", 0.7)
  params:set("sub_osc_level", 0.3)
  params:set("lp_filter_cutoff", 3000)
  params:set("amp", 1.0)

  -- metro
  clk = metro.alloc()
  clk.time = 1/15
  clk.count = -1
  clk.callback = tick
  clk:start()
end


function tick()
  -- update each glorb
  for i=1,#glorbs do
    local g = glorbs[i]
    if g then
      g:update()

      -- if the glorb goes off screen make a new one
      if g.x+g.s > 128 or g.x+g.s < 0 or g.y+g.s > 64 or g.y+g.s < 0 then
        engine.noteOff(g.id)
        table.remove(glorbs, i)
        Glorb:new(g.t)
      end
    end
  end

  redraw()
end


function redraw()
  screen.clear()
  screen.aa(1)

  for i=1,#glorbs do
    if glorbs[i].t == 0 then glorbs[i]:draw(15) end
  end
  screen.close()
  screen.stroke()

  for i=1,#glorbs do
    if glorbs[i].t == 1 then glorbs[i]:draw(15) end
  end
  screen.close()
  screen.stroke()

  for i=1,#glorbs do
    if glorbs[i].t == 2 then glorbs[i]:draw(15) end
  end
  screen.close()
  screen.stroke()

  screen.update()
end


function enc(n, d)
  if shift == 1 then
    if n == 1 then
      params:delta("lp_filter_resonance", d)
    elseif n == 2 then
      params:delta("lp_filter_cutoff", d)
    elseif n == 3 then
      params:delta("hp_filter_cutoff", d)
    end
  else
    if n == 1 then
      -- drift allows glorbs to move
      params:delta("drift", d)
    elseif n == 2 then
      -- push/pull glorbs
      for i=1,#glorbs do
        local b = glorbs[i]

        if b then
          if b.x > 64 then
            b.x = util.clamp(b.x+d, 64-b.s, 124)
          else
            b.x = util.clamp(b.x-d, 4, 64-b.s)
          end

          if b.y > 32 then 
            b.y = util.clamp(b.y+d, 32-b.s, 64)
          else
            b.y = util.clamp(b.y-d, 4, 32-b.s)
          end

          b:play_note()
        end
      end
    elseif n == 3 then
      -- move glorbs up or down
      for i=1,#glorbs do
        local b = glorbs[i]

        if b then
          b.y = util.clamp(b.y+d, 4, 64)
          b:play_note()
        end
      end
    end
  end
end


function key(n, z)
  if n == 1 then -- shift button
    shift = z
  end

  if shift == 1 then 
    if n == 2 then -- add wurm 
      if z == 1 then
        local w = Glorb:new(1)
      end
    elseif n == 3 then -- clear screen
      engine.noteOffAll()
      glorbs = {}
    end
  else
    if n == 2 then -- add glorb 
      if z == 1 then 
        local b = Glorb:new(0)
      end
    elseif n == 3 then -- add brid 
      if z == 1 then
        local t = Glorb:new(2)
      end
    end
  end
end

