--
-- grid mapping test case
--
-- dev: ccode
-- date: 2/19/19
--

engine.name = 'KarplusRings'

local cs = require 'controlspec'

music = require 'mark_eats/musicutil'

beatclock = require 'beatclock'

version = "v0.1"
prompt = "grid key mapping " .. version

steps = {}
position = 1
transpose = 0
direction = 1
k3_state = 0

mode = math.random(#music.SCALES)
scale = music.generate_scale_of_length(60,music.SCALES[mode].name,8)

clk = beatclock.new()
clk_midi = midi.connect()
clk_midi.event = clk.process_midi

function init()

    for i=1,16 do
        table.insert(steps,1)
    end
    grid_redraw()
    redraw()

    clk.on_step = count
    clk.on_select_internal = function() clk:start() end
    clk.on_select_external = function() print("external") end
    clk:add_clock_params()


    params:add_separator()

    cs.AMP = cs.new(0,1,'lin',0,0.5,'')
    params:add_control("amp", "amp", cs.AMP)
    params:set_action("amp",
        function(x) engine.amp(x) end)

    cs.DECAY = cs.new(0.1,15,'lin',0,3.6,'s')
    params:add_control("damping", "damping", cs.DECAY)
    params:set_action("damping",
        function(x) engine.decay(x) end)

    cs.COEF = cs.new(0,1,'lin',0,0.11,'')
    params:add_control("brightness", "brightness", cs.COEF)
    params:set_action("brightness",
        function(x) engine.coef(x) end)

    cs.LPF_FREQ = cs.new(100,10000,'lin',0,4500,'')
    params:add_control("lpf_freq", "lpf_freq", cs.LPF_FREQ)
    params:set_action("lpf_freq",
        function(x) engine.lpf_freq(x) end)

    cs.LPF_GAIN = cs.new(0,3.2,'lin',0,0.5,'')
    params:add_control("lpf_gain", "lpf_gain", cs.LPF_GAIN)
    params:set_action("lpf_gain",
        function(x) engine.lpf_gain(x) end)

    cs.BPF_FREQ = cs.new(100,10000,'lin',0,0.5,'')
    params:add_control("bpf_freq", "bpf_freq", cs.BPF_FREQ)
    params:set_action("bpf_freq",
        function(x) engine.bpf_freq(x) end)

    cs.BPF_RES = cs.new(0,4,'lin',0,0.5,'')
    params:add_control("bpf_res", "bpf_res", cs.BPF_RES)
    params:set_action("bpf_res",
        function(x) engine.bpf_res(x) end)

    params:bang()

    clk:start()

end


g = grid.connect()

g.event = function(x,y,z)
    if z == 1 then

        if (x == 16 and y == 8) then

            prompt = x .. " : " .. y
            g.all(0)
            g.refresh()
            redraw()
        end

        if steps[x] == y then
            steps[x] = 0
        else
            steps[x] = y
            prompt = "grid key mapping " .. version
        end
    grid_redraw()
    redraw()
    end
end


--
-- handle norns key presses
--
function key(n,z)
    if n == 2 and z == 1 then
        prompt = "key 2 pressed"
    end
    if n == 3 and z == 1 then
        prompt = "key 3 pressed"

        if k3_state == 0 then
            clk:stop()
            g.all(0)
            g.refresh()
            k3_state = 1
        elseif k3_state == 1 then
            clk:start()
            k3_state = 0
        end
    end
    if z == 0 then
        prompt = "grid key mapping " .. version
    end
    redraw()
end

function enc(n,d)
    if n == 2 then
        params:delta("bpm",d)
    elseif n == 3 then
        mode = util.clamp(mode + d, 1, #music.SCALES)
        scale = music.generate_scale_of_length(60,music.SCALES[mode].name,8)
    end
    redraw()
end

function redraw()
    screen.clear()
    screen.move(0,10)
    screen.level(15)
    screen.text(prompt)
    screen.move(0,30)
    screen.text("bpm: "..params:get("bpm"))
    screen.move(0,40)
    screen.text(music.SCALES[mode].name)
    screen.update()
end

function grid_redraw()
    g.all(0)
    for i=1,16 do
        if steps[i] ~= 0 then
            g.led(i,steps[i],i==position and 15 or 2)
            g.led(i,steps[i]+1,i==position and 15 or 3)
            g.led(i,steps[i]+2,i==position and 15 or 4)
            g.led(i,steps[i]+3,i==position and 15 or 5)
            g.led(i,steps[i]+4,i==position and 15 or 6)
            g.led(i,steps[i]+5,i==position and 15 or 7)
            g.led(i,steps[i]+6,i==position and 15 or 8)
            g.led(i,steps[i]+7,i==position and 15 or 9)
        end
    end
    g.refresh()

end

function count()

    if direction == 1 then
        position = (position % 16) + 1
        if position == 16 then
            direction = 0
        end
        --print("> " .. position)
    else
        position = position - 1
        if position == 1 then
            direction = 1
        end
        --print("< " .. position)
    end
    print("< " .. position)
    if steps[position] ~= 0 then
        engine.hz(music.note_num_to_freq(scale[steps[position]] + transpose))
    end

    grid_redraw()
end

k = midi.connect(3)
k.event = function(data)
    local d = midi.to_msg(data)
    if d.type == "note_on" then
        transpose = d.note - 60
    end
end