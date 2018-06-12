Engine_Gong : CroneGenEngine {
	classvar numOscs = 3;

	// TODO: not used atm *polyphony { ^6 }

	*ugenGraphFunc {
		^{
			arg
				out,
				gate,
				freq,
				timbre,
				timemod,
				osc1gain,
				osc1partial,
				// TODO osc1partialdetune,
				osc1fixed,
				osc1fixedfreq,
				osc1index,
				osc1outlevel,
				osc1_to_osc1freq,
				osc1_to_osc2freq,
				osc1_to_osc3freq,
				osc2gain,
				osc2partial,
				osc2fixed,
				osc2fixedfreq,
				osc2index,
				osc2outlevel,
				osc2_to_osc1freq,
				osc2_to_osc2freq,
				osc2_to_osc3freq,
				osc3gain,
				osc3partial,
				osc3fixed,
				osc3fixedfreq,
				osc3index,
				osc3outlevel,
				osc3_to_osc3freq,
				osc3_to_osc2freq,
				osc3_to_osc1freq,
				lpfcutoff,
				lpfres,
				hpfcutoff,
				hpfres,
				ampgain,
				lforate,
				lfo_to_lpfcutoff,
				lfo_to_lpfres,
				lfo_to_hpfcutoff,
				lfo_to_hpfres,
				lfo_to_ampgain,
				lfo_to_osc1freq,
				lfo_to_osc2freq,
				lfo_to_osc3freq,
				envattack,
				envdecay,
				envsustain,
				envrelease,
				env_to_osc1freq,
				env_to_osc1gain,
				env_to_osc2freq,
				env_to_osc2gain,
				env_to_osc3freq,
				env_to_osc3gain,
				env_to_lpfcutoff,
				env_to_lpfres,
				env_to_hpfcutoff,
				env_to_hpfres,
				env_to_ampgain
/*
	TODO
				amp_env0,
				amp_env1,
				pitch_trk0,
				pitch_trk1,
				ampenv_to_osc1freq,
				ampenv_to_osc2freq,
				ampenv_to_osc3freq,
				pitchenv_to_osc1freq,
				pitchenv_to_osc2freq,
				pitchenv_to_osc3freq
*/
			;
			var env = EnvGen.ar(Env.adsr((envattack*timemod).clip(0, 5000)/1000, (envdecay*timemod).clip(0, 5000)/1000, envsustain, (envrelease*timemod).clip(0, 5000)/1000), gate); // TODO: clip?
			var oscfeedback = LocalIn.ar(3);
			var osc1;
			var osc2;
			var osc3;
			var freqSpec = ControlSpec(20, 10000, 'exp', 0, 440, " Hz");
			var rqSpec = \rq.asSpec;
			var lfo = SinOsc.ar((lforate*timemod).clip(0.125, 8)); // TODO: clip?
			var hpfrq = rqSpec.map(1-(hpfres + (env * env_to_hpfres) + (lfo * lfo_to_hpfres)));
			var lpfrq = rqSpec.map(1-(lpfres + (env * env_to_lpfres) + (lfo * lfo_to_lpfres)));
			var sig;

			var osc1freq, osc2freq, osc3freq;

			osc1freq = Select.kr(osc1fixed, [freq*osc1partial, osc1fixedfreq]);
			osc2freq = Select.kr(osc2fixed, [freq*osc2partial, osc2fixedfreq]);
			osc3freq = Select.kr(osc3fixed, [freq*osc3partial, osc3fixedfreq]);

			osc1index = osc1index * timbre;
			osc2index = osc2index * timbre;
			osc3index = osc3index * timbre;

			osc1 = SinOsc.ar(
				osc1freq
					+ (oscfeedback[0] * osc1freq * osc1_to_osc1freq * osc1index) // TODO: moving index multiplication is likely more optimal
					+ (oscfeedback[1] * osc1freq * osc2_to_osc1freq * osc1index)
					+ (oscfeedback[2] * osc1freq * osc3_to_osc1freq * osc1index)
					+ (env * osc1freq * env_to_osc1freq * osc1index)
					+ (lfo * osc1freq * lfo_to_osc1freq * osc1index)
			) * (osc1gain + (env_to_osc1gain * env));

			osc2 = SinOsc.ar(
				osc2freq
					+ (osc1 * osc2freq * osc1_to_osc2freq * osc2index) // TODO: moving index multiplication is likely more optimal
					+ (oscfeedback[1] * osc2freq * osc2_to_osc2freq * osc2index)
					+ (oscfeedback[2] * osc2freq * osc3_to_osc2freq * osc2index)
					+ (env * osc2freq * env_to_osc2freq * osc2index)
					+ (lfo * osc2freq * lfo_to_osc2freq * osc1index)
			) * (osc2gain + (env_to_osc2gain * env));

			osc3 = SinOsc.ar(
				osc3freq
					+ (osc1 * osc3freq * osc1_to_osc3freq * osc3index) // TODO: moving index multiplication is likely more optimal
					+ (osc2 * osc3freq * osc2_to_osc3freq * osc3index)
					+ (oscfeedback[2] * osc3freq * osc3_to_osc3freq * osc3index)
					+ (env * osc3freq * env_to_osc3freq * osc3index)
					+ (lfo * osc3freq * lfo_to_osc3freq * osc1index)
			) * (osc3gain + (env_to_osc3gain * env));

			sig = (osc1 * osc1outlevel) + (osc2 * osc2outlevel) + (osc3 * osc3outlevel);

			sig = RHPF.ar(
				sig,
				freqSpec.map(freqSpec.unmap(hpfcutoff) + (env * env_to_hpfcutoff) + (lfo * lfo_to_hpfcutoff)),
				hpfrq
			);

			sig = RLPF.ar(
				sig,
				freqSpec.map(freqSpec.unmap(lpfcutoff) + (env * env_to_lpfcutoff) + (lfo * lfo_to_lpfcutoff)),
				lpfrq
			);

			sig = sig * (ampgain + (env * env_to_ampgain) + (lfo * lfo_to_ampgain)).clip(0, 1);
			LocalOut.ar([osc1, osc2, osc3]);
			Out.ar(out, sig ! 2); // TODO: stereo output?
		}
	}

    *specs {
		var sp;

		sp = sp.add("timbre" -> ControlSpec(0, 5, 'lin', nil, 1, ""));
		sp = sp.add("timemod" -> ControlSpec(1, 5, 'lin', nil, 1, ""));

		numOscs.do { |oscnum|
			sp = sp.addAll(
				[
					"osc%gain".format(oscnum+1) -> \amp.asSpec,
					"osc%partial".format(oscnum+1) -> ControlSpec(0.5, 12, 'lin', 0.5, 1, ""),
					"osc%fixed".format(oscnum+1) -> ControlSpec(0, 1, 'lin', 1, 0, ""),
					"osc%fixedfreq".format(oscnum+1) -> \widefreq.asSpec,
					"osc%index".format(oscnum+1) -> ControlSpec(0, 24, 'lin', 0, 3, ""),
					"osc%outlevel".format(oscnum+1) -> \amp.asSpec,
					"env_to_osc%freq".format(oscnum+1) -> \bipolar.asSpec,
					"env_to_osc%gain".format(oscnum+1) -> \bipolar.asSpec,
					"lfo_to_osc%freq".format(oscnum+1) -> \bipolar.asSpec,
				]
			);
			numOscs.do { |dest|
				sp = sp.add(
					"osc%_to_osc%freq".format(oscnum+1, dest+1) -> \amp.asSpec
				);
			};
		};
		sp = sp.addAll(
			[
				'lpfcutoff' -> ControlSpec(20, 10000, 'exp', 0, 10000, "Hz"),
				'lpfres' -> \unipolar.asSpec,
				'hpfcutoff' -> ControlSpec(1, 10000, 'exp', 0, 1, "Hz"),
				'hpfres' -> \unipolar.asSpec,
				'ampgain' -> \amp.asSpec,
				'lforate' -> ControlSpec(0.125, 8, 'exp', 0, 1, "Hz"), // TODO \rate.asSpec,
				'lfo_to_lpfcutoff' -> \bipolar.asSpec,
				'lfo_to_lpfres' -> \bipolar.asSpec,
				'lfo_to_hpfcutoff' -> \bipolar.asSpec,
				'lfo_to_hpfres' -> \bipolar.asSpec,
				'lfo_to_ampgain' -> \bipolar.asSpec,
				'gate' -> \unipolar.asSpec,
				'envattack' -> ControlSpec(0, 5000, 'lin', 0, 5, "ms"),
				'envdecay' -> ControlSpec(0, 5000, 'lin', 0, 400, "ms"),
				'envsustain' -> ControlSpec(0, 1, 'lin', 0, 0.5, ""),
				'envrelease' -> ControlSpec(0, 5000, 'lin', 0, 400, "ms"),
				'env_to_lpfcutoff' -> \bipolar.asSpec,
				'env_to_lpfres' -> \bipolar.asSpec,
				'env_to_hpfcutoff' -> \bipolar.asSpec,
				'env_to_hpfres' -> \bipolar.asSpec,
				'env_to_ampgain' -> \bipolar.asSpec,
			]
		);

		sp = sp.collect { |assoc|
			assoc.key.asSymbol -> assoc.value
		};
		// sp.collect{ |assoc| assoc.key}.debug(\debug);

		sp = sp.asDict;

		^sp;
    }

	*synthDef { // TODO: remove, this is just due to wrapping of out not working right atm
		^SynthDef(
			\abcd,
			this.ugenGraphFunc,
			metadata: (specs: this.specs)
		)
	}
}

