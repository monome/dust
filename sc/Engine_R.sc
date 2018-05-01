/*
	delete
	rename
	replace (with x)
	substitute
	insert before
	insert after
	insert
	swap
	bypass
*/

Engine_R : CroneEngine {
    classvar maxNumModules = 32;
    var numModules;
	var <modules;
	var moduleDict;

	*new { |context, callback| ^super.new(context, callback) }

	alloc {
		this.setDefaults;

		this.addCommand(\capacity, "i") { |msg| this.setNumModules(msg[1]) };
		this.addCommand(\module, "ss") { |msg| this.createModule(msg[1], msg[2]) };
		this.addCommand(\freeall, "") { |msg| this.freeModules }; // TODO: doesn't work yet
		this.addCommand(\free, "s") { |msg| this.freeModule(msg[1]) };
		this.addCommand(\patch, "ssf") { |msg| this.setPatchLevel(msg[1], msg[2], msg[3]) };
		this.addCommand(\param, "ssf") { |msg| this.setParam(msg[1], msg[2], msg[3]) };
		// this.addCommand(\parami, "iif") { |msg| this.setParamByIndex(msg[1], msg[2], msg[3]) };

		RModule.allSubclasses.do { |class|
			SynthDef(
				class.defName.asSymbol,
				class.ugenGraphFunc,
				class.lagTimes
			).add;
			"SynthDef % sent to server".format(class.asString.quote).inform;
		};

		context.server.sync;

		moduleDict = ();
	}

	free {
		\pre.debug([thisMethod.name]);
		this.freeModules;
		super.free;
		\post.debug([thisMethod.name]);
	}

	freeModules {
		modules.collect { |module|
			module[\thing].free;
			module[\patchSynths] do: _.free;
			module[\patchGroup].free;
			module[\synthGroup].free;
			module[\inbus].free;
			module[\outbus].free;
		}
	}

	setDefaults {
        this.setNumModules(8);
	}

	setParam { |name, paramnum, f|
		moduleDict[name] !? { |modulenum|
			this.setParamByModulenum(modulenum, paramnum, f);
		} ?? {
			"module named % not found amongst modules %".format(name, moduleDict.keys).error;
		}
	}

	setParamByModulenum { |modulenum, paramnum, f|
		modules[modulenum][\thing].setParam(paramnum, f);
	}

	setParamByModulenumAndIndex { |modulenum, paramnum, f|
		modules[modulenum][\thing].setParamByIndex(paramnum, f);
	}

	setPatchLevel { |srcName, destName, volumeDb|
		// TODO: validate inputs
		var srcModulenum, destModulenum;
		srcModulenum = moduleDict[srcName];
		destModulenum = moduleDict[destName];
		if (srcModulenum.notNil) {
			if (destModulenum.notNil) {
				this.setPatchLevelByModulenum(srcModulenum, destModulenum, volumeDb);
			} {
				"module named % not found amongst modules %".format(destName, moduleDict.keys).error;
			}
		} {
			"module named % not found amongst modules %".format(srcName, moduleDict.keys).error;
		}
	}

	setPatchLevelByModulenum { |srcModulenum, destModulenum, volumeDb|
		var patchSynth = modules[destModulenum][\patchSynths][srcModulenum];
		if (volumeDb <= -60) {
			context.server.makeBundle(nil) {
				patchSynth.set(\level, \db.asSpec.unmap(volumeDb));
				patchSynth.run(0); // TODO: optimization, is this just dumb?
			}
		} {
			context.server.makeBundle(nil) {
				patchSynth.run(1);
				patchSynth.set(\level, \db.asSpec.unmap(volumeDb));
			}
		};
		// patchSynth.set(\level, \db.asSpec.unmap(volumeDb)); // TODO: pre-optimization
	}

/*
	scrambleSamples {
		var filenameSymbol = this.class.filenameSymbol;
		var soundsFolder = PathName(filenameSymbol.asString).pathOnly ++ "tests";
		var soundsToLoad;
		var allSounds = PathName(soundsFolder)
			.deepFiles
			.select { |pathname| ["aif", "aiff", "wav"].includesEqual(pathname.extension) }
			.collect(_.fullPath);

		soundsToLoad = allSounds
			.scramble
			.keep(numSamples);

		soundsToLoad.do { |path, samplenum|
			this.loadSample(samplenum, path.asString);
		};

		context.server.sync;

		"% randomly selected sounds out of % sounds in folder % loaded into step"
				.format(soundsToLoad.size, allSounds.size, soundsFolder.quote).inform;
	}

	loadSample { |samplenum, path|
		if (samplenum >= 0 and: samplenum < numSamples) {
			// TODO: support stereo samples
			// TODO: enforce a maximum number of frames - no need to load 1 minute soundfiles (informative warning when not whole file is loaded)
	        buffers[samplenum].allocReadChannel(path, channels: [0], completionMessage: {
	            this.changed(\sampleWasLoaded, samplenum, path);
	        }); // TODO: look into making a PR for completionMessage bug
		} {
			"Invalid argument (%) to loadSample. Sample number must be between 0 and %"
				.format(samplenum, maxNumSamples-1).error;
		};
	}
*/

	setNumModules { |numModules|
		if ((numModules > 0) and: (numModules <= maxNumModules)) {
			this.freeModules;
	    	modules = Array.fill(numModules) {
				(
					patchGroup: Group.tail(context.xg),
					synthGroup: Group.tail(context.xg),
					inbus: Bus.audio,
					outbus: Bus.audio
				)
			};

			modules.do { |module, moduleIndex|
				module[\patchSynths] = modules.collect { |otherModule, otherModuleIndex|
					Synth.newPaused(
						if (otherModuleIndex >= moduleIndex, \patch_mono_fb, \patch_mono), // TODO: relies on CroneDefs for patching
						[\in, otherModule[\outbus], \out, module[\inbus], \level, 0.0],
						module[\patchGroup],
						\addToTail
					)
				};
			}
		} {
			"Invalid argument (%) to setNumModules. Number of modules must be between 1 and %"
				.format(numModules, maxNumModules).error;
		};
	}

	unusedModulenum {
		^modules.detectIndex { |module| module[\thing].isNil }
	}

	createModule { |name, moduleType|
		// TODO: validate name, should be [a-zA-Z0-9_]
		if (moduleDict[name].notNil) {
			"module named % already exists".format(name).error;
		} {
			var modulenum = this.unusedModulenum;
			if (modulenum.notNil) {
				var module = modules[modulenum];
				var thing = this.createModuleByModuleType(moduleType.asSymbol, module[\synthGroup], module[\inbus], module[\outbus]);
				moduleDict[name] = modulenum;
				module[\thing] = thing;
				thing.debug([thisMethod.name, modulenum, moduleType]);
			} {
				"module capacity % exceeded".format(this.numModules).error;
			};
		};
	}

	freeModule { |name|
		moduleDict[name] !? { |modulenum|
			var module = modules[modulenum];
			module[\thing].free;
			module[\thing] = nil;
			moduleDict[name] = nil;
			this.numModules.do { |outi|
				this.numModules.do { |ini|
					if ((ini == modulenum) or: (outi == modulenum)) {
						this.setPatchLevelByModulenum(ini, outi, -60);
					}
				}
			}
		} ?? {
			"module named % not found amongst modules %".format(name, moduleDict.keys).error;
		};
	}

	numModules { ^modules.size }

	createModuleByModuleType { |moduleType, group, inbus, outbus|
		^switch (moduleType)
			{ 'input' } { RInputModule.new(context, group, inbus, outbus) }
			{ 'output' } { ROutputModule.new(context, group, inbus, outbus) }
			{ 'delay' } { RDelayModule.new(context, group, inbus, outbus) }
			{ 'oscil' } { ROscillatorModule.new(context, group, inbus, outbus) }
			{ 'fmthing' } { RFMThingModule.new(context, group, inbus, outbus) }
			{ 'filter' } { RMultiModeFilterModule.new(context, group, inbus, outbus) }
			{ 'pole' } { RModulatingMultiModeFilterModule.new(context, group, inbus, outbus) }
			{ 'newpole' } { RTheNewPoleModule.new(context, group, inbus, outbus) }
			{ 'tape' } { RTapeModule.new(context, group, inbus, outbus) }
			{ 'grain' } { RGrainModule.new(context, group, inbus, outbus) }
	}
}

