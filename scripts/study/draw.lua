-- draw demo
--
-- code shows all of the screen
-- drawing functions

-- specify dsp engine to load:
--engine.name = 'TestSine'

function init()
  -- enable anti-alasing
  screen.aa(1)
end

-- screen redraw function
function redraw()
  -- clear screen
  screen.clear()
  -- set pixel brightness (0-15)
  screen.level(15)
  -- set line width
  screen.line_width(1.0)
  -- move position
  screen.move(0,0)
  -- draw line
  screen.line(10,20)
  -- stroke line
  screen.stroke()
  -- draw arc: x-center, y-center, radius, angle1, angle2
  screen.arc(20,0,10,0,math.pi*0.8)
  screen.stroke()
  -- draw rect: x,y,w,h
  screen.rect(30,10,15,20)
  screen.level(3)
  screen.stroke()
  -- draw curve
  screen.move(50,0)
  screen.curve(50,20,60,0,70,10)
  screen.level(15)
  screen.stroke()
  -- draw poly and fill
  screen.move(60,20)
  screen.line(80,10)
  screen.line(70,40)
  screen.close()
  screen.level(10)
  screen.fill()
  -- draw circle
  screen.circle(100,20,10)
  screen.stroke()


  screen.level(15)
  screen.move(0,63)
  -- set text face
  screen.font_face(9)
  -- set text size
  screen.font_size(20)
  -- draw text
  screen.text("new!")
  -- draw centered text
  screen.move(63,50)
  screen.font_face(0)
  screen.font_size(8)
  screen.text_center("center")
  -- draw right aligned text
  screen.move(127,63)
  screen.text_right("1992")

  screen.update()
end
