
local tabutil = require "tabutil"

local gridscales = {}
gridscales.__index = gridscales

gridscales.L0 = 4
gridscales.L1 = 8
gridscales.L2 = 12

local gridbuf = require "gridbuf"
local gbuf = gridbuf.new(16, 8)

function gridscales.new()
	local m = {}
	setmetatable(m, gridscales)

	m.scales = {}
	m.selected = 1

	m.scales = {
		{0, 2, 2, 1, 2, 2, 2, 1},
		{0, 2, 1, 2, 2, 2, 1, 2},
		{0, 1, 2, 2, 2, 1, 2, 2},
		{0, 2, 2, 2, 1, 2, 2, 1},
		{0, 2, 2, 1, 2, 2, 1, 2},
		{0, 2, 1, 2, 2, 1, 2, 2},
		{0, 1, 2, 2, 1, 2, 2, 2},
		{0, 2, 2, 2, 2, 2, 2, 2},
		{0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0}
	}

	return m
end

function gridscales:note(i)
	local n = 0
	for y=1,i do
		n = n + self.scales[self.selected][y]
	end

	return n
end

function gridscales:gridevent(x, y, z)
	-- select scale
	if x < 9 then
		if z == 1 then
			if y == 7 then -- top row
				self.selected = x		
			elseif y == 8 then -- bottom rom
				self.selected = 8 + x
			end
		end
	-- change scale
	else
		local y = math.abs(y-9) -- inverse so that index 1 is bottom row
		self.scales[self.selected][y] = x - 9
	end
end

function gridscales:gridredraw(g)
	gbuf:led_level_all(0)

	-- draw top row
	for x=1,8 do
		gbuf:led_level_set(x, 7, self.selected == x and gridscales.L2 or gridscales.L0)
	end
	
	-- draw bottom row
	for x=9,16 do
		gbuf:led_level_set(x-8, 8, self.selected == x and gridscales.L2 or gridscales.L0)
	end

	-- draw divider
	for y=1,8 do
		gbuf:led_level_set(9, y, gridscales.L1)
	end

	-- draw scale
	for y=1,8 do
		local i = math.abs(y-9) -- inverse so that index 1 is bottom row
		gbuf:led_level_set(9+self.scales[self.selected][i], y, gridscales.L2)
	end

	gbuf:render(g)
	g.refresh()
end

function gridscales.loadornew(f)
	local s
	s = tabutil.load(data_dir .. f)

	if s == nil then
		s = gridscales.new()
	else
		setmetatable(s, gridscales)
	end

	return s
end

function gridscales:save(f)
	print("saving gridscales")

	for k,v in ipairs(self) do
		print("saving gridscales." .. k)
	end

	tabutil.save(self, data_dir .. f)
end

return gridscales