RModule {
	var synth;
	var context;
	*params { ^nil } // specified as Array of name -> ControlSpec associations where name correspond to SynthDef ugenGraphFunc argument
	*specs { ^this.params !? _.asDict }
	*ugenGraphFunc { ^this.subclassResponsibility }
	*lagTimes { ^nil }
	*defName { ^this.asSymbol }

	setParamByIndex { |paramnum, f|
		// (
			this.class.params[paramnum] !? { |param|
				var name, controlSpec, constrainedParamValue;
				name = param.key;
				controlSpec = param.value;
				constrainedParamValue = controlSpec.constrain(f);
				synth.set(name, constrainedParamValue);
				"%: synth.set(%, %); // param: %, spec: %".format(this.class, name, constrainedParamValue, name, controlSpec);
			} ?? {
				"%: no param indexed %".format(this.class, paramnum)
			}
		// ).debug([thisMethod.name, paramnum, f]);
	}

	setParam { |name, f|
		this.class.params.detectIndex { |param|
			param.key == name.asSymbol
		} !? { |i| this.setParamByIndex(i, f) } ?? {
			"%: no param named %".format(this.class, name).error
		}
	}

	*new { |context, group, inbus, outbus|
		^super.new.init(context, group, inbus, outbus);
	}

	init { |argContext, group, inbus, outbus|
		context = argContext;
		synth = Synth(this.class.defName.asSymbol, [\in, inbus, \out, outbus], target: group);
	}

	free {
		synth.free;
	}
}

