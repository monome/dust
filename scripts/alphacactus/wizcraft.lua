-- wizcraft
-- key1 shift^
-- key2 add vector / ^
-- key3 add force / ^clear screen
-- enc1 drift / ^output
-- enc2 push/pull / ^select scale
-- enc3 up/down / ^detune

local MusicUtil = require "mark_eats/musicutil"
local scale_notes = {}

local MollyThePoly = require "mark_eats/mollythepoly"

engine.name = "MollyThePoly"

vectors = {}
local NUM_VECTORS = 8

local forces = {}
local NUM_FORCES = 8

local next_id = 0
local function get_next_id()
    next_id = (next_id % NUM_VECTORS) + 1
    return next_id
end

-- return plus or minus one at random
local function flip()
    return ((math.random(1,2)*2)-3)
end

Vector = {id=0, x=0, y=0, xv=0, yv=0, xa=0, ya=0, s=8}

function Vector:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.x=math.random(128)
    o.y=math.random(64)
    o.xv = 0
    o.yv = 0
    o.xa=math.random() * flip()
    o.ya=math.random() * flip()

    return o
end

function Vector:update()
    self.xa = math.random() * flip() 
    self.ya = math.random() * flip()

    self.xv = util.clamp(self.xv + self.xa, -1*params:get("drift"), 1*params:get("drift"))
    self.yv = util.clamp(self.yv + self.ya, -1*params:get("drift"), 1*params:get("drift"))
    self.xv = util.round(self.xv, 1)
    self.yv = util.round(self.yv, 1)

    self.x = self.x + self.xv
    self.y = self.y + self.yv

    local sx = self.x + self.x
    local sy = self.y + self.y
    for i=1,#vectors do -- check for vector collisions
        local v = vectors[i]
        if v then
            local vx = v.x + v.s
            local vy = v.y + v.s
            if self.id ~= v.id then
                if math.abs(sx-vx) < self.s and math.abs(sy-vy) < self.s then
                    engine.noteOff(v.id)
                    table.remove(vectors, i)

                    local n = Vector:new()
                    n.id = get_next_id()
                    table.insert(vectors, n)
                    n:play_note()

                    self.s = self.s + v.s
                    self:play_note()
                end
            end
        end
    end

end

function Vector:update_f() 
    self.xa = math.random() * flip() 
    self.ya = math.random() * flip()

    self.xv = util.clamp(self.xv + self.xa, -2, 2)
    self.yv = util.clamp(self.yv + self.ya, -2, 2)

    self.xv = util.round(self.xv, 1)
    self.yv = util.round(self.yv, 1)

    self.x = util.clamp(self.x + self.xv, 2, 126)
    self.y = util.clamp(self.y + self.yv, 2, 62)

    local sx = self.x + self.s
    local sy = self.y + self.s
    for i=1,#vectors do
        local v = vectors[i]
        if v then
            local vx = v.x + v.s
            local vy = v.y + v.s

            local dx = math.abs(sx-vx)        
            local dy = math.abs(sy-vy)
            if dx <= 2 and dy <= 2 then
                engine.noteOff(v.id)
                table.remove(vectors, i)

                MollyThePoly.randomize_params("lead")
                MollyThePoly.randomize_params("pad")
                MollyThePoly.randomize_params("percussion")

                local n = Vector:new()
                n.id = get_next_id()
                table.insert(vectors, n)
                n:play_note()
            elseif dx <= 16 and dy <= 16 then
                if sx > vx then
                    v.x = v.x + 4
                else 
                    v.x = v.x - 4
                end

                if sy > vy then
                    v.y = v.y + 4
                else
                    v.y = v.y - 4
                end
                vectors[i] = v
                vectors[i]:play_note()
            end
        end
    end
end

function Vector:play_note()
    local note = util.round(util.linlin(0, 128, 1, #scale_notes, self.x), 1)
    local octave = util.round(util.linlin(0, 64, 1, 7, self.y), 1)
    local note_num = scale_notes[note] + (octave*12)
    local freq = MusicUtil.note_num_to_freq(note_num)
    --[[local note = ((7-(self.y/8))*5) + (self.x/8)
    freq =  55*2^(note/12)]]--
    engine.noteOn(self.id, freq, 1)
end

function Vector:draw(c)
    screen.level(c)

    local x = self.x + self.s
    local y = self.y + self.s
    screen.move(x, y)
    for i=1,self.s do
        screen.line(x+(math.random(self.s)*flip()), y+(math.random(self.s)*flip()))
    end

    screen.fill()
end

function Vector:draw_f(c)
    screen.level(c)

    local x = self.x + self.s
    local y = self.y + self.s
    screen.move(x, y)
    for i=1,self.s do
        screen.arc(x, y, self.s, math.pi*math.random(), 2*math.pi*math.random()) 
    end
end

function init()
    tmp = 1
    shift = 0
    scale_notes = MusicUtil.generate_scale(0, scale_type, 1)

    params:add_number("scale_type", "scale_type", 1, #MusicUtil.SCALES, 1)

    params:add_control("drift", "drift", controlspec.new(0,2,"lin",0,0,""))
    MollyThePoly.add_params()

    clk = metro.alloc()
    clk.time = 1/15
    clk.count = -1
    clk.callback = tick
    clk:start()
end


function tick()
    redraw()
end


function redraw()
    screen.clear()
    screen.aa(1)
   
    for i=1,#vectors do
        local v = vectors[i]
        if v then
            v:draw(15)
            v:update()
            if v.x > 128 or v.x < 0 or v.y > 64 or v.y < 0 then
                engine.noteOff(v.id)
                table.remove(vectors, i)

                local n = Vector:new()
                n.id = get_next_id()
                table.insert(vectors, n)
                n:play_note()
            end
        end
    end
    screen.close()
    screen.stroke()

    for i=1,#forces do
        local f = forces[i]
        f:draw_f(15)
        f:update_f()
    end
    screen.close()
    screen.stroke()
    screen.update()
end


function enc(n, d)
    if shift == 1 then
        if n == 1 then
            mix:delta("output", d)
        elseif n == 2 then
            params:delta("scale_type", d)
            scale_notes = MusicUtil.generate_scale(0, params:get("scale_type"), 1)
            tab.print(scale_notes)
        elseif n == 3 then
            params:delta("detune", d)
        end
    else
        if n == 1 then
            params:delta("drift", d)
        elseif n == 2 then
            for i=1,#vectors do
                local v = vectors[i]
                if v then
                    if v.x > 64 then
                        v.x = util.clamp(v.x+d, 64, 128-v.s)
                    else
                        v.x = util.clamp(v.x-d, 0, 63-v.s)
                    end

                    if v.y > 32 then 
                        v.y = util.clamp(v.y+d, 32, 64-v.s)
                    else
                        v.y = util.clamp(v.y-d, 0, 31-v.s)
                    end

                    v:play_note()
                end
            end
        elseif n == 3 then
            for i=1,#vectors do
                local v = vectors[i]
                if v then
                    v.y = util.clamp(v.y+d, 0, 64-v.s)
                    v:play_note()
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
        if n == 2 then
            local f = Vector:new()
            table.insert(forces, f)
        elseif n == 3 then -- clear all vectors
            engine.noteOffAll()
            vectors = {}
            forces = {}
        end
    else
        if n == 2 then -- add vector
            if z == 1 then 
                local v = Vector:new()
                v.id = get_next_id()
                table.insert(vectors, v)
                v:play_note()
            end
        elseif n == 3 then 
            if z == 1 then
                local f = Vector:new()
                table.insert(forces, f)
            end
        end
    end
end




