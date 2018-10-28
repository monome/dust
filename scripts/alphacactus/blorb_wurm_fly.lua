-- wizcraft
-- key1 shift^
-- key2 add vector
-- key2^ 
-- key3 add force
-- key3^ clear screen
-- enc1 drift
-- enc1^ output
-- enc2 push/pull
-- enc2^ select scale
-- enc3 up/down
-- enc3^ select root note

local ripples = {}

local MusicUtil = require "mark_eats/musicutil"

local blorb_scale_notes = {}
function build_blorb_scale()
    local root_note = (params:get("boctave")*12) + params:get("broot")
    blorb_scale_notes = MusicUtil.generate_scale(root_note, params:get("bscale"), 1)
end

local wurm_scale_notes = {}
function build_wurm_scale()
    local root_note = (params:get("woctave")*12) + params:get("wroot")
    wurm_scale_notes = MusicUtil.generate_scale(root_note, params:get("wscale"), 1)
end

local thing_scale_notes = {}
function build_thing_scale()
    local root_note = (params:get("toctave")*12) + params:get("troot")
    thing_scale_notes = MusicUtil.generate_scale(root_note, params:get("tscale"), 1)
end

local MollyThePoly = require "mark_eats/mollythepoly"
engine.name = "MollyThePoly"

-- return plus or minus one at random
local function random_flip()
    return ((math.random(1,2)*2)-3)
end

Blorb = {id=-1, t=0, x=0, y=0, xv=0, yv=0, xa=0, ya=0, s=8}
local blorbs = {}
local MAX_NUM_BLORBS = 16

function Blorb:new(t)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.t = t or 0
    o.x = math.random(120) + 4
    o.y = math.random(56) + 4
    o.xv = 0
    o.yv = 0
    o.xa = math.random() * random_flip()
    o.ya = math.random() * random_flip()

    if #blorbs < MAX_NUM_BLORBS then
        table.insert(blorbs, o)
        o:play_note()
    end

    return o
end

function Blorb:get_scale()
    if self.t == 0 then return blorb_scale_notes
    elseif self.t == 1 then return wurm_scale_notes
    else return thing_scale_notes end
end

function Blorb:update()
    self.xa = math.random() * random_flip() 
    self.ya = math.random() * random_flip()

    local drift = params:get("drift")
    self.xv = util.clamp(self.xv + self.xa, -2*drift, 2*drift)
    self.yv = util.clamp(self.yv + self.ya, -2*drift, 2*drift)

    self.x = self.x + self.xv
    self.y = self.y + self.yv

    local sx = self.x + self.s
    local sy = self.y + self.s

    if self.t == 0 then
        for i=1,#blorbs do -- blorb eats things
            local t = blorbs[i]
            if t and t.t == 2 then
                local tx = t.x + t.s
                local ty = t.y + t.s

                if math.abs(sx-tx) < self.s and math.abs(sy-ty) < self.s then
                    engine.noteOff(t.id)
                    table.remove(blorbs, i)
                    Blorb:new(2)

                    -- grow blorb
                    self.s = self.s + t.s
                    self:play_note()
                end
            end
        end
    elseif self.t == 1 then
        for i=1,#blorbs do -- wurm eats blorbs
            local b = blorbs[i]
            if b and b.t == 0 then
                local bx = b.x + b.s
                local by = b.y + b.s

                local dx = math.abs(sx-bx)        
                local dy = math.abs(sy-by)
                if dx <= self.s and dy <= self.s then
                    engine.noteOff(b.id)
                    table.remove(blorbs, i)
                    Blorb:new(0)
                elseif dx <= self.s+16 and dy <= self.s+16 then
                    if sx > bx then
                        b.x = b.x + 8
                    else 
                        b.x = b.x - 8
                    end

                    if sy > by then
                        b.y = b.y + 4
                    else
                        b.y = b.y - 4
                    end

                    b:play_note()
                end
            end
        end
    else
        for i=1,#blorbs do -- thing eats wurms
            local w = blorbs[i]
            if w and w.t == 1 then
                local wx = w.x + w.s
                local wy = w.y + w.s

                if math.abs(sx-wx) < self.s and math.abs(sy-wy) < self.s then
                    engine.noteOff(w.id)
                    table.remove(blorbs, i)
                    Blorb:new(1)

                    table.insert(ripples, {x=wx, y=wy, r=4})
                end
            end
        end
    end
end

