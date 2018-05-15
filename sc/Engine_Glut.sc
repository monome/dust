
Engine_Glut : CroneEngine {
	classvar nvoices = 7;

	var effect;
	var <buf;
	var <voices;
	var mixBus;
	var <phases;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	// disk read
	readBuf { arg i, path;
		if(buf[i].notNil, {
			if (File.exists(path), {
				var newbuf = Buffer.readChannel(context.server, path, 0, -1, [0], {
					voices[i].set(\buf, newbuf);
					buf[i].free;
					buf[i] = newbuf;
				});
			});
		});
	}

	alloc {
		buf = Array.fill(nvoices, { arg i;
			Buffer.alloc(
				context.server,
				context.server.sampleRate * 1,
			);
		});

		SynthDef(\synth, {
			arg out, phase_out, buf, gate=0, pos=0, speed=1,
			jitter=0, size=0.1, density=20, pitch=1, spread=0, gain=1,
			envscale=1, t_playhead=0;

			var grain_trig;
			var jitter_sig;
			var pan_sig;
			var buf_pos;
			var pos_sig;
			var sig;

			var env;
			var level;

			grain_trig = Impulse.kr(density);

			pan_sig = TRand.kr(lo: spread.neg, hi: spread, trig: grain_trig);
			// TODO: this should probably be expressed in units
			jitter_sig = TRand.kr(lo: jitter.neg, hi: jitter, trig: grain_trig);

			buf_pos = Phasor.kr(trig: t_playhead,
				rate: BufDur.kr(buf).reciprocal / ControlRate.ir * speed,
				resetPos: pos);

			pos_sig = Wrap.kr(buf_pos + jitter_sig);
			sig = GrainBuf.ar(2, grain_trig, size, buf, pitch, pos_sig, 2, pan_sig, -1);
			env = EnvGen.kr(Env.asr(1, 1, 1, -2), gate: gate, timeScale: envscale);

			Out.ar(out, sig * env * gain);
			Out.kr(phase_out, buf_pos);
		}).add;

		SynthDef(\effect, {
			arg in, out, mix=0.5, room=0.5, damp=0.5;
			var sig = In.ar(in, 2);
			sig = FreeVerb.ar(sig, mix, room, damp);
			Out.ar(out, sig);
		}).add;

		context.server.sync;

		// mix bus for all synth outputs
		mixBus =  Bus.audio(context.server, 2);

		effect = Synth.new(\effect, [\in, mixBus.index, \out, context.out_b.index]);

		phases = Array.fill(nvoices, { arg i;
			Bus.control(context.server);
		});

		voices = Array.fill(nvoices, { arg i;
			Synth.new(\synth, [
				\out, mixBus.index,
				\phase_out, phases[i].index,
				\buf, buf[i],
			]);
		});

		context.server.sync;

		this.addCommand("reverb_mix", "f", { arg msg; effect.set(\mix, msg[1]); });

		this.addCommand("reverb_room", "f", { arg msg; effect.set(\room, msg[1]); });

		this.addCommand("reverb_damp", "f", { arg msg; effect.set(\damp, msg[1]); });

		this.addCommand("read", "is", { arg msg;
			this.readBuf(msg[1] - 1, msg[2]);
		});

		this.addCommand("seek", "if", { arg msg;
			var voice = msg[1] - 1;

			voices[voice].set(\pos, msg[2]);
			voices[voice].set(\t_playhead, 1);
		});

		this.addCommand("gate", "ii", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\gate, msg[2]);
		});

		this.addCommand("speed", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\speed, msg[2]);
		});

		this.addCommand("jitter", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\jitter, msg[2]);
		});

		this.addCommand("size", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\size, msg[2]);
		});

		this.addCommand("density", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\density, msg[2]);
		});

		this.addCommand("pitch", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\pitch, msg[2]);
		});

		this.addCommand("spread", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\spread, msg[2]);
		});

		this.addCommand("volume", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\gain, msg[2]);
		});

		this.addCommand("envscale", "if", { arg msg;
			var voice = msg[1] - 1;
			voices[voice].set(\envscale, msg[2]);
		});

		nvoices.do({ arg i;
			this.addPoll(("phase_" ++ (i+1)).asSymbol, {
				var val = phases[i].getSynchronous;
				val
			});
		});
	}

	free {
		voices.do({ arg voice; voice.free; });
		phases.do({ arg phase; phase.free; });
		buf.do({ arg b; b.free; });
		effect.free;
		mixBus.free;
		super.free;
	}
}
