s = Crone.server;
c = Crone.ctx;

s.postln;
c.postln;
c.out_b.postln;


v = GrainDelayVoice.new(s, c.out_b.index, c.xg);
p = Synth.new(\patch_mono, [\in, c.in_b[0].index, \out, v.in_b.index], target:c.ig, addAction:\addAfter);
v.grain_trig_b.set(1);
v.sync_trig_b.set(1);
