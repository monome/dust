-- wizcraft
-- vector drone machine
-- 
--
-- key1
-- key2 generate vector
-- key3
-- enc1
-- enc2
-- enc3

engine.name = 'PolySub'

vectors = {}
NUM_VECTORS = 16

next_id = 0
function get_next_id()
    next_id = (next_id % NUM_VECTORS) + 1
    return next_id
end

Vector = {id=0, x=0, y=0, xv=0, yv=0, xa=0, ya=0, s=16}

function Vector:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.id = get_next_id()
    o.x=math.random(128)
    o.y=math.random(64)
    --o.xv = ((math.random(1,2)*2)-3)
    --o.yv = ((math.random(1,2)*2)-3)
    o.xa=math.random() * ((math.random(1,2)*2)-3)
    o.ya=math.random() * ((math.random(1,2)*2)-3)

    return o
end

function Vector:update()
    self.xv = util.clamp(self.xv + self.xa, -1, 1)
    self.yv = util.clamp(self.yv + self.ya, -1, 1)

    self.x = self.x + self.xv
    self.y = self.y + self.yv
end

function Vector:draw()
    screen.move(self.x, self.y)
    screen.rect(self.x, self.y, self.s, self.s)
end

local function getHzET(note)
    return 55*2^(note/12)
end

function init()
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
    screen.level(15)
   
    check_collisions()
    for i=1,#vectors do
        local v = vectors[i]
        v:update()
        v:draw()
        if v.x > 128 or v.x < 0 or v.y > 64 or v.y < 0 then
            engine.stop(v.id)
            table.remove(vectors, i)
        end
    end
    screen.stroke()

    screen.update()
end

function check_collisions()
    for i=1,#vectors do
        local v = vectors[i]
        for j=i+1,#vectors do
            local o = vectors[j]

            if math.abs(v.x-o.x) < v.s and math.abs(v.y-o.y) < v.s then
                engine.stop(o.id)
                table.remove(vectors, j)

                v.s = v.s + 4
                local note = ((7-(v.y/8))*5) + (v.x/8)
                engine.start(v.id, getHzET(note))
            end
        end
    end
end


function enc(n, d)
    if n == 1 then
        mix:delta("output", d)
    elseif n == 2 then
        params:delta("cut", d)
    end
end

function key(n, z)
    if n == 2 then
        if z == 1 then
            local v = Vector:new()
            table.insert(vectors, v)
            local note = ((7-(v.y/8))*5) + (v.x/8)
            engine.start(v.id, getHzET(note))
        end
    end

end






