/*
2018, Till Bovermann
http://tai-studio.org
*/

Engine_Haven : CroneGenEngine {
	*rotate {|in, pos = 0.0|
		^Rotate2.ar(in[0], in[1], pos)
	}

	*ugenGraphFunc {
		^{|in = 0, out = 0, freq1, freq2, amp1, amp2, inAmp, fdbck|

			var x, freq, snd, lIn, input, dyn2;
			var dyn, dynIn;

			fdbck = fdbck.varlag(0.3);
			freq = [freq1, freq2].varlag(0.5);

			lIn = LocalIn.ar(2);
			input = (In.ar(in, 2) * inAmp);
			dynIn = Amplitude.ar(input, 0.1, 0.1);
			x = Limiter.ar(
				CombL.ar(
					lIn,
					0.5,
					(LFNoise1.ar(0.1, 0.5, 0.5) + dynIn).tanh * 0.5,
					-10
				)
			);

			dyn = Impulse.ar(0).lag(0.001, 0.1) + Amplitude.ar(x.reverse, LFNoise1.kr(0.062).abs * 10, LFNoise2.kr(0.12362).abs * 15);

			snd =
			(fdbck * x) +
			this.rotate(
				SinOscFB.ar(
					freq: (freq) - (dyn.lag(0.003235246) * (freq - [0, 2])),
					feedback: (dyn).fold(0, 1.5),
					mul: SinOsc.ar(0.1 + dyn.lag(0, 10)) * (0.1 + dyn) * LFTri.ar(dyn.lag(0.04235) * 20 + 0.001) * 200
				).tanh
				* [amp1, amp2].lag(0.2),
				(dynIn + LFSaw.kr(0.001))%1
			);

			snd = LeakDC.ar(snd);


			LocalOut.ar(snd + input);

			snd = snd - (0.5 * MoogLadder.ar(this.rotate(snd, dyn.sum.lag(0.01)), ffreq: (1-dyn.lag(0, 10)) * 1100 + 50, res: 0.2));

			Out.ar(out, snd);
		}
	}

	*specs {
		^(
			freq1: ControlSpec(10, 200, \exp, default: 20, units: "Hz"),
			freq2: ControlSpec(1000, 12000, \exp, default: 4000, units: "Hz"),
			amp1: ControlSpec(0, 1, \lin, default: 0, units: ""),
			amp2: ControlSpec(0, 1, \lin, default: 0, units: ""),
			inAmp: ControlSpec(0, 1, \lin, default: 0, units: ""),
			fdbck: ControlSpec(-1, 1, \lin, default: 0.03, units: "")
		)
	}

	*synthDef { // TODO: remove, this is just due to wrapping of out not working right atm
		^SynthDef(
			\haven,
			this.ugenGraphFunc,
			metadata: (specs: this.specs)
		)
	}
}

/*

Engine_Haven.generateLuaEngineModuleSpecsSection
*/