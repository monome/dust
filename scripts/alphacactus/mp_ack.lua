
local ack = require "jah/ack"

engine.name = "Ack"

local meadowphysics = require "ansible/meadowphysics"

local g = grid.connect()

local clk = metro.alloc()

function init()
	-- meadowphysics
	-- mp = meadowphysics.new()
	-- save the meadowphysics state using mp:save("filename")
	mp = meadowphysics.new() -- for default 
	-- mp = meadowphysics.loadornew("alphacactus/mp.data") -- to load a saved state

	-- set mp.mp_event to your callback function(see step function below)
	mp.mp_event = step
	
	-- metro
	params:add_number("bpm", "bpm", 1, 600, 420)
	params:set_action("bpm", function(x) clk.time = 60 / x end)
	clk.time = 60 / params:get("bpm")
	clk.count = -1
	clk.callback = tick

	-- ack
	for channel=1,8 do
		ack.add_channel_params(channel)
	end
  ack.add_effects_params()
	params:read("alphacactus/mp_ack.pset")
	params:bang()

	params:add_separator()

	-- grid
	if g then mp:gridredraw(g) end

	clk:start()
end

-- callback function from meadowphysics
-- parameter "i" is the row number where an event occured
--
-- parameter "s" is the row state
-- if set to trigger mode "s" will be 1 when a row reaches the endpoint
-- else "s" will be 0
--
-- if set to toggle mode "s" will be 1 when toggled on
-- else "s" will be zero when toggled off
function step(i, s)
	-- if a trigger occurs then trigger a sample
	-- when toggled on trigger a sample on each clock step
	if s == 1 then
		engine.trig(i-1)
	end
end

function tick()
	-- call mp:clock() to send a tick to meadowphysics
	mp:clock()
	-- call mp:gridredraw(g) to redraw the meadowphysics grid
	-- note be sure to pass the grid object g into this call
	mp:gridredraw(g)

	redraw()
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
	-- call mp:gridevent(x, y, z) when a grid event occurs
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
	-- mp:save("filename") to save the current state
	if n == 3 and z == 1 then
		mp:save("alphacactus/mp.data")
	end
end

