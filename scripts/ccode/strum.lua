-- strum v0.52
--
-- tap grid pads to change pitch
-- double tap to add a rest
--
-- ENC 1: adjusts direction
-- ENC 2: adjusts tempo
-- ENC 3: sets scale
-- KEY 3: pauses/restarts
-- MIDI : transposes key
--
-- synth params can be changed
--
-- based on norns study #4
--
-- @carvingcode (Randy Brown)
--

engine.name = 'KarplusRings'

local cs = require 'controlspec'
music = require 'mark_eats/musicutil'
beatclock = require 'beatclock'

version = "v0.52"
name = ":: strum :: "

steps = {}
playmode = {"Onward","Aft","Sway","Joy"}
playchoice = 1
position = 1
transpose = 0
direction = 1
k3_state = 0

mode = math.random(#music.SCALES)
scale = music.generate_scale_of_length(60,music.SCALES[mode].name,8)

clk = beatclock.new()
clk_midi = midi.connect()
clk_midi.event = clk.process_midi

--
-- setup
--
function init()

    for i=1,16 do
        table.insert(steps,1)
    end
    grid_redraw()
    redraw()

    clk.on_step = handle_step
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

    cs.COEF = cs.new(0.2,0.9,'lin',0,0.2,'')
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

    cs.BPF_FREQ = cs.new(100,4000,'lin',0,0.5,'')
    params:add_control("bpf_freq", "bpf_freq", cs.BPF_FREQ)
    params:set_action("bpf_freq",
        function(x) engine.bpf_freq(x) end)

    cs.BPF_RES = cs.new(0,3,'lin',0,0.5,'')
    params:add_control("bpf_res", "bpf_res", cs.BPF_RES)
    params:set_action("bpf_res",
        function(x) engine.bpf_res(x) end)

    params:bang()

    clk:start()

end

--
-- each step
--
function handle_step()
    --print(playmode[playchoice])
    if playmode[playchoice] == "Onward" then
        position = (position % 16) + 1
    elseif playmode[playchoice] == "Aft" then
        position = position - 1
        if position == 0 then
            position = 16
        end
    elseif playmode[playchoice] == "Sway" then
        if direction == 1 then
            position = (position % 16) + 1
            if position == 16 then
                direction = 0
            end
        else
            position = position - 1
            if position == 1 then
                direction = 1
            end
        end
    else
        position = math.random(1,16)
    end

    if steps[position] ~= 0 then
        vel = math.random(1,100) / 100 -- random velocity values
        --print(vel)
        engine.amp(vel)
        engine.hz(music.note_num_to_freq(scale[steps[position]] + transpose))
    end
    grid_redraw()
end

--
-- norns keys
--
function key(n,z)
    --if n == 2 and z == 1 then
    --prompt = "key 2 pressed"
    --end
    if n == 3 and z == 1 then
        --prompt = "key 3 pressed"
        if k3_state == 0 then
            clk:stop()
            g.all(0)
            g.refresh()
            k3_state = 1
        else
            clk:start()
            k3_state = 0
        end
    end
    --if z == 0 then
    --prompt = "key released"
    --end
    redraw()
end

--
-- norns encoders
--
function enc(n,d)
    if n == 1 then          -- sequence direction
        playchoice = util.clamp(playchoice + d, 1, #playmode)
        print (playchoice)
    elseif n == 2 then      -- tempo
        params:delta("bpm",d)
    elseif n == 3 then      -- scale
        mode = util.clamp(mode + d, 1, #music.SCALES)
        scale = music.generate_scale_of_length(60,music.SCALES[mode].name,8)
    end
    redraw()
end

--
-- norns screen display
--
function redraw()
    screen.clear()
    screen.move(44,10)
    screen.level(5)
    screen.text(name)
    screen.move(0,20)
    screen.text("---------------------------------")
    screen.move(0,30)
    screen.level(5)
    screen.text("Path: ")
    screen.move(30,30)
    screen.level(15)
    screen.text(playmode[playchoice])
    screen.move(0,40)
    screen.level(5)
    screen.text("Tempo: ")
    screen.move(30,40)
    screen.level(15)
    screen.text(params:get("bpm").." bpm")
    screen.move(0,50)
    screen.level(5)
    screen.text("Scale: ")
    screen.move(30,50)
    screen.level(15)
    screen.text(music.SCALES[mode].name)
    --screen.move(64,60)
    --screen.level(2)
    --screen.text(":: carvingcode ::")
    screen.update()
end

--
-- grid functions
--
g = grid.connect()

g.event = function(x,y,z)
    --print(x,y,z)
    if z == 1 then
        if steps[x] == y then
            steps[x] = 0
        else
            steps[x] = y
        end
        grid_redraw()
    end
    redraw()
end

function grid_redraw()
    g.all(0)
    for i=1,16 do
        if steps[i] ~= 0 then
            for j=0,7 do
                g.led(i,steps[i]+j,i==position and 12 or (2+j))
            end
        end
    end
    g.refresh()
end

--
-- midi functions
--
k = midi.connect(1)
k.event = function(data)
    local d = midi.to_msg(data)
    if d.type == "note_on" then
        transpose = d.note - 60
    end
end