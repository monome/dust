SynthDef.new(\scape_osc, {
	arg in, out=0, amp=0.125, hz=220,

	shape_buf_a, shape_buf_b,
	shape_select=0,

	hz_lag=0.01, shape_lag=0.01,

	osc_amp=1, osc_amp_atk=0.001, osc_amp_rel=0.01,
	in_amp=1, in_amp_atk=0.001, in_amp_rel=0.01,
	ring_amp=0, ring_amp_atk=0.001, ring_amp_rel=0.01,
	amp_atk=0.001, amp_rel=0.01,
	in_delay=0.0, ring_delay = 0.0, pm_delay=0.0,
	pm_index=0.0, // input->osc phase modulation index

	cutoff=2200, res=0.1, lowpass=1, bandpass=0, highpass=0, notch=0, peak=0;

	var snd, osc, ring, input;
	var shape_a, shape_b;
	var osc_env, in_env, ring_env, amp_env;

	shape_select = Lag.kr(shape_select, shape_lag);
	hz = Lag.kr(hz, hz_lag);

	in_delay = in_delay.min(2.0);
	ring_delay = ring_delay.min(2.0);
	pm_delay = pm_delay.min(2.0);

	input = DelayL.ar(In.ar(in), 2.0, in_delay);
	osc = SinOsc.ar(hz, DelayL.ar((input * pm_index).mod(2pi), 2.0, pm_delay));
	ring = (osc * DelayL.ar(input, 2.0, ring_delay));


	osc_env = LagUD.ar(K2A.ar(osc_amp), osc_amp_atk, osc_amp_rel);
	in_env = LagUD.ar(K2A.ar(in_amp), in_amp_atk, in_amp_rel);
	ring_env = LagUD.ar(K2A.ar(ring_amp), ring_amp_atk, ring_amp_rel);
	amp_env = LagUD.ar(K2A.ar(amp), amp_atk, amp_rel);

	shape_a = Shaper.ar(shape_buf_a, osc);
	shape_b = Shaper.ar(shape_buf_b, osc);
	osc = SelectX.ar(shape_select, [shape_a, shape_b]);

	snd = (osc*osc_env) + (input*in_env) + (ring*ring_env);
	snd = SVF.ar(snd, cutoff, res, lowpass, bandpass, highpass, notch, peak);
	Out.ar(out, (snd * amp_env).dup);
}).send(s);


c = Crone.ctx;
c.in_b[0].scope;

~buf1 = Buffer.alloc(s, 512, 1, { |buf| buf.chebyMsg([1]); });
~buf2 = Buffer.alloc(s, 512, 1, { |buf| buf.chebyMsg(Array.geom(8, 1.0, -3.dbamp)); });

x = Synth.new(\scape_osc, [
	\in, c.in_b[0].index,
	\hz, 110,
	\shape_buf_a, ~buf1.bufnum,
	\shape_buf_b, ~buf2.bufnum,
	\in_amp, 0.0
], c.xg);


x.set(\shape_lag, 4.0);
x.set(\shape_select, 0.8);
x.set(\shape_select, 0.0);

x.set(\in_amp, 1.0);
x.set(\osc_amp, 0.0);
x.set(\ring_amp, 0.4);
x.set(\amp, 0.5);

x.set(\osc_amp, 0.2);
x.set(\pm_index, 2.0);
x.set(\pm_delay, 1.4);
x.set(\ring_delay, 1.8);
x.set(\ring_amp, 0.5);

x.set(\osc_amp, 0.2);
x.set(\bandpass, 0.2);

x.set(\cutoff, 330);
x.set(\res, 0.1);


// TODO: maybe split processing into separate synths, so that e.g. input can be routed through waveshaper, ring before shape, or &c

// c.out_b.scope;
