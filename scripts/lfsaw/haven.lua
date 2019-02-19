-- haven.
--
-- a safe space?
--

engine.name = "Haven"

local sel = 1
local shift = false
local fdbckSign = 1

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
    id="fdbckSign",
    controlspec=controlspec.new(-1, 1, "linear", 1, 1, ""),
	  action=engine.fdbckSign,
  }

  params:add{
    type="control",
    id="fdbck",
    controlspec=controlspec.new(0, 1, "linear", 0, 0, ""),
	  action=engine.fdbck,
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
  if params:string("amp1") == "-90.0 dB" then
    screen.text("lo: "..params:string("freq1").."  *  -inf dB")
  else
    screen.text("lo: "..params:string("freq1").."  *  "..params:string("amp1"))
  end
  screen.level(sel == 2 and 15 or 2)
  screen.move(8, 24)
  if params:string("amp2") == "-90.0 dB" then
    screen.text("hi: "..params:string("freq2").."  *  -inf dB")
  else
    screen.text("hi: "..params:string("freq2").."  *  "..params:string("amp2"))
  end
  screen.level(sel == 3 and 15 or 2)
  screen.move(8, 32)
  if fdbckSign == 1 then
    screen.text("fdbck: "..params:string("fdbck"))
  else
    screen.text("fdbck: -"..params:string("fdbck"))
  end    
  screen.level(sel == 4 and 15 or 2)
  screen.move(8, 40)
  if params:string("in_amp") == "-90.0 dB" then
    screen.text("in: -inf dB")
  else
    screen.text("in: "..params:string("in_amp"))
  end
  
  screen.level(sel == 5 and 15 or 2)
  screen.move(8, 48)
  screen.text("reverb: "..params:string("rev_level"))

  screen.update()
end


function key(n, z)
  if n == 2 and z == 1 then
  	-- use shift to move up, else down in selection
    if shift then
	    sel = sel - 1
	  else
		  sel = sel +1
	  end
    -- wrap cycle around
    sel = ((sel-1) % 5) + 1
    redraw()
  end
  
  if n == 3 then
    shift = (z == 1)
	  if sel == 3 and z == 1 then
		  -- toggle feedbackSign
  	  fdbckSign = fdbckSign * -1
	    engine.fdbckSign(fdbckSign)
      redraw()
	  end
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