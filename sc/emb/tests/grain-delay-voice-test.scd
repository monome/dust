s = Crone.server;
c = Crone.ctx;

s.postln;
c.postln;
c.out_b.postln;


v = GrainDelayVoice.new(s, c.in_b[0].index, c.out_b.index, c.xg);

v.grain_trig_b.set(1);
v.sync_trig_b.set(1);
