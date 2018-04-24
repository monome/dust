
Engine_Glut : CroneEngine {
	classvar nvoices = 4;

	var effect;
	var <buf;
	var <voices;
	var mixBus;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	// disk read
	readBuf { arg i, path;
		if(buf[i].notNil, {
			buf[i].readChannel(path, channels:[0]);
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
			arg out=context.out_b, sndbuf, gate=0, pos=0;
			var pos_sig;
			var sig;
			var env;

			pos_sig = Wrap.kr(LFNoise1.kr(freq: 50, mul: 0.15, add: pos));
			env = EnvGen.ar(Env.adsr(), gate: gate);

			sig = GrainBuf.ar(2,
				Impulse.kr(15), // trig
				0.25, //dur
				sndbuf,
				1, // rate
				pos_sig, // pos
				2, // interp
				0, -1);
			sig = sig * env;
			Out.ar(out, sig);
		}).add;

		SynthDef(\effect, {
			arg in, out, mix=0.66, room=1.0, damp=0.5;
			var sig = In.ar(in, 2);
			sig = FreeVerb.ar(sig, mix, room, damp);
			Out.ar(out, sig);
		}).add;

		context.server.sync;

		// mix bus for all synth outputs
		mixBus =  Bus.audio(context.server, 2);

		effect = Synth.new(\effect, [\in, mixBus.index, \out, context.out_b.index]);

		voices = Array.fill(nvoices, { |i|
			Synth.new(\synth, [\out, mixBus.index, \sndbuf, buf[i]]);
		});

		this.addCommand("read", "is", { arg msg;
			this.readBuf(msg[1] - 1, msg[2]);
		});

		this.addCommand("pos", "if", { arg msg;
			var voice = msg[1] - 1;
			var synth = voices[voice];

			synth.set(\pos, msg[2]);
		});

		this.addCommand("gate", "ii", { arg msg;
			var voice = msg[1] - 1;
			var synth = voices[voice];

			synth.set(\gate, msg[2]);
		});
	}

	free {
		super.free;
	}
}
