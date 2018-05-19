Routine {
	s = Crone.server;
	c = Crone.ctx;

	SynthDef.new(\faust_comp, { arg in1, in2, out,
		bypass= 0, ratio= 4, threshold= -30, attack= 5, release= 50, makeup_gain= 18;
		var snd = FaustCompressor.ar(In.ar(in1), In.ar(in2),
			bypass, ratio, threshold, attack, release, makeup_gain);
		Out.ar(out, snd);
	}).send(s);

	
	SynthDef.new(\faust_verb, { arg in1, in2, out,
		in_delay= 60.0, lf_x= 200.0, low_rt60= 3.0, mid_rt60= 2.0, hf_damping= 6000.0, eq1_freq= 315.0, eq1_level= 0.0, eq2_freq= 1500.0, eq2_level= 0.0, dry_wet_mix= 0.0, level= -20.0;
		Out.ar(out, FaustZitaRev.ar(In.ar(in1), In.ar(in2),
			in_delay, lf_x, low_rt60, mid_rt60, hf_damping, eq1_freq, eq1_level, eq2_freq, eq2_level, dry_wet_mix, level));
	}).send(s);

	b = Bus.audio(s, 2);
	
	
	s.sync;

	p = Array.fill(2, { |i| Synth.new(\patch_pan, [\in, c.in_b[i].index, \out, b.index], c.ig, \addAfter); });


	
	x = Synth.new(\faust_comp, [
		\out, b.index,
		\in1, c.in_b[0].index,
		\in2, c.in_b[1].index
	], target:c.xg);

	y = Synth.new(\faust_verb, [
		\out, c.out_b.index,
		\in1, b.index,
		\in2, b.index + 1y
	], target:c.xg, addAction:\addToTail);

}.play;