RDelayModule : RModule {
	*params { // or: shove this into SynthDef metadata, change setModuleParam to iss and refer to parameters by name instead of indices, or infer index by argument
		^[
			'delaytime' -> ControlSpec(0.0001, 3, 'exp', 0, 0.3, "secs"),
		]
	}

	*ugenGraphFunc {
		var delayTimeSpec = this.specs['delaytime'];
		^{ |in, out, delaytime|
			var sig = In.ar(in);
			sig = DelayC.ar(sig, maxdelaytime: delayTimeSpec.maxval, delaytime: delaytime);
			Out.ar(out, sig);
		}
	}

	*lagTimes {
		^[
			nil, // in
			nil, // out
			0.25, // delaytime
			0.02 // decaytime
		]
	}
}

RInputModule : RModule {
	*params {
		^[ 'config' -> ControlSpec(0, 1, 'lin', 1, 0, "channel") ] // TODO: offset to context.in_b
	}

	*ugenGraphFunc {
		^{ |out, norns_in_b, config| Out.ar(out, In.ar(norns_in_b+config)) }
	}

	init { |argContext, group, inbus, outbus|
		context = argContext;
		synth = Synth(this.class.defName.asSymbol, [\in, inbus, \out, outbus, \norns_in_b, context.in_b], target: group);
	}
}

ROutputModule : RModule {
	*params {
		^[ 'config' -> ControlSpec(0, 1, 'lin', 1, 0, "") ] // TODO: offset to context.out_b
	}

	*ugenGraphFunc {
		^{ |in, config, mainoutl|
			var insig = In.ar(in);
			Out.ar(mainoutl+config, insig);
		}
	}

	init { |argContext, group, inbus, outbus|
		context = argContext;
		synth = Synth(this.class.defName.asSymbol, [\in, inbus, \out, outbus, \mainoutl, context.out_b.index, \mainoutr, context.out_b.index+1], target: group);
	}
}

