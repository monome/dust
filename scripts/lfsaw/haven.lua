-- haven.
-- lots of feedback
--

engine.name = 'Haven'

function init()
  k1 = false
  k2 = false

  params:add{
    type="control",
    id="freq1",
    controlspec=controlspec.new(10, 200, "exp", 0, 20, "Hz"),
    action=engine.freq1,
  }

  params:add{
    type="control",
    id="freq2",
    controlspec=controlspec.new(1000, 12000, "exp", 0, 4000, "Hz"),
    action=engine.freq2,
  }

  params:add{
    type="control",
    id="amp1",
    controlspec=controlspec.new(0, 1, "linear", 0, 0, ""),
    action=engine.amp1,
  }

  params:add{
    type="control",
    id="amp2",
    controlspec=controlspec.new(0, 1, "linear", 0, 0, ""),
    action=engine.amp2,
  }

  params:add{
    type="control",
    id="in_amp",
    controlspec=controlspec.new(0, 1, "linear", 0, 0, ""),
    action=engine.inAmp,
  }

  params:add{
    type="control",
    id="fdbck",
    controlspec=controlspec.new(-1, 1, "linear", 0, 0.03, ""),
    action=engine.fdbck,
  }
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(15)
  screen.text("haven.")
  screen.move(0, 24)
  screen.text("lo: "..params:string("freq1"))
  screen.move(100, 24)
  screen.text(params:string("amp1"))
  screen.move(0, 32)
  screen.text("hi: "..params:string("freq2"))
  screen.move(100, 32)
  screen.text(params:string("amp2"))
  screen.move(0, 40)
  screen.text("fdbck: "..params:string("fdbck"))
  screen.move(0, 48)
  screen.text("in: "..params:string("in_amp"))
  screen.update()
end


function key(n,z)
  if n == 2 then
    if z == 1 then
      k1 = true
    else
      k1 = false
    end
    elseif n == 3 then
    if z == 1 then
      k2 = true
    else
      k2 = false
    end
  end
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    if k1 then
      params:delta("freq1", delta)
    elseif k2 then
      params:delta("fdbck", delta)
    else
      params:delta("amp1", delta)
    end
    redraw()
  elseif n == 3 then
    if k1 then
      params:delta("freq2", delta)
    elseif k2 then
      params:delta("in_amp", delta)
    else
      params:delta("amp2", delta)
    end
    redraw()
  end
end

