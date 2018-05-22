Engine_Ack : CroneEngine {
	var numChannels = 8;

	var <buffers;
	var <channelGroups;
	var <channelControlBusses;
	var <samplePlayerSynths;

	var effectsGroup;
	var delayBus;
	var reverbBus;
	var delaySynth;
	var reverbSynth;

	var loopEnabled;

	var channelSpecs;
	var filterCutoffSpec;

	var delayTimeSpec;
	var delayFeedbackSpec;
	var delayLevelSpec;

	var reverbRoomSpec;
	var reverbDampSpec;
	var reverbLevelSpec;

	*new { |context, callback| ^super.new(context, callback) }

	monoSamplePlayerDefName { ^(this.class.name.asString++"_Mono").asSymbol }
	stereoSamplePlayerDefName { ^(this.class.name.asString++"_Stereo").asSymbol }
	delayDefName { ^(this.class.name.asString++"_Delay").asSymbol }
	reverbDefName { ^(this.class.name.asString++"_Reverb").asSymbol }

	alloc {
		loopEnabled = Array.fill(8) { false };
		channelSpecs = IdentityDictionary.new;
		channelSpecs[\sampleStart] = \unipolar.asSpec;
		channelSpecs[\sampleEnd] = \unipolar.asSpec.copy.default_(1);
		channelSpecs[\loopPoint] = \unipolar.asSpec;
		channelSpecs[\speed] = ControlSpec(0, 5, default: 1);
		channelSpecs[\volume] = \db.asSpec.copy.default_(-10);
		channelSpecs[\delaySend] = \db.asSpec;
		channelSpecs[\reverbSend] = \db.asSpec;
		channelSpecs[\volumeEnvAttack] = ControlSpec(0, 1, default: 0.001, units: "secs");
		channelSpecs[\volumeEnvRelease] = ControlSpec(0, 3, default: 3, units: "secs");
		channelSpecs[\filterEnvAttack] = ControlSpec(0, 1, default: 0.001, units: "secs");
		channelSpecs[\filterEnvRelease] = ControlSpec(0, 3, default: 0.25, units: "secs");
		channelSpecs[\pan] = \pan.asSpec;
		channelSpecs[\filterCutoff] = \widefreq.asSpec.copy.default_(\widefreq.asSpec.maxval);
		filterCutoffSpec = channelSpecs[\filterCutoff];
		channelSpecs[\filterRes] = \unipolar.asSpec;
		channelSpecs[\filterLowpassLevel] = ControlSpec(0, 1, step: 1, default: 1);
		channelSpecs[\filterBandpassLevel] = ControlSpec(0, 1, step: 1, default: 0);
		channelSpecs[\filterHighpassLevel] = ControlSpec(0, 1, step: 1, default: 0);
		channelSpecs[\filterNotchLevel] = ControlSpec(0, 1, step: 1, default: 0);
		channelSpecs[\filterPeakLevel] = ControlSpec(0, 1, step: 1, default: 0);
		channelSpecs[\filterEnvMod] = \unipolar.asSpec;
		// TODO slewSpec = ControlSpec(0, 5, default: 0);

		delayTimeSpec = ControlSpec(0.0001, 5, 'exp', 0, 0.1, "secs");
		delayFeedbackSpec = ControlSpec(0, 1.25);
		delayLevelSpec = \db.asSpec.copy.default_(-10);

		reverbRoomSpec = \unipolar.asSpec.copy.default_(0.75);
		reverbDampSpec = \unipolar.asSpec.copy.default_(0.5);
		reverbLevelSpec = \db.asSpec.copy.default_(-10);

		SynthDef(
			(this.monoSamplePlayerDefName.asString++"_Sweep").asSymbol,
			{
				|
				gate,
				out=0,
				delayBus,
				reverbBus,
				bufnum,
				sampleStart,
				sampleEnd,
				loopPoint,
				speed,
				volume,
				volumeEnvAttack,
				volumeEnvRelease,
				pan,
				filterCutoff,
				filterRes,
				filterLowpassLevel,
				filterBandpassLevel,
				filterHighpassLevel,
				filterNotchLevel,
				filterPeakLevel,
				filterEnvAttack,
				filterEnvRelease,
				filterEnvMod,
				delaySend,
				reverbSend
				/*
				TODO
				speedSlew,
				phasorFreqSlew,
				volumeSlew,
				panSlew,
				filterCutoffSlew,
				filterResSlew,
				*/
				|
				var phase = sampleStart + Sweep.ar(1, speed * BufRateScale.kr(bufnum));
		
				var sig = BufRd.ar(1, bufnum, phase.linlin(0, 1, 0, BufFrames.kr(bufnum)), interpolation: 4); // TODO: tryout BLBufRd
		
				var freeEnv = EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
				var volumeEnv = EnvGen.ar(Env.perc(volumeEnvAttack, volumeEnvRelease), gate);
				var filterEnv = EnvGen.ar(Env.perc(filterEnvAttack, filterEnvRelease, filterEnvMod), gate);
		
				PauseSelf.kr(phase > sampleEnd);
				
				// sig = RLPF.ar(sig, filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv), filterRes);
				sig = SVF.ar(
					sig,
					\widefreq.asSpec.map(\widefreq.asSpec.unmap(filterCutoff)+filterEnv),
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel
				);
				sig = Pan2.ar(sig, pan); // Mono
				sig = sig * volumeEnv * freeEnv * volume.dbamp;
				Out.ar(out, sig);
				Out.ar(delayBus, sig*delaySend.dbamp);
				Out.ar(reverbBus, sig*reverbSend.dbamp);
			},
			// rates: [\tr],
			rates: [nil],
			metadata: (
				specs: (
					// gate: ControlSpec(0, 1, step: 1, default: 0),
					out: \audiobus,
					delayBus: \audiobus,
					reverbBus: \audiobus,
					bufnum: nil,
					sampleStart: channelSpecs[\sampleStart],
					sampleEnd: channelSpecs[\sampleEnd],
					speed: channelSpecs[\speed],
					volume: channelSpecs[\volume],
					volumeEnvAttack: channelSpecs[\volumeEnvAttack],
					volumeEnvRelease: channelSpecs[\volumeEnvRelease],
					pan: channelSpecs[\pan],
					filterCutoff: channelSpecs[\filterCutoff],
					filterRes: channelSpecs[\filterRes],
					filterEnvAttack: channelSpecs[\filterEnvAttack],
					filterEnvRelease: channelSpecs[\filterEnvRelease],
					filterEnvMod: channelSpecs[\filterEnvMod],
					delaySend: channelSpecs[\delaySend],
					reverbSend: channelSpecs[\reverbSend]
/*
	TODO
					speedSlew: slewSpec,
					phasorFreqSlew: slewSpec,
					volumeSlew: slewSpec,
					panSlew: slewSpec,
					filterCutoffSlew: slewSpec,
					filterResSlew: slewSpec,
*/
				)
			)
		).add;

		SynthDef(
			(this.monoSamplePlayerDefName.asString++"_OneShot").asSymbol,
			{
				|
					gate,
					out=0,
					delayBus,
					reverbBus,
					bufnum,
					sampleStart,
					sampleEnd,
					loopPoint,
					speed,
					volume,
					volumeEnvAttack,
					volumeEnvRelease,
					pan,
					filterCutoff,
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel,
					filterEnvAttack,
					filterEnvRelease,
					filterEnvMod,
					delaySend,
					reverbSend
/*
	TODO
					speedSlew,
					phasorFreqSlew,
					volumeSlew,
					panSlew,
					filterCutoffSlew,
					filterResSlew,
*/
				|
				var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * speed, 1);

				var freeEnv = EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
				var volumeEnv = EnvGen.ar(Env.perc(volumeEnvAttack, volumeEnvRelease), gate);
				var filterEnv = EnvGen.ar(Env.perc(filterEnvAttack, filterEnvRelease, filterEnvMod), gate);

				// sig = RLPF.ar(sig, filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv), filterRes);
				sig = SVF.ar(
					sig,
					filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv),
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel
				);
				sig = Pan2.ar(sig, pan); // Mono
				sig = sig * volumeEnv * freeEnv * volume.dbamp;
				Out.ar(out, sig);
				Out.ar(delayBus, sig*delaySend.dbamp);
				Out.ar(reverbBus, sig*reverbSend.dbamp);
			},
			// rates: [\tr],
			rates: [nil],
			metadata: (
				specs: (
					// gate: ControlSpec(0, 1, step: 1, default: 0),
					out: \audiobus,
					delayBus: \audiobus,
					reverbBus: \audiobus,
					bufnum: nil,
					sampleStart: channelSpecs[\sampleStart],
					sampleEnd: channelSpecs[\sampleEnd],
					speed: channelSpecs[\speed],
					volume: channelSpecs[\volume],
					volumeEnvAttack: channelSpecs[\volumeEnvAttack],
					volumeEnvRelease: channelSpecs[\volumeEnvRelease],
					pan: channelSpecs[\pan],
					filterCutoff: channelSpecs[\filterCutoff],
					filterRes: channelSpecs[\filterRes],
					filterEnvAttack: channelSpecs[\filterEnvAttack],
					filterEnvRelease: channelSpecs[\filterEnvRelease],
					filterEnvMod: channelSpecs[\filterEnvMod],
					delaySend: channelSpecs[\delaySend],
					reverbSend: channelSpecs[\reverbSend]
/*
	TODO
					speedSlew: slewSpec,
					phasorFreqSlew: slewSpec,
					volumeSlew: slewSpec,
					panSlew: slewSpec,
					filterCutoffSlew: slewSpec,
					filterResSlew: slewSpec,
*/
				)
			)
		).add;

		SynthDef(
			(this.monoSamplePlayerDefName.asString++"_Loop").asSymbol,
			{
				|
					gate,
					out=0,
					delayBus,
					reverbBus,
					bufnum,
					sampleStart,
					sampleEnd,
					loopPoint,
					speed,
					volume,
					volumeEnvAttack,
					volumeEnvRelease,
					pan,
					filterCutoff,
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel,
					filterEnvAttack,
					filterEnvRelease,
					filterEnvMod,
					delaySend,
					reverbSend
/*
	TODO
					speedSlew,
					phasorFreqSlew,
					volumeSlew,
					panSlew,
					filterCutoffSlew,
					filterResSlew,
*/
				|
				var bufFrames = BufFrames.kr(bufnum);
				var startPos = bufFrames * sampleStart;
				var endLoop = bufFrames * sampleEnd;
				var startLoop = startPos + ((endLoop-startPos)*loopPoint);
				var sig = LoopBuf.ar(1, bufnum, speed, 1, startPos, startLoop, endLoop, 4);

				var freeEnv = EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
				var volumeEnv = EnvGen.ar(Env.perc(volumeEnvAttack, volumeEnvRelease), gate);
				var filterEnv = EnvGen.ar(Env.perc(filterEnvAttack, filterEnvRelease, filterEnvMod), gate);

				// sig = RLPF.ar(sig, filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv), filterRes);
				sig = SVF.ar(
					sig,
					filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv),
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel
				);
				sig = Pan2.ar(sig, pan); // Mono
				sig = sig * volumeEnv * freeEnv * volume.dbamp;
				Out.ar(out, sig);
				Out.ar(delayBus, sig*delaySend.dbamp);
				Out.ar(reverbBus, sig*reverbSend.dbamp);
			},
			// rates: [\tr],
			rates: [nil],
			metadata: (
				specs: (
					// gate: ControlSpec(0, 1, step: 1, default: 0),
					out: \audiobus,
					delayBus: \audiobus,
					reverbBus: \audiobus,
					bufnum: nil,
					sampleStart: channelSpecs[\sampleStart],
					sampleEnd: channelSpecs[\sampleEnd],
					speed: channelSpecs[\speed],
					volume: channelSpecs[\volume],
					volumeEnvAttack: channelSpecs[\volumeEnvAttack],
					volumeEnvRelease: channelSpecs[\volumeEnvRelease],
					pan: channelSpecs[\pan],
					filterCutoff: channelSpecs[\filterCutoff],
					filterRes: channelSpecs[\filterRes],
					filterEnvAttack: channelSpecs[\filterEnvAttack],
					filterEnvRelease: channelSpecs[\filterEnvRelease],
					filterEnvMod: channelSpecs[\filterEnvMod],
					delaySend: channelSpecs[\send],
					reverbSend: channelSpecs[\send]
/*
	TODO
					speedSlew: slewSpec,
					phasorFreqSlew: slewSpec,
					volumeSlew: slewSpec,
					panSlew: slewSpec,
					filterCutoffSlew: slewSpec,
					filterResSlew: slewSpec,
*/
				)
			)
		).add;

		SynthDef(
			(this.stereoSamplePlayerDefName.asString++"_Sweep").asSymbol,
			{
				|
				gate,
				out=0,
				delayBus,
				reverbBus,
				bufnum,
				sampleStart,
				sampleEnd,
				loopPoint,
				speed,
				volume,
				volumeEnvAttack,
				volumeEnvRelease,
				pan,
				filterCutoff,
				filterRes,
				filterLowpassLevel,
				filterBandpassLevel,
				filterHighpassLevel,
				filterNotchLevel,
				filterPeakLevel,
				filterEnvAttack,
				filterEnvRelease,
				filterEnvMod,
				delaySend,
				reverbSend
				/*
				TODO
				speedSlew,
				phasorFreqSlew,
				volumeSlew,
				panSlew,
				filterCutoffSlew,
				filterResSlew,
				*/
				|
				var phase = sampleStart + Sweep.ar(1, speed * BufRateScale.kr(bufnum));
		
				var sig = BufRd.ar(2, bufnum, phase.linlin(0, 1, 0, BufFrames.kr(bufnum)), interpolation: 4); // TODO: tryout BLBufRd
		
				var freeEnv = EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
				var volumeEnv = EnvGen.ar(Env.perc(volumeEnvAttack, volumeEnvRelease), gate);
				var filterEnv = EnvGen.ar(Env.perc(filterEnvAttack, filterEnvRelease, filterEnvMod), gate);
		
				PauseSelf.kr(phase > sampleEnd);
				
				// sig = RLPF.ar(sig, filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv), filterRes);
				sig = SVF.ar(
					sig,
					\widefreq.asSpec.map(\widefreq.asSpec.unmap(filterCutoff)+filterEnv),
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel
				);
				sig = Balance2.ar(sig[0], sig[1], pan);
				sig = sig * volumeEnv * freeEnv * volume.dbamp;
				Out.ar(out, sig);
				Out.ar(delayBus, sig*delaySend.dbamp);
				Out.ar(reverbBus, sig*reverbSend.dbamp);
			},
			// rates: [\tr],
			rates: [nil],
			metadata: (
				specs: (
					// gate: ControlSpec(0, 1, step: 1, default: 0),
					out: \audiobus,
					delayBus: \audiobus,
					reverbBus: \audiobus,
					bufnum: nil,
					sampleStart: channelSpecs[\sampleStart],
					sampleEnd: channelSpecs[\sampleEnd],
					speed: channelSpecs[\speed],
					volume: channelSpecs[\volume],
					volumeEnvAttack: channelSpecs[\volumeEnvAttack],
					volumeEnvRelease: channelSpecs[\volumeEnvRelease],
					pan: channelSpecs[\pan],
					filterCutoff: channelSpecs[\filterCutoff],
					filterRes: channelSpecs[\filterRes],
					filterEnvAttack: channelSpecs[\filterEnvAttack],
					filterEnvRelease: channelSpecs[\filterEnvRelease],
					filterEnvMod: channelSpecs[\filterEnvMod],
					delaySend: channelSpecs[\delaySend],
					reverbSend: channelSpecs[\reverbSend]
/*
	TODO
					speedSlew: slewSpec,
					phasorFreqSlew: slewSpec,
					volumeSlew: slewSpec,
					panSlew: slewSpec,
					filterCutoffSlew: slewSpec,
					filterResSlew: slewSpec,
*/
				)
			)
		).add;

		SynthDef(
			(this.stereoSamplePlayerDefName.asString++"_OneShot").asSymbol,
			{
				|
					gate,
					out=0,
					delayBus,
					reverbBus,
					bufnum,
					sampleStart,
					sampleEnd,
					loopPoint,
					speed,
					volume,
					volumeEnvAttack,
					volumeEnvRelease,
					pan,
					filterCutoff,
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel,
					filterEnvAttack,
					filterEnvRelease,
					filterEnvMod,
					delaySend,
					reverbSend
/*
	TODO
					speedSlew,
					phasorFreqSlew,
					volumeSlew,
					panSlew,
					filterCutoffSlew,
					filterResSlew,
*/
				|
				var sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * speed, 1);

				var freeEnv = EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
				var volumeEnv = EnvGen.ar(Env.perc(volumeEnvAttack, volumeEnvRelease), gate);
				var filterEnv = EnvGen.ar(Env.perc(filterEnvAttack, filterEnvRelease, filterEnvMod), gate);

				// sig = RLPF.ar(sig, filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv), filterRes);
				sig = SVF.ar(
					sig,
					filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv),
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel
				);
				sig = Balance2.ar(sig[0], sig[1], pan);
				sig = sig * volumeEnv * freeEnv * volume.dbamp;
				Out.ar(out, sig);
				Out.ar(delayBus, sig*delaySend.dbamp);
				Out.ar(reverbBus, sig*reverbSend.dbamp);
			},
			// rates: [\tr],
			rates: [nil],
			metadata: (
				specs: (
					// gate: ControlSpec(0, 1, step: 1, default: 0),
					out: \audiobus,
					delayBus: \audiobus,
					reverbBus: \audiobus,
					bufnum: nil,
					sampleStart: channelSpecs[\sampleStart],
					sampleEnd: channelSpecs[\sampleEnd],
					speed: channelSpecs[\speed],
					volume: channelSpecs[\volume],
					volumeEnvAttack: channelSpecs[\volumeEnvAttack],
					volumeEnvRelease: channelSpecs[\volumeEnvRelease],
					pan: channelSpecs[\pan],
					filterCutoff: channelSpecs[\filterCutoff],
					filterRes: channelSpecs[\filterRes],
					filterEnvAttack: channelSpecs[\filterEnvAttack],
					filterEnvRelease: channelSpecs[\filterEnvRelease],
					filterEnvMod: channelSpecs[\filterEnvMod],
					delaySend: channelSpecs[\send],
					reverbSend: channelSpecs[\send]
/*
	TODO
					speedSlew: slewSpec,
					phasorFreqSlew: slewSpec,
					volumeSlew: slewSpec,
					panSlew: slewSpec,
					filterCutoffSlew: slewSpec,
					filterResSlew: slewSpec,
*/
				)
			)
		).add;

		SynthDef(
			(this.stereoSamplePlayerDefName.asString++"_Loop").asSymbol,
			{
				|
					gate,
					out=0,
					delayBus,
					reverbBus,
					bufnum,
					sampleStart,
					sampleEnd,
					loopPoint,
					speed,
					volume,
					volumeEnvAttack,
					volumeEnvRelease,
					pan,
					filterCutoff,
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel,
					filterEnvAttack,
					filterEnvRelease,
					filterEnvMod,
					delaySend,
					reverbSend
/*
	TODO
					speedSlew,
					phasorFreqSlew,
					volumeSlew,
					panSlew,
					filterCutoffSlew,
					filterResSlew,
*/
				|
				var bufFrames = BufFrames.kr(bufnum);
				var startPos = bufFrames * sampleStart;
				var endLoop = bufFrames * sampleEnd;
				var startLoop = startPos + ((endLoop-startPos)*loopPoint);
				var sig = LoopBuf.ar(2, bufnum, speed, 1, startPos, startLoop, endLoop, 4);

				var freeEnv = EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
				var volumeEnv = EnvGen.ar(Env.perc(volumeEnvAttack, volumeEnvRelease), gate);
				var filterEnv = EnvGen.ar(Env.perc(filterEnvAttack, filterEnvRelease, filterEnvMod), gate);

				// sig = RLPF.ar(sig, filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv), filterRes);
				sig = SVF.ar(
					sig,
					filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv),
					filterRes,
					filterLowpassLevel,
					filterBandpassLevel,
					filterHighpassLevel,
					filterNotchLevel,
					filterPeakLevel
				);
				sig = Balance2.ar(sig[0], sig[1], pan);
				sig = sig * volumeEnv * freeEnv * volume.dbamp;
				Out.ar(out, sig);
				Out.ar(delayBus, sig*delaySend.dbamp);
				Out.ar(reverbBus, sig*reverbSend.dbamp);
			},
			// rates: [\tr],
			rates: [nil],
			metadata: (
				specs: (
					// gate: ControlSpec(0, 1, step: 1, default: 0),
					out: \audiobus,
					delayBus: \audiobus,
					reverbBus: \audiobus,
					bufnum: nil,
					sampleStart: channelSpecs[\sampleStart],
					sampleEnd: channelSpecs[\sampleEnd],
					speed: channelSpecs[\speed],
					volume: channelSpecs[\volume],
					volumeEnvAttack: channelSpecs[\volumeEnvAttack],
					volumeEnvRelease: channelSpecs[\volumeEnvRelease],
					pan: channelSpecs[\pan],
					filterCutoff: channelSpecs[\filterCutoff],
					filterRes: channelSpecs[\filterRes],
					filterEnvAttack: channelSpecs[\filterEnvAttack],
					filterEnvRelease: channelSpecs[\filterEnvRelease],
					filterEnvMod: channelSpecs[\filterEnvMod],
					delaySend: channelSpecs[\send],
					reverbSend: channelSpecs[\send]
/*
	TODO
					speedSlew: slewSpec,
					phasorFreqSlew: slewSpec,
					volumeSlew: slewSpec,
					panSlew: slewSpec,
					filterCutoffSlew: slewSpec,
					filterResSlew: slewSpec,
*/
				)
			)
		).add;

		SynthDef(
			this.delayDefName,
			{ |in, out, delayTime, feedback, level|
				var sig = In.ar(in, 2);
				var sigfeedback = LocalIn.ar(2);
				sig = DelayC.ar(sig + sigfeedback, maxdelaytime: delayTimeSpec.maxval, delaytime: delayTime);
				LocalOut.ar(sig * feedback);
				Out.ar(out, sig * level.dbamp);
			},
			rates: [nil, nil, 0.2, 0.2],
			metadata: (
				specs: (
					in: \audiobus,
					out: \audiobus,
					delayTime: delayTimeSpec,
					feedback: delayFeedbackSpec,
					level: delayLevelSpec
				)
			)
		).add;

		SynthDef(
			this.reverbDefName,
			{ |in, out, room, damp, level|
				var sig = In.ar(in, 2);
				sig = FreeVerb.ar(sig, 1, room, damp);
				Out.ar(out, sig * level.dbamp);
			},
			metadata: (
				specs: (
					out: \audiobus,
					room: reverbRoomSpec,
					damp: reverbDampSpec,
					level: reverbLevelSpec
				)
			)
		).add;

		channelGroups = numChannels collect: { Group.tail(context.xg) };
		channelControlBusses = numChannels collect: {
			#[
				sampleStart,
				sampleEnd,
				loopPoint,
				speed,
				volume,
				volumeEnvAttack,
				volumeEnvRelease,
				pan,
				filterCutoff,
				filterRes,
				filterEnvAttack,
				filterEnvRelease,
				filterEnvMod,
				delaySend,
				reverbSend,
				filterLowpassLevel,
				filterBandpassLevel,
				filterHighpassLevel,
				filterNotchLevel,
				filterPeakLevel
/*
	TODO
				phasorFreqSlew,
				volumeSlew,
				panSlew,
				filterCutoffSlew,
				filterResSlew,
*/
			].collect { |sym|
				var bus = Bus.control;
				postln("channelControlBus for %".format(sym));
				postln("- set to default %".format(channelSpecs[sym].default));
				bus.set(channelSpecs[sym].default);
				postln("");

				sym -> bus
			}.asDict
		};
		effectsGroup = Group.tail(context.xg);

		// TODO: weirdness buffers = numChannels collect: { Buffer.new };
		buffers = numChannels collect: { Buffer.alloc(numFrames: 1) };

		delayBus = Bus.audio(numChannels: 2);
		reverbBus = Bus.audio(numChannels: 2);

		context.server.sync;

		delaySynth = Synth(this.delayDefName, [\out, context.out_b, \in, delayBus], target: effectsGroup);
		reverbSynth = Synth(this.reverbDefName, [\out, context.out_b, \in, reverbBus], target: effectsGroup);

		samplePlayerSynths = Array.fill(numChannels);

		context.server.sync;

		this.addCommand(\loadSample, "is") { |msg| this.cmdLoadSample(msg[1], msg[2]) };
		this.addCommand(\multiTrig, "iiiiiiii") { |msg| this.cmdMultiTrig(msg[1], msg[2], msg[3], msg[4], msg[5], msg[6], msg[7], msg[8]) };
		this.addCommand(\trig, "i") { |msg| this.cmdTrig(msg[1]) };
		this.addCommand(\sampleStart, "if") { |msg| this.cmdSampleStart(msg[1], msg[2]) };
		this.addCommand(\sampleEnd, "if") { |msg| this.cmdSampleEnd(msg[1], msg[2]) };
		this.addCommand(\loopPoint, "if") { |msg| this.cmdLoopPoint(msg[1], msg[2]) };
		this.addCommand(\enableLoop, "i") { |msg| this.cmdEnableLoop(msg[1]) };
		this.addCommand(\disableLoop, "i") { |msg| this.cmdDisableLoop(msg[1]) };
		this.addCommand(\speed, "if") { |msg| this.cmdSpeed(msg[1], msg[2]) };
		this.addCommand(\volume, "if") { |msg| this.cmdVolume(msg[1], msg[2]) };
		this.addCommand(\volumeEnvAttack, "if") { |msg| this.cmdVolumeEnvAttack(msg[1], msg[2]) };
		this.addCommand(\volumeEnvRelease, "if") { |msg| this.cmdVolumeEnvRelease(msg[1], msg[2]) };
		this.addCommand(\pan, "if") { |msg| this.cmdPan(msg[1], msg[2]) };
		this.addCommand(\filterCutoff, "if") { |msg| this.cmdFilterCutoff(msg[1], msg[2]) };
		this.addCommand(\filterRes, "if") { |msg| this.cmdFilterRes(msg[1], msg[2]) };
		this.addCommand(\filterMode, "ii") { |msg| this.cmdFilterMode(msg[1], msg[2]) };
		this.addCommand(\filterEnvAttack, "if") { |msg| this.cmdFilterEnvAttack(msg[1], msg[2]) };
		this.addCommand(\filterEnvRelease, "if") { |msg| this.cmdFilterEnvRelease(msg[1], msg[2]) };
		this.addCommand(\filterEnvMod, "if") { |msg| this.cmdFilterEnvMod(msg[1], msg[2]) };
		this.addCommand(\delaySend, "if") { |msg| this.cmdDelaySend(msg[1], msg[2]) };
		this.addCommand(\reverbSend, "if") { |msg| this.cmdReverbSend(msg[1], msg[2]) };
		this.addCommand(\delayTime, "f") { |msg| this.cmdDelayTime(msg[1]) };
		this.addCommand(\delayFeedback, "f") { |msg| this.cmdDelayFeedback(msg[1]) };
		this.addCommand(\delayLevel, "f") { |msg| this.cmdDelayLevel(msg[1]) };
		this.addCommand(\reverbRoom, "f") { |msg| this.cmdReverbRoom(msg[1]) };
		this.addCommand(\reverbDamp, "f") { |msg| this.cmdReverbDamp(msg[1]) };
		this.addCommand(\reverbLevel, "f") { |msg| this.cmdReverbLevel(msg[1]) };