ROscillatorModule : RModule {
	*params {
		^[
			'freq' -> \widefreq.asSpec,
			// 'index' -> \unipolar.asSpec
			'index' -> ControlSpec(0, 24, 'lin', 0, 3, "");
		]
	}

	*ugenGraphFunc {
		^{ |in, out, freq, index|
			var insig = In.ar(in);
			Out.ar(out, SinOsc.ar(freq + (insig * freq * index)));
		}
	}

	*lagTimes {
		^[
			nil, // in
			nil, // out
			0.02, // freq
			0.02 // mod
		]
	}
}

RFMThingModule : RModule {
	classvar numOscs = 3;
	*params {
		var params;
		numOscs.do { |oscnum|
			params = params.addAll(
				[
					"osc%gain".format(oscnum+1) -> \amp.asSpec,
					"osc%freq".format(oscnum+1) -> \widefreq.asSpec,
					"osc%index".format(oscnum+1) -> ControlSpec(0, 24, 'lin', 0, 3, ""),
					"osc%outlevel".format(oscnum+1) -> \amp.asSpec,
				]
			);
			numOscs.do { |dest|
				params = params.add(
					"osc%_to_osc%freq".format(oscnum+1, dest+1) -> \amp.asSpec
				);
			};
		};
		params = params.addAll(
			[
				'envgate' -> \unipolar.asSpec,
				'envattack' -> ControlSpec(0, 5000, 'lin', 0, 5, "ms"),
				'envdecay' -> ControlSpec(0, 5000, 'lin', 0, 30, "ms"),
				'envsustain' -> ControlSpec(0, 1, 'lin', 0, 0.5, ""),
				'envrelease' -> ControlSpec(0, 5000, 'lin', 0, 100, "ms"),
			]
		);

		numOscs.do { |oscnum|
			params = params.addAll(
				[
					"env_to_osc%freq".format(oscnum+1) -> \bipolar.asSpec,
					"env_to_osc%gain".format(oscnum+1) -> \bipolar.asSpec,
				]
			);
		};

		params = params.collect { |assoc|
			assoc.key.asSymbol -> assoc.value
		};
		// params.collect{ |assoc| assoc.key}.debug(\debug);

		^params;
	}

	*ugenGraphFunc {
		^{
			arg 
				in, // TODO: not used yet
				out,
				osc1gain,
				osc1freq,
				osc1index,
				osc1outlevel,
				osc1_to_osc1freq,
				osc1_to_osc2freq,
				osc1_to_osc3freq,
				osc2gain,
				osc2freq,
				osc2index,
				osc2outlevel,
				osc2_to_osc1freq,
				osc2_to_osc2freq,
				osc2_to_osc3freq,
				osc3gain,
				osc3freq,
				osc3index,
				osc3outlevel,
				osc3_to_osc3freq,
				osc3_to_osc2freq,
				osc3_to_osc1freq,
				envgate,
				envattack,
				envdecay,
				envsustain,
				envrelease,
				env_to_osc1freq,
				env_to_osc1gain,
				env_to_osc2freq,
				env_to_osc2gain,
				env_to_osc3freq,
				env_to_osc3gain
			;
			// var insig = In.ar(in); // TODO: not used
			var env = EnvGen.ar(Env.adsr(envattack/1000, envdecay/1000, envsustain, envrelease/1000), envgate);
			var oscfeedback = LocalIn.ar(3);
			var osc1 = SinOsc.ar(
				osc1freq
					+ (oscfeedback[0] * osc1freq * osc1_to_osc1freq * osc1index) // TODO: move osc1index multiplication out of here
					+ (oscfeedback[1] * osc1freq * osc2_to_osc1freq * osc1index)
					+ (oscfeedback[2] * osc1freq * osc3_to_osc1freq * osc1index)
					/* TODO + \freq.asSpec.map(env_to_osc1freq * env)*/
			) * (osc1gain + (env_to_osc1gain * env));
			var osc2 = SinOsc.ar(
				osc2freq
					+ (oscfeedback[0] * osc2freq * osc1_to_osc2freq * osc2index)
					+ (oscfeedback[1] * osc2freq * osc2_to_osc2freq * osc2index)
					+ (oscfeedback[2] * osc2freq * osc3_to_osc2freq * osc2index)
					/* TODO + \freq.asSpec.map(env_to_osc2freq * env)*/
			) * (osc2gain + (env_to_osc2gain * env));
			var osc3 = SinOsc.ar(
				osc3freq
					+ (oscfeedback[0] * osc3freq * osc1_to_osc3freq * osc3index)
					+ (oscfeedback[1] * osc3freq * osc2_to_osc3freq * osc3index)
					+ (oscfeedback[2] * osc3freq * osc3_to_osc3freq * osc3index)
					/* TODO + \freq.asSpec.map(env_to_osc3freq * env)*/
			) * (osc3gain + (env_to_osc3gain * env));
			LocalOut.ar([osc1, osc2, osc3]);
			Out.ar(
				out,
				(osc1 * osc1outlevel) +
				(osc2 * osc2outlevel) +
				(osc3 * osc3outlevel)
			);
		}
	}

	*lagTimes {
		^[
		]
	}
}

