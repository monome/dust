engine.name = 'SoftCut'

init = function()
   path = "/home/emb/snd/test.wav"
   channels, frames, samplerate = sound_file_inspect(path)
   print(path, channels, frames, samplerate)
end