/*
	TODO
		this.addCommand(\speedSlew, "if") { |msg| this.cmdSpeedSlew(msg[1], msg[2]) };
		this.addCommand(\volumeSlew, "if") { |msg| this.cmdVolumeSlew(msg[1], msg[2]) };
		this.addCommand(\panSlew, "if") { |msg| this.cmdPanSlew(msg[1], msg[2]) };
		this.addCommand(\filterCutoffSlew, "if") { |msg| this.cmdFilterCutoffSlew(msg[1], msg[2]) };
		this.addCommand(\filterResSlew, "if") { |msg| this.cmdFilterResSlew(msg[1], msg[2]) };
*/
	}

	cmdLoadSample { |channelnum, path|
		this.loadSample(channelnum, path.asString);
	}

	cmdMultiTrig { |...channels|
		context.server.makeBundle(nil) {
			channels.do { |trig, channelnum|
				if (trig.booleanValue) { this.cmdTrig(channelnum) };
			};
		};
	}

	cmdTrig { |channelnum|
		if (this.sampleIsLoaded(channelnum)) {
			var samplePlayerSynthArgs = [
				\gate, 1,
				\out, context.out_b,
				\delayBus, delayBus,
				\reverbBus, reverbBus,
				\bufnum, buffers[channelnum]
			];
			channelControlBusses[channelnum] keysValuesDo: { |key, value|
				samplePlayerSynthArgs = samplePlayerSynthArgs.addAll(
					[key, value.asMap]
				)
			};

			samplePlayerSynths[channelnum].release;

			samplePlayerSynths[channelnum] = Synth.new(
				(if (this.sampleIsStereo(channelnum), this.stereoSamplePlayerDefName, this.monoSamplePlayerDefName).asString++if (this.sampleHasLoopEnabled(channelnum), "_Loop", "_Sweep")).asSymbol,
				args: samplePlayerSynthArgs,
				target: channelGroups[channelnum]
			);
		};
	}

	cmdSampleStart { |channelnum, f|
		channelControlBusses[channelnum][\sampleStart].set(channelSpecs[\sampleStart].constrain(f));
	}

	cmdSampleEnd { |channelnum, f|
		channelControlBusses[channelnum][\sampleEnd].set(channelSpecs[\sampleEnd].constrain(f));
	}

	cmdLoopPoint { |channelnum, f|
		channelControlBusses[channelnum][\loopPoint].set(channelSpecs[\loopPoint].constrain(f));
	}

	cmdEnableLoop { |channelnum| loopEnabled[channelnum] = true }
	cmdDisableLoop { |channelnum| loopEnabled[channelnum] = false }

	cmdSpeed { |channelnum, f|
		channelControlBusses[channelnum][\speed].set(channelSpecs[\speed].constrain(f));
	}

	cmdVolume { |channelnum, f|
		channelControlBusses[channelnum][\volume].set(channelSpecs[\volume].constrain(f));
	}

	cmdVolumeEnvAttack { |channelnum, f|
		channelControlBusses[channelnum][\volumeEnvAttack].set(channelSpecs[\volumeEnvAttack].constrain(f));
	}

	cmdVolumeEnvRelease { |channelnum, f|
		channelControlBusses[channelnum][\volumeEnvRelease].set(channelSpecs[\volumeEnvRelease].constrain(f));
	}

	cmdPan { |channelnum, f|
		channelControlBusses[channelnum][\pan].set(channelSpecs[\pan].constrain(f));
	}

	cmdFilterCutoff { |channelnum, f|
		channelControlBusses[channelnum][\filterCutoff].set(channelSpecs[\filterCutoff].constrain(f));
	}

