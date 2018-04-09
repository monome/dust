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

	var loopStartSpec;
	var loopEndSpec;
	var speedSpec;
	var slewSpec;
	var volumeSpec;
	var sendSpec;
	var volumeEnvAttackSpec;
	var volumeEnvReleaseSpec;
	var filterEnvAttackSpec;
	var filterEnvReleaseSpec;
	var panSpec;
	var filterCutoffSpec;
	var filterResSpec;
	var filterModeSpec;
	var filterEnvModSpec;

	var delayTimeSpec;
	var delayFeedbackSpec;

	var reverbRoomSpec;
	var reverbDampSpec;

	*new { |context, callback| ^super.new(context, callback) }

	monoSamplePlayerDefName { ^(this.class.name.asString++"_Mono").asSymbol }
	stereoSamplePlayerDefName { ^(this.class.name.asString++"_Stereo").asSymbol }
	delayDefName { ^(this.class.name.asString++"_Delay").asSymbol }
	reverbDefName { ^(this.class.name.asString++"_Reverb").asSymbol }

	alloc {
		var makeDef;

		loopStartSpec = \unipolar.asSpec;
		loopEndSpec = \unipolar.asSpec.copy.default_(1);
		speedSpec = ControlSpec(0, 5, default: 1);
		slewSpec = ControlSpec(0, 5, default: 0);
		volumeSpec = \db.asSpec.copy.default_(-10);
		sendSpec = \db.asSpec;
		volumeEnvAttackSpec = ControlSpec(0, 1, default: 0.001, units: "secs");
		volumeEnvReleaseSpec = ControlSpec(0, 3, default: 3, units: "secs");
		filterEnvAttackSpec = ControlSpec(0, 1, default: 0.001, units: "secs");
		filterEnvReleaseSpec = ControlSpec(0, 3, default: 0.25, units: "secs");
		panSpec = \pan.asSpec;
		filterCutoffSpec = \freq.asSpec.copy.default_(\freq.asSpec.maxval); // TODO: no reason to go all the way up to 20 000 Hz
		filterResSpec = \unipolar.asSpec;
		filterModeSpec = ControlSpec(0, 1, step: 1, default: 0);
		filterEnvModSpec = \unipolar.asSpec;

		delayTimeSpec = ControlSpec.new(0.0001, 5, 'exp', 0, 0.1, "secs");
		delayFeedbackSpec = \unipolar.asSpec;

		reverbRoomSpec = \unipolar.asSpec.copy.default_(0.75);
		reverbDampSpec = \unipolar.asSpec.copy.default_(0.5);

/*
		SynthDef(
			(this.stereoSamplePlayerDefName.asString++"_Loop").asSymbol,
			{
				|
					gate,
					out=0,
					delayBus,
					reverbBus,
					bufnum,
					loopStart,
					loopEnd,
					// speed, TODO
					// speedSlew, TODO
					phasorFreq,
					phasorFreqSlew,
					volume,
					volumeSlew,
					volumeEnvAttack,
					volumeEnvRelease,
					pan,
					panSlew,
					filterCutoff,
					filterCutoffSlew,
					filterRq,
					filterRqSlew,
					filterMode,
					filterEnvAttack,
					filterEnvRelease,
					filterEnvMod,
					delaySend,
					reverbSend
				|
				//var sig = SynthDef.wrap(func, nil, [bufnum, speed, trigger]) * volume.dbamp; TODO // Fix Mono and Stereo
				//var sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * speed, gate, loopStart*BufFrames.kr(bufnum));
				// var sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * phasorFreq, gate, loopStart*BufFrames.kr(bufnum));

				var rate = BufRateScale.kr(bufnum) * Lag.kr(phasorFreq, phasorFreqSlew) * sign(loopStart-loopEnd) * (-1);
				var playhead = Phasor.ar(0, rate, BufFrames.kr(bufnum)*loopStart, BufFrames.kr(bufnum)*loopEnd);
				// TODO: add miller puckette-style amp window to remove clicks
				var sig = BufRd.ar(2, bufnum, playhead, interpolation: 4);

				var hpz = HPZ1.ar(playhead);
				// PauseSelf.kr((HPZ1.ar(playhead) < 0) + rate.sign - 1); // PauseSelf when playing forwards and wraps
				// PauseSelf.kr((HPZ1.ar(playhead) > 0) + rate.sign + 1); // PauseSelf when playing backwards and wraps

				var volumeEnv = EnvGen.ar(Env.perc(volumeEnvAttack, volumeEnvRelease), gate);
				var filterEnv = EnvGen.ar(Env.perc(filterEnvAttack, filterEnvRelease, filterEnvMod), gate);

				//EnvGen.ar(Env.cutoff(0.0), hpz < 0, doneAction: Done.pauseSelf);
				//EnvGen.ar(Env.cutoff(0.0), hpz > 0, doneAction: Done.pauseSelf);

				sig = RLPF.ar(sig, filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv), filterRq);
				// sig = Pan2.ar(sig, Lag.kr(pan, panSlew)); // Mono
				sig = Balance2.ar(sig[0], sig[1], Lag.kr(pan, panSlew)); // Stereo
				sig = sig * volumeEnv * volume.dbamp;
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
					bufnum: nil, // ControlSpec(0, 7, step: 1, default: 0), // TODO: temporary for testing in SynthDescLib
					loopStart: loopStartSpec,
					loopEnd: loopEndSpec,
					// speed: speedSpec,
					// speedSlew: slewSpec,
					phasorFreq: nil,
					phasorFreqSlew: slewSpec,
					volume: volumeSpec,
					volumeSlew: slewSpec,
					volumeEnvAttack: volumeEnvAttackSpec,
					volumeEnvRelease: volumeEnvReleaseSpec,
					pan: panSpec,
					panSlew: slewSpec,
					filterCutoff: filterCutoffSpec,
					filterCutoffSlew: slewSpec,
					filterRq: \rq,
					filterRqSlew: slewSpec,
					filterMode: filterModeSpec,
					filterEnvAttack: filterEnvAttackSpec,
					filterEnvRelease: filterEnvReleaseSpec,
					filterEnvMod: filterEnvModSpec,
					delaySend: sendSpec,
					reverbSend: sendSpec
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
					loopStart,
					loopEnd,
					// speed, TODO
					// speedSlew, TODO
					phasorFreq,
					phasorFreqSlew,
					volume,
					volumeSlew,
					volumeEnvAttack,
					volumeEnvRelease,
					pan,
					panSlew,
					filterCutoff,
					filterCutoffSlew,
					filterRq,
					filterRqSlew,
					filterMode,
					filterEnvAttack,
					filterEnvRelease,
					filterEnvMod,
					delaySend,
					reverbSend
				|
				//var sig = SynthDef.wrap(func, nil, [bufnum, speed, trigger]) * volume.dbamp; TODO // Fix Mono and Stereo
				//var sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * speed, gate, loopStart*BufFrames.kr(bufnum));
				// var sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * phasorFreq, gate, loopStart*BufFrames.kr(bufnum));

				var rate = BufRateScale.kr(bufnum) * VarLag.kr(phasorFreq, phasorFreqSlew) * sign(loopStart-loopEnd) * (-1);
				var playhead = Phasor.ar(0, rate, BufFrames.kr(bufnum)*loopStart, BufFrames.kr(bufnum)*loopEnd);
				// TODO: add miller puckette-style amp window to remove clicks
				var sig = BufRd.ar(2, bufnum, playhead, interpolation: 4);

				var hpz = HPZ1.ar(playhead);
				// PauseSelf.kr((HPZ1.ar(playhead) < 0) + rate.sign - 1); // PauseSelf when playing forwards and wraps
				// PauseSelf.kr((HPZ1.ar(playhead) > 0) + rate.sign + 1); // PauseSelf when playing backwards and wraps

				var volumeEnv = EnvGen.ar(Env.perc(volumeEnvAttack, volumeEnvRelease), gate);
				var filterEnv = EnvGen.ar(Env.perc(filterEnvAttack, filterEnvRelease, filterEnvMod), gate);

				EnvGen.ar(Env.cutoff(0.0), hpz < 0, doneAction: Done.pauseSelf);
				//EnvGen.ar(Env.cutoff(0.0), hpz > 0, doneAction: Done.pauseSelf);

				sig = RLPF.ar(sig, filterCutoffSpec.map(VarLag.ar(filterCutoffSpec.unmap(filterCutoff)+filterEnv, filterCutoffSlew)), filterRq);
				// sig = Pan2.ar(sig, Lag.kr(pan, panSlew)); // Mono
				// sig = Balance2.ar(sig[0], sig[1], Lag.kr(pan, panSlew)); // Stereo
				sig = sig * volumeEnv * volume.dbamp;
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
					bufnum: nil, // ControlSpec(0, 7, step: 1, default: 0), // TODO: temporary for testing in SynthDescLib
					loopStart: loopStartSpec,
					loopEnd: loopEndSpec,
					// speed: speedSpec,
					// speedSlew: slewSpec,
					phasorFreq: nil,
					phasorFreqSlew: slewSpec,
					volume: volumeSpec,
					volumeSlew: slewSpec,
					volumeEnvAttack: volumeEnvAttackSpec,
					volumeEnvRelease: volumeEnvReleaseSpec,
					pan: panSpec,
					panSlew: slewSpec,
					filterCutoff: filterCutoffSpec,
					filterCutoffSlew: slewSpec,
					filterRq: \rq,
					filterRqSlew: slewSpec,
					filterMode: filterModeSpec,
					filterEnvAttack: filterEnvAttackSpec,
					filterEnvRelease: filterEnvReleaseSpec,
					filterEnvMod: filterEnvModSpec,
					delaySend: sendSpec,
					reverbSend: sendSpec
				)
			)
		).add;
*/

		SynthDef(
			(this.monoSamplePlayerDefName.asString++"_OneShot").asSymbol,
			{
				|
					gate,
					out=0,
					delayBus,
					reverbBus,
					bufnum,
					loopStart,
					loopEnd,
					// speed, TODO
					// speedSlew, TODO
					phasorFreq,
					phasorFreqSlew,
					volume,
					volumeSlew,
					volumeEnvAttack,
					volumeEnvRelease,
					pan,
					panSlew,
					filterCutoff,
					filterCutoffSlew,
					filterRq,
					filterRqSlew,
					filterMode,
					filterEnvAttack,
					filterEnvRelease,
					filterEnvMod,
					delaySend,
					reverbSend
				|
				var sig = PlayBuf.ar(1, bufnum, phasorFreq, 1);

				var freeEnv = EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
				var volumeEnv = EnvGen.ar(Env.perc(volumeEnvAttack, volumeEnvRelease), gate);
				var filterEnv = EnvGen.ar(Env.perc(filterEnvAttack, filterEnvRelease, filterEnvMod), gate);

				sig = RLPF.ar(sig, filterCutoffSpec.map(filterCutoffSpec.unmap(filterCutoff)+filterEnv), filterRq);
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
					bufnum: nil, // ControlSpec(0, 7, step: 1, default: 0), // TODO: temporary for testing in SynthDescLib
					loopStart: loopStartSpec,
					loopEnd: loopEndSpec,
					// speed: speedSpec,
					// speedSlew: slewSpec,
					phasorFreq: nil,
					phasorFreqSlew: slewSpec,
					volume: volumeSpec,
					volumeSlew: slewSpec,
					volumeEnvAttack: volumeEnvAttackSpec,
					volumeEnvRelease: volumeEnvReleaseSpec,
					pan: panSpec,
					panSlew: slewSpec,
					filterCutoff: filterCutoffSpec,
					filterCutoffSlew: slewSpec,
					filterRq: \rq,
					filterRqSlew: slewSpec,
					filterMode: filterModeSpec,
					filterEnvAttack: filterEnvAttackSpec,
					filterEnvRelease: filterEnvReleaseSpec,
					filterEnvMod: filterEnvModSpec,
					delaySend: sendSpec,
					reverbSend: sendSpec
				)
			)
		).add;

		SynthDef(
			this.delayDefName,
			{ |in, out, delayTimeL, delayTimeR, feedback|
				var sig = In.ar(in, 2);
				sig = CombC.ar(sig, maxdelaytime: delayTimeSpec.maxval, delaytime: delayTimeL, decaytime: feedback);
				Out.ar(out, sig);
			},
			rates: [nil, nil, nil, nil, nil],
			metadata: (
				specs: (
					in: \audiobus,
					out: \audiobus,
					delayTimeL: delayTimeSpec,
					delayTimeR: delayTimeSpec,
					feedback: delayTimeSpec
				)
			)
		).add;

		SynthDef(
			this.reverbDefName,
			{ |in, out, room, damp|
				var sig = In.ar(in, 2);
				sig = FreeVerb.ar(sig, 1, room, damp);
				Out.ar(out, sig);
			},
			metadata: (
				specs: (
					out: \audiobus,
					room: reverbRoomSpec,
					damp: reverbDampSpec
				)
			)
		).add;

		channelGroups = numChannels collect: { Group.tail(context.xg) };
		channelControlBusses = numChannels collect: {
			#[
				loopStart,
				loopEnd,
				phasorFreq,
				phasorFreqSlew,
				volume,
				volumeSlew,
				volumeEnvAttack,
				volumeEnvRelease,
				pan,
				panSlew,
				filterCutoff,
				filterCutoffSlew,
				filterRq,
				filterResSlew,
				filterMode,
				filterEnvAttack,
				filterEnvRelease,
				filterEnvMod,
				delaySend,
				reverbSend,
				// TODO delayTimeL,
				// TODO delayTimeR,
				// TODO delayFeedback,
				// TODO reverbRoom,
				// TODO reverbDamp
			].collect { |sym| sym -> Bus.control }.asDict
		};
		effectsGroup = Group.tail(context.xg);

		// TODO: weirdness buffers = numChannels collect: { Buffer.new };
		buffers = numChannels collect: { Buffer.alloc(numFrames: 1) };

		delayBus = Bus.audio(numChannels: 2);
		reverbBus = Bus.audio(numChannels: 2);

		delayBus.debug(\delayBus);
		reverbBus.debug(\reverbBus);

		context.server.sync;

		this.addCommand(\loadSample, "is") { |msg| this.cmdLoadSample(msg[1], msg[2]) };
		this.addCommand(\trig, "i") { |msg| this.cmdTrig(msg[1]) };
		this.addCommand(\loopStart, "if") { |msg| this.cmdLoopStart(msg[1], msg[2]) };
		this.addCommand(\loopEnd, "if") { |msg| this.cmdLoopEnd(msg[1], msg[2]) };
		this.addCommand(\speed, "if") { |msg| this.cmdSpeed(msg[1], msg[2]) };
		this.addCommand(\speedSlew, "if") { |msg| this.cmdSpeedSlew(msg[1], msg[2]) };
		this.addCommand(\volume, "if") { |msg| this.cmdVolume(msg[1], msg[2]) };
		this.addCommand(\volumeSlew, "if") { |msg| this.cmdVolumeSlew(msg[1], msg[2]) };
		this.addCommand(\volumeEnvAttack, "if") { |msg| this.cmdVolumeEnvAttack(msg[1], msg[2]) };
		this.addCommand(\volumeEnvRelease, "if") { |msg| this.cmdVolumeEnvRelease(msg[1], msg[2]) };
		this.addCommand(\pan, "if") { |msg| this.cmdPan(msg[1], msg[2]) };
		this.addCommand(\panSlew, "if") { |msg| this.cmdPanSlew(msg[1], msg[2]) };
		this.addCommand(\filterCutoff, "if") { |msg| this.cmdFilterCutoff(msg[1], msg[2]) };
		this.addCommand(\filterCutoffSlew, "if") { |msg| this.cmdFilterCutoffSlew(msg[1], msg[2]) };
		this.addCommand(\filterRes, "if") { |msg| this.cmdFilterRes(msg[1], msg[2]) };
		this.addCommand(\filterResSlew, "if") { |msg| this.cmdFilterResSlew(msg[1], msg[2]) };
		this.addCommand(\filterMode, "ii") { |msg| this.cmdFilterMode(msg[1], msg[2]) };
		this.addCommand(\filterEnvAttack, "if") { |msg| this.cmdFilterEnvAttack(msg[1], msg[2]) };
		this.addCommand(\filterEnvRelease, "if") { |msg| this.cmdFilterEnvRelease(msg[1], msg[2]) };
		this.addCommand(\filterEnvMod, "if") { |msg| this.cmdFilterEnvMod(msg[1], msg[2]) };
		this.addCommand(\delaySend, "if") { |msg| this.cmdDelaySend(msg[1], msg[2]) };
		this.addCommand(\reverbSend, "if") { |msg| this.cmdReverbSend(msg[1], msg[2]) };
		this.addCommand(\delayTimeL, "f") { |msg| this.cmdDelayTimeL(msg[1]) };
		this.addCommand(\delayTimeR, "f") { |msg| this.cmdDelayTimeR(msg[1]) };
		this.addCommand(\delayFeedback, "f") { |msg| this.cmdDelayFeedback(msg[1]) };
		// TODO :this.addCommand(\reverbRoom, "f") { |msg| this.cmdReverbRoom(msg[1]) };
		// this.addCommand(\reverbDamp, "f") { |msg| this.cmdReverbDamp(msg[1]) };
		this.addParameter(\reverbRoom, reverbRoomSpec);
		this.addParameter(\reverbDamp, reverbDampSpec);

		context.server.sync;

		delaySynth = Synth(this.delayDefName, [\out, context.out_b, \in, delayBus], target: effectsGroup);
		reverbSynth = Synth(this.reverbDefName, [\out, context.out_b, \in, reverbBus, \room, parameterControlBusses[\reverbRoom].asMap, \damp, parameterControlBusses[\reverbDamp].asMap], target: effectsGroup);

		samplePlayerSynths = Array.fill(numChannels);

	}

	cmdLoadSample { |channelnum, path|
		this.loadSample(channelnum, path.asString);
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
			samplePlayerSynthArgs.debug;

			samplePlayerSynths[channelnum].release; // TODO

			samplePlayerSynths[channelnum] = Synth.new(
				(if (this.sampleIsStereo(channelnum), this.stereoSamplePlayerDefName, this.monoSamplePlayerDefName).asString++"_OneShot").asSymbol,
				args: samplePlayerSynthArgs,
				target: channelGroups[channelnum]
			);
		};
	}

	cmdLoopStart { |channelnum, f|
		channelControlBusses[channelnum][\loopStart].set(loopStartSpec.constrain(f));
	}

	cmdLoopEnd { |channelnum, f|
		channelControlBusses[channelnum][\loopEnd].set(loopEndSpec.constrain(f));
	}

	cmdSpeed { |channelnum, f|
		// TODO channelGroups[channelnum].set(\speed, speedSpec.constrain(f));
		channelControlBusses[channelnum][\phasorFreq].set(speedSpec.constrain(f)); // TODO: this should be a ctrlBus
	}

	cmdSpeedSlew { |channelnum, f|
		// TODO channelGroups[channelnum].set(\speedSlew, slewSpec.constrain(f));
		channelControlBusses[channelnum][\phasorFreqSlew].set(slewSpec.constrain(f));
	}

	cmdVolume { |channelnum, f|
		channelControlBusses[channelnum][\volume].set(volumeSpec.constrain(f));
	}

	cmdVolumeSlew { |channelnum, f|
		channelControlBusses[channelnum][\volumeSlew].set(slewSpec.constrain(f));
	}

	cmdVolumeEnvAttack { |channelnum, f|
		channelControlBusses[channelnum][\volumeEnvAttack].set(volumeEnvAttackSpec.constrain(f));
	}

	cmdVolumeEnvRelease { |channelnum, f|
		channelControlBusses[channelnum][\volumeEnvRelease].set(volumeEnvReleaseSpec.constrain(f));
	}

	cmdPan { |channelnum, f|
		channelControlBusses[channelnum][\pan].set(panSpec.constrain(f));
	}

	cmdPanSlew { |channelnum, f|
		channelControlBusses[channelnum][\panSlew].set(slewSpec.constrain(f));
	}

	cmdFilterCutoff { |channelnum, f|
		channelControlBusses[channelnum][\filterCutoff].set(filterCutoffSpec.constrain(f));
	}

	cmdFilterCutoffSlew { |channelnum, f|
		channelControlBusses[channelnum][\filterCutoffSlew].set(slewSpec.constrain(f));
	}

	cmdFilterRes { |channelnum, f|
		channelControlBusses[channelnum][\filterRq].set(\rq.asSpec.copy.maxval_(1).map((filterResSpec.unmap(f).neg+1)));
	}

	cmdFilterResSlew { |channelnum, f|
		channelControlBusses[channelnum][\filterResSlew].set(slewSpec.constrain(f));
	}

	cmdFilterMode { |channelnum, f|
		channelControlBusses[channelnum][\filterMode].set(filterModeSpec.constrain(f));
	}

	cmdFilterEnvAttack { |channelnum, f|
		channelControlBusses[channelnum][\filterEnvAttack].set(filterEnvAttackSpec.constrain(f));
	}

	cmdFilterEnvRelease { |channelnum, f|
		channelControlBusses[channelnum][\filterEnvRelease].set(filterEnvReleaseSpec.constrain(f));
	}

	cmdFilterEnvMod { |channelnum, f|
		channelControlBusses[channelnum][\filterEnvMod].set(filterEnvModSpec.constrain(f));
	}

	cmdDelaySend { |channelnum, f|
		channelControlBusses[channelnum][\delaySend].set(sendSpec.constrain(f));
	}

	cmdReverbSend { |channelnum, f|
		channelControlBusses[channelnum][\reverbSend].set(sendSpec.constrain(f));
	}

	cmdDelayTimeL { |f|
		delaySynth.set(\delayTimeL, delayTimeSpec.constrain(f));
	}

	cmdDelayTimeR { |f|
		delaySynth.set(\delayTimeR, delayTimeSpec.constrain(f));
	}

	cmdDelayFeedback { |f|
		delaySynth.set(\feedback, delayTimeSpec.constrain(f));
	}

	cmdReverbRoom { |f|
		reverbSynth.set(\room, reverbRoomSpec.constrain(f));
	}

	cmdReverbDamp { |f|
		reverbSynth.set(\damp, reverbDampSpec.constrain(f));
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

		super.free;
	}

	// TODO: remove
	scrambleSamples {
		var soundsFolder = "/home/pi/dust/audio/hello_ack";
		// var soundsFolder = "/newthing/dust/audio/hello_ack";
		var soundsToLoad;
		var allSounds = PathName(soundsFolder)
			.deepFiles
			.select { |pathname| ["aif", "aiff", "wav"].includesEqual(pathname.extension) }
			.collect(_.fullPath);

		soundsToLoad = allSounds
			.scramble
			.keep(numChannels);

		fork {
			soundsToLoad.do { |path, channelnum|
				this.loadSample(channelnum, path.asString);
			};

			context.server.sync;

			"% randomly selected sounds out of % sounds in folder % loaded."
				.format(soundsToLoad.size, allSounds.size, soundsFolder.quote).inform;
		};
	}

	sampleIsLoaded { |channelnum|
		^buffers[channelnum].path.notNil
	}

	sampleIsStereo { |channelnum|
		^buffers[channelnum].numChannels == 2
	}

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
						"sample % loaded into channel %".format(path.quote, channelnum).inform;
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
