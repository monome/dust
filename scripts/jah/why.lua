-- why.
-- classic supercollider example
-- by jmcc

engine.name = 'Why'

function init()
  redraw()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  end
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.move(0, 8)
  screen.text("Why?")
  screen.update()
end
