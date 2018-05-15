SynthDef.new(\shapeosc, {
	arg in, out=0, amp=0.125, hz=220,

	shape_buf_a, shape_buf_b,
	shape_select=0,

	hz_lag=0.01, shape_lag=0.01,

	osc_amp=1, osc_amp_atk=0.001, osc_amp_rel=0.01,
	in_amp=1, in_amp_atk=0.001, in_amp_rel=0.01,
	ring_amp=0, ring_amp_atk=0.001, ring_amp_rel=0.01,
	amp_atk=0.001, amp_rel=0.01,

	var snd, osc, ring, input;
	var shape_a, shape_b;
	var ring_env;

	shape_select = Lag.kr(shape_select, shape_lag);
	hz = Lag.kr(hz, hz_lag);

	osc = SinOsc.ar(hz);
	shape_a = Shaper.ar(shape_buf_a, snd);
	shape_b = Shaper.ar(shape_buf_b, snd);
	osc = SelectX.ar(shape_select, [shape_a, shape_b]);

	osc_env = LagUD.kr(osc_amp, osc_amp_atk, osc_amp_rel);
	in_env = LagUD.kr(in_amp, in_amp_atk, in_amp_rel);
	ring_env = LagUD.kr(ring_amp, ring_amp_atk, ring_amp_rel);
	amp_env = LagUD.kr(amp, amp_atk, amp_rel);

	input = In.ar(in);
	ring = snd * input;
	snd =

	Out.ar(out, amp_env * (snd + (ring_env * snd.ring1(In.ar(in)))));

}).send(s);