function Blorb:play_note()
    local scale_notes = self:get_scale()
    local note = util.round(util.linlin(0, 192, 1, #scale_notes, self.x+self.y), 1)
    local note_num = scale_notes[note]
    local freq = MusicUtil.note_num_to_freq(note_num)

    self.id = note_num
    engine.noteOn(note_num, freq, 1)
end

function Blorb:draw(c)
    screen.level(c)

    local x = self.x + self.s
    local y = self.y + self.s
    screen.move(x, y)

    if self.t == 0 then
        for i=1,self.s do
            screen.line(x+(math.random(self.s)*random_flip()), y+(math.random(self.s)*random_flip()))
        end
        screen.fill()
    elseif self.t == 1 then
        for i=1,self.s do
            screen.arc(x, y, self.s, math.pi*math.random(), 2*math.pi*math.random()) 
        end
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
    
    params:add_control("drift", "drift", controlspec.new(0,1,"lin",0,0,""))

    params:add_separator()

    local scales = {}
    for i=1,#MusicUtil.SCALES do
        scales[i] = MusicUtil.SCALES[i].name
    end

    --blorb
    params:add_option("bscale", "bscale", scales)
    params:set_action("bscale", build_blorb_scale)

    params:add_option("broot", "broot", MusicUtil.NOTE_NAMES)
    params:set_action("broot", build_blorb_scale)

    params:add_number("boctave", "boctave", 1, 8, 3)
    params:set_action("boctave", build_blorb_scale)

    build_blorb_scale()

    params:add_separator()

    --wurm
    params:add_option("wscale", "wscale", scales)
    params:set_action("wscale", build_wurm_scale)

    params:add_option("wroot", "wroot", MusicUtil.NOTE_NAMES)
    params:set_action("wroot", build_wurm_scale)

    params:add_number("woctave", "woctave", 1, 8, 4)
    params:set_action("woctave", build_wurm_scale)

    build_wurm_scale()

    params:add_separator()

    --thing
    params:add_option("tscale", "tscale", scales)
    params:set_action("tscale", build_thing_scale)

    params:add_option("troot", "troot", MusicUtil.NOTE_NAMES)
    params:set_action("troot", build_thing_scale)

    params:add_number("toctave", "toctave", 1, 8, 5)
    params:set_action("toctave", build_thing_scale)

    build_thing_scale()

    params:add_separator()

    -- engine
    MollyThePoly.add_params()

    clk = metro.alloc()
    clk.time = 1/15
    clk.count = -1
    clk.callback = tick
    clk:start()
end


function tick()
    for i=1,#blorbs do
        local b = blorbs[i]
        if b then
            b:update()
            if b.x > 128 or b.x < 0 or b.y > 64 or b.y < 0 then
                engine.noteOff(b.id)
                table.remove(blorbs, i)
                Blorb:new(b.t)
            end
        end
    end

    redraw()
end


function redraw()
    screen.clear()
    screen.aa(1)
   
    for i=1,#blorbs do
        if blorbs[i].t == 0 then blorbs[i]:draw(15) end
    end
    screen.close()
    screen.stroke()

    for i=1,#blorbs do
        if blorbs[i].t == 1 then blorbs[i]:draw(15) end
    end
    screen.close()
    screen.stroke()

    for i=1,#blorbs do
        if blorbs[i].t == 2 then blorbs[i]:draw(15) end
    end
    screen.close()
    screen.stroke()

    for i=1,#ripples do
        local r = ripples[i]
        if r then
            screen.move(r.x+r.r, r.y)
            screen.circle(r.x, r.y, r.r)
            ripples[i].r = ripples[i].r + 1
            if ripples[i].r >= 64 then ripples[i] = nil end
        end
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

        elseif n == 3 then

        end
    else
        if n == 1 then
            params:delta("drift", d)
        elseif n == 2 then
            for i=1,#blorbs do
                local b = blorbs[i]
                if b then
                    if b.x > 64 then
                        b.x = util.clamp(b.x+d, 64, 124)
                    else
                        b.x = util.clamp(b.x-d, 4, 64)
                    end

                    if b.y > 32 then 
                        b.y = util.clamp(b.y+d, 32, 64)
                    else
                        b.y = util.clamp(b.y-d, 4, 32)
                    end

                    b:play_note()
                end
            end
        elseif n == 3 then
            for i=1,#blorbs do
                local b = blorbs[i]
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
                local w = Blorb:new(1)
            end
        elseif n == 3 then -- clear screen
            engine.noteOffAll()
            blorbs = {}
        end
    else
        if n == 2 then -- add blorb 
            if z == 1 then 
                local b = Blorb:new(0)
            end
        elseif n == 3 then -- add thing 
            if z == 1 then
                local t = Blorb:new(2)
            end
        end
    end
end



