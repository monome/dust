-- streams
-- norns study 5
--
-- KEY2 - clear pitch table
-- KEY3 - capture pitch to table
--
-- OSC patterns:
-- /x i : noise 0-127
-- /y i : cut 0-127
-- /3/xy f f : noise 0-1 cut 0-1

engine.name = 'PolySub'

collection = {}
last = -1

function init()
    screen.level(4)
    screen.aa(0)
    screen.line_width(1)

    params:add_control("shape","shape", controlspec.new(0,1,"lin",0,0,""))
    params:set_action("shape", function(x) engine.shape(x) end)
    params:add_control("timbre","timbre", controlspec.new(0,1,"lin",0,0.5,""))
    params:set_action("timbre", function(x) engine.timbre(x) end)
    params:add_control("noise","noise", controlspec.new(0,1,"lin",0,0,""))
    params:set_action("noise", function(x) engine.noise(x) end)
    params:add_control("cut","cut", controlspec.new(0,32,"lin",0,8,""))
    params:set_action("cut", function(x) engine.cut(x) end)
    params:add_control("fgain","fgain", controlspec.new(0,6,"lin",0,0,""))
    params:set_action("fgain", function(x) engine.fgain(x) end)
    params:add_control("cutEnvAmt","cutEnvAmt", controlspec.new(0,1,"lin",0,0,""))
    params:set_action("cutEnvAmt", function(x) engine.cutEnvAmt(x) end)
    params:add_control("detune","detune", controlspec.new(0,1,"lin",0,0,""))
    params:set_action("detune", function(x) engine.detune(x) end)
    params:add_control("ampAtk","ampAtk", controlspec.new(0.01,10,"lin",0,1.5,""))
    params:set_action("ampAtk", function(x) engine.ampAtk(x) end)
    params:add_control("ampDec","ampDec", controlspec.new(0,2,"lin",0,0.1,""))
    params:set_action("ampDec", function(x) engine.ampDec(x) end)
    params:add_control("ampSus","ampSus", controlspec.new(0,1,"lin",0,1,""))
    params:set_action("ampSus", function(x) engine.ampSus(x) end)
    params:add_control("ampRel","ampRel", controlspec.new(0.01,10,"lin",0,1,""))
    params:set_action("ampRel", function(x) engine.ampRel(x) end)
    params:add_control("cutAtk","cutAtk", controlspec.new(0.01,10,"lin",0,0.05,""))
    params:set_action("cutAtk", function(x) engine.cutAtk(x) end)
    params:add_control("cutDec","cutDec", controlspec.new(0,2,"lin",0,0.1,""))
    params:set_action("cutDec", function(x) engine.cutDec(x) end)
    params:add_control("cutSus","cutSus", controlspec.new(0,1,"lin",0,1,""))
    params:set_action("cutSus", function(x) engine.cutSus(x) end)
    params:add_control("cutRel","cutRel", controlspec.new(0.01,10,"lin",0,1,""))
    params:set_action("cutRel", function(x) engine.cutRel(x) end)
    params:bang()

    engine.level(0.02)

    pitch_tracker = poll.set("pitch_in_l")
    pitch_tracker.callback = function(x)
        if x > 0 then
            table.insert(collection,x)
            engine.start(#collection,x)
            last = x
            redraw()
        end
    end
end

function key(n,z)
    if n==2 and z==1 then
        engine.stopAll()
        collection = {}
        last = -1
        redraw()
    elseif n==3 and z==1 and #collection < 16 then
        pitch_tracker:update()
    end
end

local osc_in = function(path, args, from)
    if path == "/x" then
        params:set_raw("noise",args[1]/127)
    elseif path == "/y" then
        params:set_raw("cut",args[1]/127)
    elseif path == "/3/xy" then
        params:set_raw("noise",args[1])
        params:set_raw("cut",1-args[2])
    else
        print(path)
        tab.print(args)
    end
end

osc.event = osc_in

function redraw()
    screen.clear()
    screen.move(0,10)
    if last ~= -1 then screen.text(#collection .. " > " .. string.format("%.2f",last)) end
    for i,y in pairs(collection) do
        screen.move(4+(i-1)*8,60)
        screen.line_rel(0,-(8 * (math.log(collection[i]))-30))
        screen.stroke()
    end
    screen.update()
end