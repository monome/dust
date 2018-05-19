s = Crone.server;
c = Crone.ctx;
v = GrainDelayVoice.new(s, c.out_b.index, c.xg);

v.buf.plot
v.