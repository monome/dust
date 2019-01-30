-- haven.
--
-- a safe space?
--

engine.name = "Haven"

local sel = 1
local shift = false

function init()
  params:add{
    type="control",
    id="freq1",
    controlspec=controlspec.new(1, 800, "exp", 0, 20, "Hz"),
    action=engine.freq1,
  }

  params:add{
    type="control",
    id="freq2",
    controlspec=controlspec.new(400, 12000, "exp", 0, 4000, "Hz"),
    action=engine.freq2,
  }

  params:add{
    type="control",
    id="amp1",
    controlspec=controlspec.new(-90, 0, "db", 0, -90, "dB"),
    action=engine.amp1,
  }

  params:add{
    type="control",
    id="amp2",
    controlspec=controlspec.new(-90, 0, "db", 0, -90, "dB"),
    action=engine.amp2,
  }

  params:add{
    type="control",
    id="in_amp",
    controlspec=controlspec.new(-90, 0, "db", 0, -90, "dB"),
    action=engine.inAmp,
  }

  params:add{
    type="control",
    id="fdbck",
    controlspec=controlspec.new(-1, 1, "linear", 0, 0.03, ""),
    action=function(value)
      if (value < 0) then
        engine.fdbckSign(-1)
      else
        engine.fdbckSign(1)
      end
      engine.fdbck(math.abs(value))
    end,
  }

  params:add{
    type="control",
    id="rev_level",
    controlspec=controlspec.new(-math.huge, 18, "db", 0, 0, "dB"),
    action=function(value) mix:set("rev_level", value) end,
  }

  params:bang()
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.font_size(8)
  screen.level(15)

  screen.level(sel == 1 and 15 or 2)
  screen.move(8, 16)
  screen.text("lo: "..params:string("freq1").."  *  "..params:string("amp1"))

  screen.level(sel == 2 and 15 or 2)
  screen.move(8, 24)
  screen.text("hi: "..params:string("freq2").."  *  "..params:string("amp2"))
  
  screen.level(sel == 3 and 15 or 2)
  screen.move(8, 32)
  screen.text("fdbck: "..params:string("fdbck"))

  screen.level(sel == 4 and 15 or 2)
  screen.move(8, 40)
  screen.text("in: "..params:string("in_amp"))

  screen.level(sel == 5 and 15 or 2)
  screen.move(8, 48)
  screen.text("reverb: "..params:string("rev_level"))

  screen.update()
end


function key(n, z)
  if n == 2 and z == 1 then
    sel = sel + 1

    if sel > 5 then
      sel = 1
    end

    redraw()
  end
  
  if n == 3 then
    shift = z == 1
  end
end

function enc(n, delta)
  local delta = delta

  if n == 1 then
    mix:delta("output", delta)
  end

  if sel == 1 then
    if n == 2 then
      if shift then delta = delta / 100 end
      params:delta("freq1", delta)
    end
    if n == 3 then
      if shift then delta = delta / 10 end
      params:delta("amp1", delta)
    end
  elseif sel == 2 then
    if n == 2 then
      if shift then delta = delta / 100 end
      params:delta("freq2", delta)
    end
    if n == 3 then
      if shift then delta = delta / 10 end
      params:delta("amp2", delta)
    end
  elseif sel == 3 then
    if n == 2 or n == 3 then
      if shift then
        params:set("fdbck", -params:get("fdbck"))
      else
        params:delta("fdbck", delta)
      end
    end
  elseif sel == 4 then
    if n == 2 or n == 3 then
      if shift then delta = delta / 100 end
      params:delta("in_amp", delta)
    end
  elseif sel == 5 then
    if n == 2 or n == 3 then
      if shift then delta = delta / 100 end
      params:delta("rev_level", delta)
    end
  end

  redraw()
end

