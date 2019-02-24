--
-- polyperc_seq v0.1
--
-- grid controls arpeggio
-- // midi sends notes out to world
-- ENC2 = bpm
-- ENC3 = scale

engine.name = 'PolyPerc'

local cs = require 'controlspec'

music = require 'mark_eats/musicutil'
beatclock = require 'beatclock'

steps = {}
position = 1
transpose = 0

k2_mode = 0
k3_state = 0

mode = math.random(#music.SCALES)
scale = music.generate_scale_of_length(60,music.SCALES[mode].name,8)

clk = beatclock.new()
clk_midi = midi.connect()
clk_midi.event = clk.process_midi

function init()
    for i=1,16 do
        table.insert(steps,math.random(8))
    end

    grid_redraw()

    clk.on_step = count
    clk.on_select_internal = function() clk:start() end
    clk.on_select_external = function() print("external") end
    clk:add_clock_params()


    params:add_separator()

    cs.AMP = cs.new(0,1,'lin',0,0.5,'')
    params:add_control("amp", "amp", cs.AMP)
    params:set_action("amp",
        function(x) engine.amp(x) end)

    cs.PW = cs.new(0,100,'lin',0,80,'%')
    params:add_control("pw", "pw", cs.PW)
    params:set_action("pw",
        function(x) engine.pw(x/100) end)

    cs.REL = cs.new(0.1,3.2,'lin',0,0.2,'s')
    params:add_control("release", "release", cs.REL)
    params:set_action("release",
        function(x) engine.release(x) end)

    cs.CUT = cs.new(50,5000,'exp',0,555,'hz')
    params:add_control("cutoff", "cutoff", cs.CUT)
    params:set_action("cutoff",
        function(x) engine.cutoff(x) end)

    cs.GAIN = cs.new(0,4,'lin',0,1,'')
    params:add_control("gain", "gain", cs.GAIN)
    params:set_action("gain",
        function(x) engine.gain(x) end)

    params:bang()

    clk:start()
end

function key(n,z)
    if n == 2 then
        k2_mode = z
        redraw()
    end
    if n == 3 and z == 1 then
        if k3_state == 0 then
            clk:stop()
            k3_state = 1
        elseif k3_state == 1 then
            clk:start()
            k3_state = 0
        end
    end
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
    if k2_mode == 0 then
        screen.clear()
        screen.level(15)
        screen.move(0,30)
        screen.text("bpm: "..params:get("bpm"))
        screen.move(0,40)
        screen.text(music.SCALES[mode].name)
        screen.update()
    elseif k2_mode == 1 then
        screen.clear()
        screen.level(15)
        screen.move(0,30)
        screen.text("K2 pressed")
        screen.update()
    end
end

g = grid.connect()

g.event = function(x,y,z)
    if z == 1 then
        if steps[x] == y then
            steps[x] = 0
        else
            steps[x] = y
        end
        grid_redraw()
    end
end

function grid_redraw()
    g.all(0)
    for i=1,16 do
        g.led(i,steps[i],i==position and 15 or 4)
        --g.led(i,7,i==position and 15 or 4)
    end
    g.refresh()
end

--m = midi.connect(2)

function count()
    position = (position % 16) + 1
    engine.hz(music.note_num_to_freq(scale[steps[position]] + transpose))


    --engine.noteOn(1,music.note_num_to_freq(scale[steps[position]] + transpose),1)

    -- MIDI
    --cur_note = music.freq_to_note_num(music.note_num_to_freq(scale[steps[position]] + transpose),1)
    --m.note_on(cur_note,100)
    --m.note_off(cur_note,0)
    --

    grid_redraw()
end

k = midi.connect(3)
k.event = function(data)
    local d = midi.to_msg(data)
    if d.type == "note_on" then
        transpose = d.note - 60
    end
end