RTheNewPoleModule : RModule {
	*params {
		^[
			'lpfcutoff' -> ControlSpec(20, 10000, 'exp', 0, 440, " Hz"),
			'lpfres' -> \unipolar.asSpec,
			'hpfcutoff' -> ControlSpec(1, 10000, 'exp', 0, 440, " Hz"),
			'hpfres' -> \unipolar.asSpec,
			'ampgain' -> \amp.asSpec,
			'envgate' -> \unipolar.asSpec,
			'envattack' -> ControlSpec(0, 5000, 'lin', 0, 5, "ms"),
			'envdecay' -> ControlSpec(0, 5000, 'lin', 0, 30, "ms"),
			'envsustain' -> ControlSpec(0, 1, 'lin', 0, 0.5, ""),
			'envrelease' -> ControlSpec(0, 5000, 'lin', 0, 100, "ms"),
			'env_to_lpfcutoff' -> \amp.asSpec,
			'env_to_lpfres' -> \amp.asSpec,
			'env_to_hpfcutoff' -> \amp.asSpec,
			'env_to_hpfres' -> \amp.asSpec,
			'env_to_ampgain' -> \amp.asSpec,
			'lforate' -> \lofreq.asSpec,
			'lfo_to_lpfcutoff' -> \bipolar.asSpec,
			'lfo_to_lpfres' -> \amp.asSpec,
			'lfo_to_hpfcutoff' -> \amp.asSpec,
			'lfo_to_hpfres' -> \amp.asSpec,
			'lfo_to_ampgain' -> \amp.asSpec,
		]
	}

	*ugenGraphFunc {
		^{
			arg
				in,
				out,
				lpfcutoff,
				lpfres,
				hpfcutoff,
				hpfres,
				ampgain,
				envgate,
				envattack,
				envdecay,
				envsustain,
				envrelease,
				lforate,
				env_to_lpfcutoff,
				env_to_lpfres,
				env_to_hpfcutoff,
				env_to_hpfres,
				env_to_ampgain,
				lfo_to_lpfcutoff,
				lfo_to_lpfres,
				lfo_to_hpfcutoff,
				lfo_to_hpfres,
				lfo_to_ampgain
			;
			var freqSpec = ControlSpec(20, 10000, 'exp', 0, 440, " Hz");
			var rqSpec = \rq.asSpec;
			var env = EnvGen.ar(Env.adsr(envattack/1000, envdecay/1000, envsustain, envrelease/1000), envgate);
			var lfo = SinOsc.ar(lforate);
			var hpfrq = rqSpec.map(1-(hpfres + (env * env_to_hpfres) + (lfo * lfo_to_hpfres)));
			var lpfrq = rqSpec.map(1-(lpfres + (env * env_to_lpfres) + (lfo * lfo_to_lpfres)));
			var sig = In.ar(in);

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

			Out.ar(out, sig * (ampgain + (env * env_to_ampgain) + (lfo * lfo_to_ampgain)));
		}
	}

	*lagTimes {
		^[
			nil, // in
			nil, // out
			0.1, // freq
			0.1 // res
		]
	}
}

