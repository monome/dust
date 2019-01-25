/*
2018, Till Bovermann
http://tai-studio.org


*/

Engine_Haven : CroneGenEngine {
	*rotate {|in, pos = 0.0|
		^Rotate2.ar(in[0], in[1], pos)
	}

	*ugenGraphFunc {
		^{|in = 0, out = 0, freq1, freq2, amp1, amp2, inAmp, fdbck, fdbckSign|

			var freqs, freqRange = 0.85;
			var inputs, oscAmps;
			var dyns, dynIns;
			var xxx, snd, lIns;

			// combine fdbck with its sign
			fdbck = fdbck.varlag(0.3) * fdbckSign.lag(SampleRate.ir * 0.5);

			lIns = LocalIn.ar(2);
			inputs = (In.ar(in, 2) * inAmp);
			dynIns = Amplitude.ar(inputs, 0.1, 0.1);

			// magic (>:)
			xxx = Limiter.ar(
				CombL.ar(
					lIns + inputs,
					0.5,
					(LFNoise1.ar(0.1, 0.5, 0.5) + dynIns).tanh * 0.5,
					-10
				)
			);

			dyns = Impulse.ar(0).lag(0.001, 0.1)
			+ Amplitude.ar(
				in: xxx.reverse,
				attackTime: LFNoise1.kr(dynIns[0].lag(1) * 0.1).abs * 5,
				releaseTime: LFNoise1.kr(dynIns[0].lag(3) * 0.5).abs * 15
			);

			freqs = [freq1, freq2].varlag(0.5);
			freqs = freqs -
			(
				dyns.lag(0.003235246).abs
				* (
					(freqRange * freqs)
				)
			);

			oscAmps = [amp1, amp2].lag(0.2) * AmpCompA.kr(freqs);
			snd = SinOscFB.ar(
				freq: freqs,
				feedback: (dyns * [2, 1.1]).fold(0, [1.5, 1.9])
			) * oscAmps * 4;

			// mix
			snd = (inputs + snd).tanh;

			// amp modulation
			snd = snd * SinOsc.ar(
				0.01 + dyns.varlag(20, 20),
				{Rand()}!2
			) * LFTri.ar(
				(1-dyns.lag([1, 1.2])) * 20,
				{Rand()}!2
			);

			//stereo rotate
			sbd = this.rotate(
				in: snd,
				pos: (dynIns + LFSaw.kr(0.001))%1 // (2, 2)
			);

			snd = (fdbck * xxx) // feedback
			+ snd;

			// collapse to stereo
			snd = snd.sum;
			snd = LeakDC.ar(snd);

			LocalOut.ar(snd);

			snd = snd - (0.5 * MoogLadder.ar(this.rotate(snd, dyns.sum.lag(0.01)), ffreq: (1-dyns.lag(0, 10)) * 1100 + 50, res: 0.2));
			snd = snd.tanh;

			Out.ar(out, snd);
			// snd.tanh
		}
	}

	*specs {
		^(
			\freq1: [1, 800, \exp, 0.0, 20].asSpec,
			\freq2: [400, 12000, \exp, 0.0, 4000, "Hz"].asSpec,
			\amp1: [0, 1, \linear, 0.0, 0, ""].asSpec,
			\amp2: [0, 1, \linear, 0.0, 0, ""].asSpec,
			\inAmp: [0, 1, \linear, 0.0, 0, ""].asSpec,
			\fdbck: [0, 1, \linear, 0.0, 0.03, ""].asSpec,
			\fdbckSign: [-1, 1, \linear, 1, 0, ""].asSpec
		)
	}

	*synthDef { // TODO: move ugenGraphFunc to here...
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