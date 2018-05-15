-- subtractive polysynth
-- controlled by midi

local tab = require 'tabutil'
pattern_time = require 'pattern_time'

engine.name = 'PolySub'

-- pythagorean minor/major, kinda
local ratios = { 1, 9/8, 6/5, 5/4, 4/3, 3/2, 27/16, 16/9 }
local base = 27.5 -- low A

local getHz = function ( deg, oct )
	return base * ratios[deg] * (2^oct)
end

local getHzET = function ( note )
	return 55*2^(note/12)
end

-- table of param values indexed by name
local pparams = {
	shape = 0.0,
	timbre = 0.5,
	noise =  0.0,
	cut = 8.0,
	ampAtk = 0.05,
	ampDec = 0.1,
	ampSus = 1.0, ampRel = 1.0, ampCurve =  -1.0,
	cutAtk = 0.0, cutDec = 0.0, cutSus = 1.0, cutRel = 1.0,
	cutCurve =  -1.0, cutEnvAmt = 0.0,
	fgain = 0.0,
	detune = 0,
	delTime = 0.2, delMix = 0.0, delFb = 0.0,
	delSpread = 0.0,
	width = 0.5,
	thresh = 0.6,
	atk = 0.01,
	rel = 0.1,
	slope = 8.0,
	compMix = 1.0,
	room=0.5,
	damp=0.0,
	verbMix=0.0
}

-- FIXME: i guess we need to set up some range / scaling / warping descriptor system. arg!
local param_ranges = {
	shape = {0, 1 },
	timbre = {0, 1 },
	noise =  {0, 1 },
	cut = { 1.0, 32.0 },
	ampAtk = { 0.01, 8.0 },
	ampDec = { 0.0, 2.0 },
	ampSus = { 0.0, 1.0 },
	ampRel = { 0.01, 10.0 },
	ampCurve =  {-1.0, },

	--- not sure about filter env working...
	cutAtk = { 0.0, 1.0 },
	cutDec = {0.0, 1.0 },
	cutSus = {0.0, 1.0, },
	cutRel = {0.0, 1.0 },
	cutCurve = { -4.0, 4.0 },
	cutEnvAmt = {0.0, 1.0 },

	fgain = { 0.0, 4.0 },
	detune = { 0.0, 2.0 },
	delTime = { 0.0, 0.8 },
	delMix = { 0.0, 1.0 },
	delFb = { 0.0, 0.9 },
	delSpread = { 0.0, 0.4 },
	width = { 0.0, 1.0 },
	thresh = { 0.2, 1.0 },
	atk = { 0.0, 0.5 },
	rel = { 0.0, 0.5 },
	slope = { 1.0, 24.0 },
	compMix = { 0.0, 1.0 },
	room= { 0.0, 1.0 },
	damp= { 0.0, 1.0 },
	verbMix= { 0.0, 1.0 },
}

local param_names = tab.sort(pparams)

-- current selected parameter
local cur_param_id = 1

-- current count of active voices
local nvoices = 0

local incParam = function(name, delta)
	print("inc " .. name .. " " .. delta)
	local val = pparams[name] + delta
	if val < param_ranges[name][1] then val = param_ranges[name][1] end
	if val > param_ranges[name][2] then val = param_ranges[name][2] end
	pparams[name] = val
	engine[name](val)
end

