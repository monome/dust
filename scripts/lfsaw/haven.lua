-- haven.
-- lots of feedback
--

engine.name = 'Haven'

local sel = 1

function init()
  params:add{
    type="control",
    id="freq1",
    controlspec=controlspec.new(10, 200, "exp", 0, 20, "hz"),
    action=engine.freq1,
  }

  params:add{
    type="control",
    id="freq2",
    controlspec=controlspec.new(1000, 12000, "exp", 0, 4000, "hz"),
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
  screen.font_size(8)
  screen.level(15)

  screen.level(sel == 1 and 15 or 4)
  screen.move(0, 8)
  screen.text(params:string("freq1"))

  screen.level(3)
  screen.move(0, 16)
  screen.text("lo freq")

  screen.level(sel == 1 and 15 or 4)
  screen.move(64, 8)
  screen.text(params:string("amp1"))

  screen.level(3)
  screen.move(64, 16)
  screen.text("amp")

  screen.level(sel == 2 and 15 or 4)
  screen.move(0, 32)
  screen.text(params:string("freq2"))

  screen.level(3)
  screen.move(0, 40)
  screen.text("hi freq")

  screen.level(sel == 2 and 15 or 4)
  screen.move(64, 32)
  screen.text(params:string("amp2"))

  screen.level(3)
  screen.move(64, 40)
  screen.text("amp")

  screen.level(sel == 3 and 15 or 4)
  screen.move(0, 56)
  screen.text(params:string("fdbck"))

  screen.level(3)
  screen.move(0, 64)
  screen.text("fdbck")

  screen.level(sel == 3 and 15 or 4)
  screen.move(64, 56)
  screen.text(params:string("in_amp"))

  screen.level(3)
  screen.move(64, 64)
  screen.text("in")

  screen.move(128, 8)
  screen.text_right("haven")

  screen.update()
end


function key(n, z)
  if n == 2 and z == 1 then
    sel = sel + 1
    if sel > 3 then sel = 1 end
    redraw()
  end
end

function enc(n, delta)
  if n == 1 then mix:delta("output", delta) end

  if sel == 1 then
    if n == 2 then params:delta("freq1", delta) end
    if n == 3 then params:delta("amp1", delta) end
  elseif sel == 2 then
    if n == 2 then params:delta("freq2", delta) end
    if n == 3 then params:delta("amp2", delta) end
  elseif sel == 3 then
    if n == 2 then params:delta("fdbck", delta) end
    if n == 3 then params:delta("in_amp", delta) end
  end

  redraw()
end

