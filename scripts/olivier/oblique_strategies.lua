-- OBLIQUE STRATEGIES
-- Brian Eno & Peter Schmidt
--
-- KEY 3 / Random strategy
-- KEY 2 / Random cutoff value
-- ENC 3 / Linear strategy scroll
-- ENC 1,2 / Clear screen

engine.name = 'PolyPerc'

-- SET DEFAULT VARIABLES/VALUES + INITIALIZE STRATEGIES TABLE
function init()
  position = 1
  f = 1000
  engine.hz(0)
  engine.amp(0)
  mode = 2
  oblique = {}
  oblique[1] = {"1","Accept advice"}
  oblique[2] = {"2","Abandon normal instruments"}
  oblique[3] = {"3","A line has two sides"}
  oblique[4] = {"4","Breathe more deeply"}
  oblique[5] = {"5","Cluster analysis"}
  oblique[6] = {"6","Cascades"}
  oblique[7] = {"7","Use an old idea"}
  oblique[8] = {"8","Cut a vital connection"}
  oblique[9] = {"9","Think of the radio"}
  oblique[10] = {"10","Fill every beat with something"}
  oblique[11] = {"11","How would you have done it?"}
  oblique[12] = {"12","Disconnect from desire"}
  oblique[13] = {"13","Infinitesimal gradations"}
  oblique[14] = {"14","Work at a different speed"}
  oblique[15] = {"15","You are an engineer"}
  oblique[16] = {"16","Emphasize differences"}
  oblique[17] = {"17","Reverse"}
  oblique[18] = {"18","The tape is now the music"}
  oblique[19] = {"19","Trust in the you of now"}
  oblique[20] = {"20","Use an unacceptable color"}
  oblique[21] = {"21","Ghost echoes"}
  oblique[22] = {"22","Get your neck massaged"}
  oblique[23] = {"23","Don't be frightened of cliches"}
  oblique[24] = {"24","Decorate, decorate"}
  oblique[25] = {"25","Simple subtraction"}
  oblique[26] = {"26","Put in earplugs"}
  oblique[27] = {"27","Distorting time"}
  oblique[28] = {"28","Ask your body"}
  oblique[29] = {"29","Bridges -build -burn"}
  oblique[30] = {"30","The inconsistency principle"}
end

-- GENERATE SCALE
local scale = {
  1/8, 1/6, 1/5, 1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 5/6, 7/8
}

function redraw()
  -- RETRIEVE/DISPLAY RANDOM STRATEGY FROM TABLE
  if mode == 0 then
    screen.clear()
    screen.level(15)
    screen.move(0,30)
    screen.text(oblique[math.random(30)][2])
  end
  -- ORGANIZE SEQUENTIAL DISPLAY OF TABLE VALUES
  if mode == 1 then
    screen.clear()
    screen.level(15)
    screen.move(0,30)
    screen.text(oblique[position][2])
    screen.move(0,40)
    screen.level(1)
    screen.text(oblique[position][1] .. "/" .. #oblique)
  end
  if mode == 2 then
    screen.clear()
  end
  screen.update()
end

function enc(n,d)
  -- USE ENC 3 TO SEQUENTIALLY SCROLL THROUGH STRATEGIES 
  if n == 3 then
    mode = 1
    position = position + d
    if position > 30 then
      position = 30
    end
    if position < 1 then
      position = 1
    end
  end
  redraw()
  -- USE ENC 1 OR 2 TO CLEAR SCREEN
  if n == 1 or n == 2 then
    d = 0
    mode = 2
  end
end

function key(n,z)
  -- USE KEY 3 TO DISPLAY RANDOM STRATEGY
  if n == 3 and z == 1 then
    mode = 0
    engine.hz(f * scale[math.random(13)])
    engine.release(math.random(5))
    engine.amp(0.5)
    engine.pw(math.random(100)/100)
    redraw()
  end
  if n == 2 then
    engine.cutoff(1000*(math.random(20)))
  end
end
