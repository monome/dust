-- many tomorrows
-- norns study 1
--
-- KEY 2 toggle sound on/off
-- KEY 3 toggle octave
-- ENC 2 randomize amplitude
-- ENC 3 change frequency
--
-- first turn on AUX reverb!

engine.name = "TestSine"

function init()
  sound = 1
  level = 1
  octave =1
  f = 100
  position = 0
  engine.hz(f)
  print("the end and the beginning they are the same.")
end

function key(n,z)
  if n == 2 then
    if z == 1 then
      -- trick below to toggle between 0 and 1
      sound = 1 - sound
      engine.amp(sound * level)
    end
  elseif n == 3 then
    octave = z + 1
    engine.hz(octave * f)
  end
end

function enc(n,d)
  if n == 2 then
    level = math.random(100) / 100
    engine.amp(sound * level)
  elseif n == 3 then
    position = (position + d) % 11 
    f = 100 + position * 50
    engine.hz(octave * f)
  end
end