init = function()
	pat = pattern_time.new()
	pat.process = grid_note

	if g then
		g:all(0)
		g:refresh()
	end


	params:add_control("shape", controlspec.new(0,1,'lin',0,0,""))
	params:set_action("shape", function(x) engine.shape(x) end)

	params:add_control("timbre", controlspec.new(0,1,'lin',0,0.5,""))
	params:set_action("timbre", function(x) engine.timbre(x) end)

	params:add_control("noise", controlspec.new(0,1,'lin',0,0,""))
	params:set_action("noise", function(x) engine.noise(x) end)

	params:add_control("cut", controlspec.new(0,32,'lin',0,8,""))
	params:set_action("cut", function(x) engine.cut(x) end)

	params:add_control("cutEnvAmt", controlspec.new(0,1,'lin',0,0,""))
	params:set_action("cutEnvAmt", function(x) engine.cutEnvAmt(x) end)

	params:add_control("detune", controlspec.new(0,1,'lin',0,0,""))
	params:set_action("detune", function(x) engine.detune(x) end)

	params:add_control("verbMix", controlspec.new(0,1,'lin',0,0,""))
	params:set_action("verbMix", function(x) engine.verbMix(x) end)

	params:add_control("room", controlspec.new(0,1,'lin',0,0.5,""))
	params:set_action("room", function(x) engine.room(x) end)

	params:add_control("damp", controlspec.new(0,1,'lin',0,0,""))
	params:set_action("damp", function(x) engine.damp(x) end)

	params:add_control("ampAtk", controlspec.new(0.01,10,'lin',0,0.05,""))
	params:set_action("ampAtk", function(x) engine.ampAtk(x) end)

	params:add_control("ampDec", controlspec.new(0,2,'lin',0,0.1,""))
	params:set_action("ampDec", function(x) engine.ampDec(x) end)

	params:add_control("ampSus", controlspec.new(0,1,'lin',0,1,""))
	params:set_action("ampSus", function(x) engine.ampSus(x) end)

	params:add_control("ampRel", controlspec.new(0.01,10,'lin',0,1,""))
	params:set_action("ampRel", function(x) engine.ampRel(x) end)

	params:add_control("cutAtk", controlspec.new(0.01,10,'lin',0,0.05,""))
	params:set_action("cutAtk", function(x) engine.cutAtk(x) end)

	params:add_control("cutDec", controlspec.new(0,2,'lin',0,0.1,""))
	params:set_action("cutDec", function(x) engine.cutDec(x) end)

	params:add_control("cutSus", controlspec.new(0,1,'lin',0,1,""))
	params:set_action("cutSus", function(x) engine.cutSus(x) end)

	params:add_control("cutRel", controlspec.new(0.01,10,'lin',0,1,""))
	params:set_action("cutRel", function(x) engine.cutRel(x) end)


	engine.level(0.05)
	engine.stopAll()

	params:read("earthsea.pset")

	params:bang()
end


enc = function(n,delta)
	if n == 1 then
		norns.audio.adjust_output_level(delta) 
	elseif n==2 then
		cur_param_id = util.clamp(cur_param_id + delta,1,tab.count(pparams))
	elseif n==3 then
		incParam(param_names[cur_param_id], delta * 0.01)
	end
	redraw()
end

key = function(n,z) end

redraw = function()
	screen.clear()
	screen.line_width(1)
	screen.level(15)
	screen.move(0,30)
	screen.text(param_names[cur_param_id] .. " = " .. pparams[param_names[cur_param_id]])
	screen.update()
end



cleanup = function()
	-- nothing to do
	engine.stopAll()
	pat:stop()
	pat = nil
end

norns.midi.event = function(id, data) -- FIXME this should use midi.event (needs setup)
	--tab.print(data)
	if data[1] == 144 then
		--[[
		if data1 == 0 then
		return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
		end
		]]
		note_on(data[2], data[3])
	elseif data[1] == 128 then
		--[[
		if data1 == 0 then
		return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
		end
		]]
		note_off(data[2])
	elseif status == 176 then
		--cc(data1, data2)
	elseif status == 224 then
		--bend(data1, data2)
	end
end

nvoices = 0

note_on = function(note, vel)
	if nvoices < 6 then
		--engine.start(id, getHz(x, y-1))
		engine.start(note, getHzET(note))
		nvoices = nvoices + 1
		redraw()
	end
end

note_off = function(note, vel)
	engine.stop(note)
	nvoices = nvoices - 1
end



