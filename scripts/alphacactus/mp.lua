
--TODO
--fix rules random and stop
--
engine.name = "PolyPerc"

local MusicUtil = require "mark_eats/musicutil"

local scale_notes = {}

function build_scale()
  local root_note = (params:get("octave")*12) + params:get("root")
  scale_notes = MusicUtil.generate_scale_of_length(root_note, params:get("scale"), 8)
end

local g = grid.connect()

local gridbuf = require "gridbuf"
local gbuf = gridbuf.new(16, 8)

m = {
	count = {},
	position = {},
	speed = {},
	tick = {},
	min = {},
	max = {},
	trigger = {},
	toggle = {},
	rules = {},
	rule_dests = {},
	sync = {},
	sound = {},
	pushed = {},
	rule_dest_targets = {},
	smin = {},
	smax = {}
}

function mp_event(i)
	engine.hz(MusicUtil.note_num_to_freq(scale_notes[i]))
	redraw()
end

function mp_apply_rule(i)
	local rd = m.rule_dests[i]

	if m.rules[i] == 2 then -- inc
		if (m.rule_dest_targets[i] & 1) > 0 then
			m.count[rd] = m.count[rd] + 1
			if m.count[rd] > m.max[rd] then m.count[rd] = m.min[rd] end
		end

		if (m.rule_dest_targets[i] & 2) > 0 then
			m.speed[rd] = m.speed[rd] + 1
			if m.speed[rd] > m.smax[rd] then m.speed[rd] = m.smin[rd] end
		end

	elseif m.rules[i] == 3 then -- dec
		if (m.rule_dest_targets[i] & 1) > 0 then
			m.count[rd] = m.count[rd] - 1
			if m.count[rd] < m.min[rd] then m.count[rd] = m.max[rd] end
		end

		if (m.rule_dest_targets[i] & 2) > 0 then
			m.speed[rd] = m.speed[rd] - 1
			if m.speed[rd] < m.smin[rd] then m.speed[rd] = m.smax[rd] end
		end

	elseif m.rules[i] == 4 then -- max
		if (m.rule_dest_targets[i] & 1) > 0 then m.count[rd] = m.max[rd] end

		if (m.rule_dest_targets[i] & 2) > 0 then m.speed[rd] = m.smax[rd] end

	elseif m.rules[i] == 5 then -- min
		if (m.rule_dest_targets[i] & 1) > 0 then m.count[rd] = m.min[rd] end

		if (m.rule_dest_targets[i] & 2) > 0 then m.speed[rd] = m.smin[rd] end

	elseif m.rules[i] == 6 then -- rnd
		if (m.rule_dest_targets[i] & 1) > 0 then
			m.count[rd] = math.random(m.max[rd] - m.min[rd] + 1) + m.min[rd]
		end

		if (m.rule_dest_targets[i] & 2) > 0 then
			m.speed[rd] = math.random(m.smax[rd] - m.smin[rd] + 1) + m.smin[rd]
		end

	elseif m.rules[i] == 7 then -- pole
		if (m.rule_dest_targets[i] & 1) > 0 then
			if math.abs(m.count[rd] - m.min[rd]) < math.abs(m.count[rd] - m.max[rd]) then
				m.count[rd] = m.max[rd]
			else
				m.count[rd] = m.min[rd]
			end
		end

		if (m.rule_dest_targets[i] & 2) > 0 then
			if math.abs(m.speed[rd] - m.smin[rd]) < math.abs(m.speed[rd] - m.smax[rd]) then
				m.speed[rd] = m.smax[rd]
			else
				m.speed[rd] = m.smin[rd]
			end
		end

	elseif m.rules[i] == 8 then -- stop
		if (m.rule_dest_targets[i] & 1) > 0 then
			m.position[rd] = -1
		end
	end
end

function init()
	edit_row = 0
	key_count = 0
	mode = 0
	prev_mode = 0

	kcount = 0

	scount = {}
	for i=1,8 do scount[i] = 0 end

	-- ack
	--ack.add_channel_params(1)
	--ack.add_effects_params()

	-- musicutil
  local scales = {}
  for i=1,#MusicUtil.SCALES do
    scales[i] = MusicUtil.SCALES[i].name
  end

	params:add_option("scale", "scale", scales)
	params:set_action("scale", build_scale)

	params:add_option("root", "root", MusicUtil.NOTE_NAMES)
	params:set_action("root", build_scale)
	
	params:add_number("octave", "octave", 1, 8, 7)
	params:set_action("octave", build_scale)

	build_scale()

	params:add_separator()

	-- mp
	for i=1,8 do
		m.count[i] = 8+i
		m.position[i] = 8+i
		m.speed[i] = 0
		m.tick[i] = 0
		m.max[i] = 8+i
		m.min[i] = 8+i
		m.trigger[i] = (1 << i)
		m.toggle[i] = 0
		m.rules[i] = 2 -- inc
		m.rule_dests[i] = i
		m.sync[i] = (1 << i)
		m.rule_dest_targets[i] = 3
		m.smin[i] = 0
		m.smax[i] = 0
	end

	-- grid
	if g then gridredraw() end

	-- metro
	params:add_number("bpm", "bpm", 1, 600, 240)
	params:set_action("bpm", function(x) clk.time = 60 / x end)

	params:add_separator()

	clk = metro.alloc()
	clk.time = 60 / 240
	clk.count = -1
	clk.callback = clock_mp 
	clk:start()
