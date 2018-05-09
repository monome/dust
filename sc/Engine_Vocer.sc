Engine_Vocer : CroneEngine {
	classvar <nvoices = 7;
	classvar <fftSize = 2048;
	var <voices;
	var <pm;
	var <mixBus;
	var <outPatch;
	
	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		var s = context.server;

		SynthDef(\vocer, {
			arg buf, in, out, amp, gate, shift, scale, freeze=0,			
			noise=0.0, osc=0.0, phaseamp=1.0,
			hz=27, atk=0.01, rel=0.01, pan=0.0;
			var snd, chain, aenv;
			snd = In.ar(in);
			// FIXME: do some kinda phase replacement.
			//snd = SelectX.ar(freeze, [snd, WhiteNoise.ar*noise + Saw.ar(hz)*osc]);
			chain = FFT(buf, snd);
			chain = PV_MagFreeze(chain, freeze);
			chain = PV_MagScale(chain, scale);
			chain = PV_MagShift(chain, shift);
			aenv = EnvGen.kr(Env.asr(atk, 1, rel), gate:gate);
			Out.ar(out, Pan2.ar(IFFT(chain), pan, amp * aenv));
		}).add;


		mixBus = Bus.audio(s, 2);
		outPatch = Synth.new(\patch_stereo, [\in, mixBus.index, \out, context.out_b.index],
			target:context.og, addAction:\addBefore);
		
		voices = Array.fill(nvoices, { arg i;
			var in_bus = Bus.audio(s, 1);
			var buf= Buffer.alloc(s, fftSize);
			var synth = Synth.new(\vocer, [\buf, buf, \in, in_bus, \out, mixBus], context.xg);
			(\in_bus:in_bus, \buf: buf, \synth:synth)
		});

		pm = Event.new;
		pm.adc_voc = PatchMatrix.new(
			server:s, target:context.ig, action:\addAfter,
			in: Array.fill(2, {|i| context.in_b[i].index}),
			out: voices.collect({|v| v.in_bus.index}),
			feedback:true
		);
		
		#[\, \gate, \shift, \scale, \freeze, \pan].do({
			arg name;
			this.addCommand(name, "if", {
				arg msg;
				var i = msg[1] -1;
				if(i<nvoices && i >= 0, { 
					voices[msg[1]].synth.set(name, msg[2]);
				});
			});
		});
		
		pm.do({ |k, m| m.addLevelCommand(this, k); });

		nvoices.do({ |i|
			pm.adc_voc.level_(0, i, 0.5);
			pm.adc_voc.level_(1, i, 0.5);
		});
			
	}

	free {
		voices.do({ |v| v.buf.free; v.synth.free; });
		pm.do({ |k, m| m.free; });
		super.free;
	}
}