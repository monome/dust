
engine.name = "PolyPerc"

local MusicUtil = require "mark_eats/musicutil"
local root = 36
local function build_scale()
	local r = root + params:get("root")
	scale_notes = MusicUtil.generate_scale(r, params:get("scale"), 1)
end


local MeadowPhysics = require "ansible/meadowphysics"
local mp = MeadowPhysics.loadornew("alphacactus/mp.data") 

local g = grid.connect()

local BeatClock = require "beatclock"

local m = midi.connect()

local options = {}
options.OUTPUT = {"audio", "midi", "audio + midi"}
options.STEP_LENGTH_NAMES = {"1 bar", "1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16", "1/24", "1/32", "1/48", "1/64"}
options.STEP_LENGTH_DIVIDERS = {1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64}

local midi_out_device
local midi_out_channel

local notes = {}
local active notes = {}

local clk = BeatClock.new()
local clk_midi = midi.connect()
clk_midi.event = function(data) clk:process_midi(data) end

local notes_off_metro = metro.alloc()

local function all_notes_off()
	if (params:get("output") == 2 or params:get("output") == 3) then
		for _,a in pairs(active_notes) do
			midi_out_device.note_off(a, nil, midi_out_channel)
		end
	end
	active_notes = {}
end

local function step()
	all_notes_off()

	mp:clock()
	
	for _,n in pairs(notes) do
		local f = MusicUtil.note_num_to_freq(n)
		if (params:get("output") == 1 or params:get("output") == 3) then
			engine.hz(f)
		end

		if (params:get("output") == 2 or params:get("output") == 3) then
			midi_out_device.note_on(n, 96, midi_out_channel)
			table.insert(active_notes, 1)
		end
	end
	notes = {}

	if params:get("note_length") < 4 then
		notes_off_metro:start((60 / clk.bpm / clk.steps_per_beat / 4) * params:get("note_length"), 1)
	end
end

local function stop()
	all_notes_off()
end

local function reset_pattern()
	clk:reset()
end

local grid_clk = metro.alloc()

local screen_clk = metro.alloc()


function init()
	-- meadowphysics
	mp.mp_event = event 
	
	-- scale
	local scales = {}
	for i=1,#MusicUtil.SCALES do
		scales[i] = MusicUtil.SCALES[i].name
	end

	params:add {
		type = "option",
		id = "scale",
		name = "scale",
		options = scales,
		action = build_scale
	}

	params:add {
		type = "option",
		id = "root",
		name = "root",
		options = MusicUtil.NOTE_NAMES,
		action = build_scale
	}

	build_scale()

	-- metro / midi
	midi_out_device = midi.connect(1)
	midi_out_device.event = function() end

	clk.on_step = step
	clk.on_stop = stop
	clk.on_select_internal = function() clk:start() end
	clk.on_select_external = reset_pattern
	clk:add_clock_params()
	params:set("bpm", 60)

	notes_off_metro.callback = all_notes_off
	
	params:add {
		type = "option",
		id = "output",
		name = "output",
		options = options.OUTPUT,
		action = all_notes_off
	}

	params:add {
		type = "number",
		id = "midi_out_device",
		name = "midi out device",
		min = 1, max = 4, default = 1,
		action = function(value) midi_out_device:reconnect(value) end
	}

	params:add {
		type = "number",
		id = "midi_out_channel",
		name = "midi out channel",
		min = 1, max = 16, default = 1,
		action = function(value)
			all_notes_off()
			midi_out_channel = value
		end
	}
	
	params:add_separator()

	params:add {
		type = "option",
		id = "step_length",
		name = "step length",
		options = options.STEP_LENGTH_NAMES,
		default = 4,
		action = function(value)
			clk.ticks_per_step = 96 / options.STEP_LENGTH_DIVIDERS[value]
			clk.steps_per_beat = options.STEP_LENGTH_DIVIDERS[value] / 4
			clk:bpm_change(clk.bpm)
		end
	}

	params:add {
		type = "option",
		id = "note_length",
		name = "note length",
		options = {"25%", "50%", "75%", "100%"},
		default = 4
	}

	-- metro
	grid_clk = metro.alloc()
	grid_clk.callback = function() mp:gridredraw(g) end
	grid_clk.time = 1 / 30

	screen_clk = metro.alloc()
	screen_clk.callback = function() redraw() end
	screen_clk.time = 1 / 15

	-- engine 
  params:add {
		type = "control",
		id = "amp",
		controlspec = controlspec.new(0,1,'lin',0,0.5,''),
    action = function(x) engine.amp(x) end
	}

  params:add {
		type = "control",
		id = "pw",
		controlspec = controlspec.new(0,100,'lin',0,50,'%'),
    action = function(x) engine.pw(x/100) end
	}

	params:add {
		type = "control",
		id = "release",
		controlspec = controlspec.new(0.1,3.2,'lin',0,1.2,'s'),
    action = function(x) engine.release(x) end
	}

  params:add {
		type = "control",
		id = "cutoff",
		controlspec = controlspec.new(50,5000,'exp',0,555,'hz'),
    action = function(x) engine.cutoff(x) end
	}

  params:add {
		type = "control",
		id = "gain",
		controlspec = controlspec.new(0,4,'lin',0,1,''),
    action = function(x) engine.gain(x) end
	}

	params:bang()
	params:add_separator()

	-- grid
	if g then mp:gridredraw(g) end

	screen_clk:start()
	grid_clk:start()
	clk:start()
end

function event(i, s)
	if s == 1 then
		table.insert(notes, scale_notes[i])
	end
end

function redraw()
	screen.clear()
	screen.aa(1)

	for i=1,8 do
		if mp.position[i] >= 1 then
			local y = (i-1)*8
			local x = 0

			x = (mp.position[i]-1)*8
			screen.level(15)
			screen.move(x, y)
			screen.rect(x, y, 8, 8)
			screen.fill()
			screen.stroke()
		end
	end

	screen.level(4)
	for i=0,8 do
		local y = i*8
		screen.move(0,y)
		screen.line(128,y)
		screen.stroke()
		screen.close()
	end

	for i=0,16 do
		local x = i*8
		screen.move(x, 0)
		screen.line(x, 64)
		screen.stroke()
		screen.close()
	end

	screen.update()
end

function draw_bpm()
	screen.clear()
	screen.aa(1)

	screen.move(64,32)
	screen.font_size(32)
	screen.text(params:get("bpm"))
	screen.stroke()

	screen.update()
end

function g.event(x, y, z)
	mp:gridevent(x, y, z)
end

function enc(n, d)
	if n == 1 then
		mix:delta("output", d)
	elseif n == 3 then
		params:delta("bpm", d)
		draw_bpm()
	end
end

function key(n, z)
	if n == 3 and z == 1 then
		mp:save("alphacactus/mp.data")
	end
end