end

function clock_mp()
	for i=1,8 do
		if m.tick[i] == 0 then
			m.tick[i] = m.speed[i]

			if i == 8 then print(m.position[i]) end
			if m.position[i] == 1 then 
				mp_event(i)
				mp_apply_rule(i) 
				m.position[i] = m.position[i] - 1

				for n=1,8 do
					if (m.sync[i] & (1 << n)) > 0 then
						m.position[n] = m.count[n]
						m.tick[n] = m.speed[n]
					end
				end

			elseif m.position[i] > 1 then
				m.position[i] = m.position[i] - 1
			end

		else
			m.tick[i] = m.tick[i] - 1
		end
	end
	gridredraw()
end

function key(n,z)
	if n == 1 and z == 1 then
		clock_mp()
	end
end

function enc(n,d)
	if n == 1 then
		params:delta("bpm", d)
	end
end

function redraw()
	screen.clear()
	screen.aa(1)

	local x = math.random(128)
	local y = math.random(64)
	screen.move(x, y)
	screen.text(x .. y)
	screen.update()
end

function g.event(x, y, z)
	print(x, y, z)

	prev_mode = mode

	if x == 1 then
		kcount = kcount + ((z << 1)-1)
		if kcount < 0 then kcount = 0 end

		if kcount == 1 and z == 1 then
			mode = 1
		elseif kcount == 0 then
			mode = 0
			scount[y] = 0
		end

		if mode == 1 and z == 1 then 
			edit_row = y 
		end

	elseif x == 2 and mode ~= 0 then
		if mode == 1 and z == 1 then 
			mode = 2
			edit_row = y
		elseif mode == 2 and z == 0 then
			mode = 1
		end

	elseif mode == 0 then
		scount[y] = scount[y] + ((z << 1) - 1)
		if scount[y] < 0 then scount[y] = 0 end

		if z == 1 and scount[y] == 1 then
			m.position[y] = x
			m.count[y] = x
			m.min[y] = x
			m.max[y] = x
			m.tick[y] = m.speed[y]

			--if m.sound then m.pushed[y] = 1 end
		elseif z == 1 and scount[y] == 2 then
			if x < m.count[y] then
				m.min[y] = x
				m.max[y] = m.count[y]
			else
				m.max[y] = x
				m.min[y] = m.count[y]
			end
		end
	elseif mode == 1 then

	elseif mode == 2 and z == 1 then
		if x > 4 and x < 8 then
			m.rule_dests[edit_row] = y
			m.rule_dest_targets[edit_row] = x - 4
		elseif x > 7 then
			m.rules[edit_row] = y
		end
	end
end

function gridredraw()
	gbuf:led_level_all(0)

	if mode == 0 then -- positions
		for i=1,8 do
			for j=m.min[i],m.max[i] do
				gbuf:led_level_set(j, i, 4)
			end

			gbuf:led_level_set(m.count[i], i, 8)

			if m.position[i] >= 1 then
				gbuf:led_level_set(m.position[i], i, 12)
			end
		end
	elseif mode == 1 then -- speed
		for i=1,8 do 
			if m.position[i] >= 1 then gbuf:led_level_set(m.position[i], i, 4) end

			if m.position[i] ~= -1 then gbuf:led_level_set(3, i, 2) end

			for j=m.smin[i],m.smax[i] do
				gbuf:led_level_set(j+9, i, 4)
			end

			gbuf:led_level_set(m.speed[i]+9, i, 8)

			--if m.sound then gbuf:led_level_set(5, i, 2) end

			if (m.toggle[edit_row] & (1 << i)) > 0 then
				gbuf:led_level_set(6, i, 12)
			else
				gbuf:led_level_set(6, i, 4)
			end

			if (m.trigger[edit_row] & (1 << i)) > 0 then
				gbuf:led_level_set(7, i, 12)
			else
				gbuf:led_level_set(7, i, 4)
			end

			if (m.toggle[edit_row] & (1 << i)) > 0 then
				gbuf:led_level_set(4, i, 8)
			else
				gbuf:led_level_set(4, i, 4)
			end
		end

		gbuf:led_level_set(1, edit_row, 8)
	elseif mode == 2 then -- rules
		for i=1,8 do 
			if m.position[i] >= 1 then gbuf:led_level_set(m.position[i], i, 4) end
		end

		gbuf:led_level_set(1, edit_row, 8)
		gbuf:led_level_set(2, edit_row, 8)

		local rd = m.rule_dests[edit_row]
		if m.rule_dest_targets[edit_row] == 1 then
			gbuf:led_level_set(5, rd, 12)
			gbuf:led_level_set(6, rd, 4)
			gbuf:led_level_set(7, rd, 4)
		elseif m.rule_dest_targets[edit_row] == 2 then
			gbuf:led_level_set(5, rd, 4)
			gbuf:led_level_set(6, rd, 12)
			gbuf:led_level_set(7, rd, 4)
		else
			gbuf:led_level_set(5, rd, 12)
			gbuf:led_level_set(6, rd, 12)
			gbuf:led_level_set(7, rd, 4)

			for i=8,16 do
				gbuf:led_level_set(i, m.rules[edit_row], 4)
			end


		end
	end

	gbuf:render(g)
	g.refresh()
end