RGrainModule : RModule {
	*params {
		^[
			'rate' -> \rate.asSpec,
			'duration' -> ControlSpec(0, 100, 'lin', 0, 100, "%"),
			'position' -> ControlSpec(0, 100, 'lin', 0, 100, "%"),
			'tapenum' -> ControlSpec(0, 8, 'lin', 1, 0, ""),
		]
	}

	*ugenGraphFunc {
		^{ |out, rate, position, duration, tapenum|
			Out.ar(
				out,
				GrainBuf.ar(
					1,
					Dust.kr(rate),
					duration,
					tapenum,
					rate,
					position
				)
			)
		}
	}

	*lagTimes {
		^[
			nil, // in
			nil, // out
		]
	}
}

RTapeModule : RModule {
	*params {
		^[
			'record' -> ControlSpec(0, 1, 'lin', 1, 0, ""),
			'play' -> ControlSpec(0, 1, 'lin', 1, 0, ""),
			'monitor' -> ControlSpec(0, 1, 'lin', 1, 0, ""),
			'start' -> ControlSpec(0, 100, 'lin', 0, 0, "%"),
			'end' -> ControlSpec(0, 100, 'lin', 0, 100, "%"),
			'tapenum' -> ControlSpec(0, 100, 'lin', 0, 100, "%"),
		]
	}

	*ugenGraphFunc {
		^{ |in, out, freq, index|
			var insig = In.ar(in);
			Out.ar(out, SinOsc.ar(freq + (insig * freq * index)));
		}
	}

	*lagTimes {
		^[
			nil, // in
			nil, // out
			nil, // record
			nil, // play
			nil, // monitor
			0.01, // start
			0.01, // end
		]
	}
}

RMultiModeFilterModule : RModule {
	*params {
		^[
			'freq' -> \unipolar.asSpec,
			'res' -> \unipolar.asSpec
		]
	}

	*ugenGraphFunc {
		^{ |in, out, freq, res|
			var lpfCutoff = (freq*2) min: 1;
			var hpfCutoff = ((freq-0.5) max: 0)*2;
			var freqSpec = ControlSpec(20, 10000, 'exp', 0, 440, " Hz");
			var rqSpec = \rq.asSpec;
			var rq = rqSpec.map(1-res);
			var sig = In.ar(in);

			sig = RLPF.ar(sig, freqSpec.map(lpfCutoff), rq);
			sig = RHPF.ar(sig, freqSpec.map(hpfCutoff), rq);
			Out.ar(out, sig);
		}
	}

	*lagTimes {
		^[
			nil, // in
			nil, // out
			0.1, // freq
			0.1 // res
		]
	}
}

RModulatingMultiModeFilterModule : RModule {
	*params {
		^[
			'lforate' -> \lofreq.asSpec,
			'lfodepth' -> \unipolar.asSpec,
			'freq' -> \unipolar.asSpec,
			'res' -> \unipolar.asSpec
		]
	}

	*ugenGraphFunc {
		^{ |in, out, freq, res, lforate, lfodepth|
			var freqSpec = ControlSpec(20, 10000, 'exp', 0, 440, " Hz");
			var rqSpec = \rq.asSpec;

			var lpfCutoff;
			var hpfCutoff;

			var rq = rqSpec.map(1-res);

			var freqmodulated;
			var mod;
			var sig;

			mod = SinOsc.ar(lforate, mul: lfodepth);
			freqmodulated = freq + mod;
			lpfCutoff = (freqmodulated*2) min: 1;
			hpfCutoff = ((freqmodulated-0.5) max: 0)*2;
			sig = In.ar(in);
			sig = RLPF.ar(sig, freqSpec.map(lpfCutoff), rq);
			sig = RHPF.ar(sig, freqSpec.map(hpfCutoff), rq);
			Out.ar(out, sig);
		}
	}

	*lagTimes {
		^[
			nil, // in
			nil, // out
			0.1, // freq
			0.1 // res
		]
	}
}