/*
	TODO
	cmdSpeedSlew { |channelnum, f|
		channelControlBusses[channelnum][\phasorFreqSlew].set(slewSpec.constrain(f));
	}
	cmdVolumeSlew { |channelnum, f|
		channelControlBusses[channelnum][\volumeSlew].set(slewSpec.constrain(f));
	}
	cmdPanSlew { |channelnum, f|
		channelControlBusses[channelnum][\panSlew].set(slewSpec.constrain(f));
	}
	cmdFilterCutoffSlew { |channelnum, f|
		channelControlBusses[channelnum][\filterCutoffSlew].set(slewSpec.constrain(f));
	}
	cmdFilterResSlew { |channelnum, f|
		channelControlBusses[channelnum][\filterResSlew].set(slewSpec.constrain(f));
	}
*/

	cmdFilterRes { |channelnum, f|
		channelControlBusses[channelnum][\filterRes].set(channelSpecs[\filterRes].constrain(f));
	}

	cmdFilterMode { |channelnum, i|
		var busses = channelControlBusses[channelnum];
		switch (i)
			{ 0 } {
				busses[\filterLowpassLevel].set(1);
				busses[\filterBandpassLevel].set(0);
				busses[\filterHighpassLevel].set(0);
				busses[\filterNotchLevel].set(0);
				busses[\filterPeakLevel].set(0);
			}
			{ 1 } {
				busses[\filterLowpassLevel].set(0);
				busses[\filterBandpassLevel].set(1);
				busses[\filterHighpassLevel].set(0);
				busses[\filterNotchLevel].set(0);
				busses[\filterPeakLevel].set(0);
			}
			{ 2 } {
				busses[\filterLowpassLevel].set(0);
				busses[\filterBandpassLevel].set(0);
				busses[\filterHighpassLevel].set(1);
				busses[\filterNotchLevel].set(0);
				busses[\filterPeakLevel].set(0);
			}
			{ 3 } {
				busses[\filterLowpassLevel].set(0);
				busses[\filterBandpassLevel].set(0);
				busses[\filterHighpassLevel].set(0);
				busses[\filterNotchLevel].set(1);
				busses[\filterPeakLevel].set(0);
			}
			{ 4 } {
				busses[\filterLowpassLevel].set(0);
				busses[\filterBandpassLevel].set(0);
				busses[\filterHighpassLevel].set(0);
				busses[\filterNotchLevel].set(0);
				busses[\filterPeakLevel].set(1);
			}
	}

	cmdFilterEnvAttack { |channelnum, f|
		channelControlBusses[channelnum][\filterEnvAttack].set(channelSpecs[\filterEnvAttack].constrain(f));
	}

	cmdFilterEnvRelease { |channelnum, f|
		channelControlBusses[channelnum][\filterEnvRelease].set(channelSpecs[\filterEnvRelease].constrain(f));
	}

	cmdFilterEnvMod { |channelnum, f|
		channelControlBusses[channelnum][\filterEnvMod].set(channelSpecs[\filterEnvMod].constrain(f));
	}

	cmdDelaySend { |channelnum, f|
		channelControlBusses[channelnum][\delaySend].set(channelSpecs[\delaySend].constrain(f));
	}

	cmdReverbSend { |channelnum, f|
		channelControlBusses[channelnum][\reverbSend].set(channelSpecs[\reverbSend].constrain(f));
	}

	cmdDelayTime { |f|
		delaySynth.set(\delayTime, delayTimeSpec.constrain(f));
	}

	cmdDelayFeedback { |f|
		delaySynth.set(\feedback, delayFeedbackSpec.constrain(f));
	}

	cmdDelayLevel { |f|
		delaySynth.set(\level, delayLevelSpec.constrain(f));
	}

	cmdReverbRoom { |f|
		reverbSynth.set(\room, reverbRoomSpec.constrain(f));
	}

	cmdReverbDamp { |f|
		reverbSynth.set(\damp, reverbDampSpec.constrain(f));
	}

	cmdReverbLevel { |f|
		reverbSynth.set(\level, reverbLevelSpec.constrain(f));
	}

	free {
		samplePlayerSynths do: _.free;
		channelGroups do: _.free;
		channelControlBusses do: { |dict| dict do: _.free };
		buffers do: _.free;

		effectsGroup.free;
		delayBus.free;
		reverbBus.free;
		delaySynth.free;
		reverbSynth.free;
	}

	sampleIsLoaded { |channelnum| ^buffers[channelnum].path.notNil }

	sampleIsStereo { |channelnum| ^buffers[channelnum].numChannels == 2 }

	sampleHasLoopEnabled { |channelnum| ^loopEnabled[channelnum] }

	loadSample { |channelnum, path|
		if (channelnum >= 0 and: channelnum < numChannels) {
			var numChannels, soundFile = SoundFile.openRead(path);
			if (soundFile.notNil) {
				numChannels = soundFile.numChannels;
				soundFile.close;
				if (numChannels < 3) {
					var buffer = buffers[channelnum];
					fork {
		    	    	buffer.allocRead(path);
						context.server.sync;
		    	    	buffer.updateInfo(path);
						context.server.sync;
						"sample % loaded into channel %"
							.format(path.quote, channelnum).inform;
					};
				} {
					"Only mono and stereo samples are supported, % has % channels"
						.format(path.quote, numChannels).error;
				};
			} {
				"Unable to open file %"
					.format(path.quote).error;
			};
		} {
			"Invalid argument (%) to loadSample, channelnum must be between 0 and %"
				.format(channelnum, numChannels-1).error;
		};
	}
}
