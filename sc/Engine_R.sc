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
		(
			this.class.params[paramnum] !? { |param|
				var name, controlSpec, constrainedParamValue;
				name = param.key;
				controlSpec = param.value;
				constrainedParamValue = controlSpec.constrain(f);
				synth.set(name, constrainedParamValue);
				"synth.set(%, %);".format(name, constrainedParamValue);
			}
		).debug([thisMethod.name, paramnum, f]);
	}

	setParam { |name, f|
		this.class.params.detectIndex { |param|
			param.key == name.asSymbol
		} !? { |i| this.setParamByIndex(i, f) }
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

/*
	TODO: remove, old plain SinOsc
ROscillatorModule : RModule {
	*params {
		^[ 'freq' -> \freq.asSpec ]
	}

	*ugenGraphFunc {
		^{ |out, freq| Out.ar(out, SinOsc.ar(freq)) }
	}
}
*/

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
	*params {
		^[
			// 'index' -> ControlSpec(0, 24, 'lin', 0, 3, "");
			'envattack' -> ControlSpec(0, 100, 'lin', 0, 30, "ms"),
			'envdecay' -> ControlSpec(0, 100, 'lin', 0, 30, "ms"),
			'envsustain' -> \unipolar.asSpec,
			'envrelease' -> ControlSpec(0, 100, 'lin', 0, 30, "ms"),
			'envgate' -> \unipolar.asSpec,
			'osc1freq' -> \widefreq.asSpec,
			'osc1freqenvmod' -> \db.asSpec,
			'osc1freqosc1mod' -> \db.asSpec,
			'osc1freqosc2mod' -> \db.asSpec,
			'osc1freqosc3mod' -> \db.asSpec,
			'osc1freqosc4mod' -> \db.asSpec,
			'osc1levelenvmod' -> \db.asSpec,
			'osc1level' -> \db.asSpec,
			'osc1outlevel' -> \db.asSpec,
			'osc2freq' -> \widefreq.asSpec,
			'osc2freqenvmod' -> \db.asSpec,
			'osc2freqosc1mod' -> \db.asSpec,
			'osc2freqosc2mod' -> \db.asSpec,
			'osc2freqosc3mod' -> \db.asSpec,
			'osc2freqosc4mod' -> \db.asSpec,
			'osc2levelenvmod' -> \db.asSpec,
			'osc2level' -> \db.asSpec,
			'osc2outlevel' -> \db.asSpec,
			'osc3freq' -> \widefreq.asSpec,
			'osc3freqenvmod' -> \db.asSpec,
			'osc3freqosc1mod' -> \db.asSpec,
			'osc3freqosc2mod' -> \db.asSpec,
			'osc3freqosc3mod' -> \db.asSpec,
			'osc3freqosc4mod' -> \db.asSpec,
			'osc3levelenvmod' -> \db.asSpec,
			'osc3level' -> \db.asSpec,
			'osc3outlevel' -> \db.asSpec,
			'osc4freq' -> \widefreq.asSpec,
			'osc4freqenvmod' -> \db.asSpec,
			'osc4freqosc1mod' -> \db.asSpec,
			'osc4freqosc2mod' -> \db.asSpec,
			'osc4freqosc3mod' -> \db.asSpec,
			'osc4freqosc4mod' -> \db.asSpec,
			'osc4levelenvmod' -> \db.asSpec,
			'osc4level' -> \db.asSpec,
			'osc4outlevel' -> \db.asSpec
		]
	}

	*ugenGraphFunc {
		^{
			arg 
				in, // TODO: not used yet
				out,
				envattack,
				envdecay,
				envsustain,
				envrelease,
				envgate,
				osc1freq,
				osc1freqenvmod = -60,
				osc1freqosc1mod = -60,
				osc1freqosc2mod = -60,
				osc1freqosc3mod = -60,
				osc1freqosc4mod = -60,
				osc1level = -60,
				osc1levelenvmod = -60,
				osc1outlevel = -60,
				osc2freq,
				osc2freqenvmod = -60,
				osc2freqosc1mod = -60,
				osc2freqosc2mod = -60,
				osc2freqosc3mod = -60,
				osc2freqosc4mod = -60,
				osc2level = -60,
				osc2levelenvmod = -60,
				osc2outlevel = -60,
				osc3freq,
				osc3freqenvmod = -60,
				osc3freqosc1mod = -60,
				osc3freqosc2mod = -60,
				osc3freqosc3mod = -60,
				osc3freqosc4mod = -60,
				osc3level = -60,
				osc3levelenvmod = -60,
				osc3outlevel = -60,
				osc4freq,
				osc4freqenvmod = -60,
				osc4freqosc1mod = -60,
				osc4freqosc2mod = -60,
				osc4freqosc3mod = -60,
				osc4freqosc4mod = -60,
				osc4level = -60,
				osc4levelenvmod = -60,
				osc4outlevel = -60
			;
			var insig = In.ar(in); // TODO: not used
			var env = EnvGen.ar(Env.adsr(envattack, envdecay, envsustain, envrelease), envgate);
			var oscfeedback = LocalIn.ar(4);
			var osc1 = SinOsc.ar(
				osc1freq
					+ (oscfeedback[0] * osc1freq * osc1freqosc1mod.dbamp)
					+ (oscfeedback[1] * osc1freq * osc1freqosc2mod.dbamp)
					+ (oscfeedback[2] * osc1freq * osc1freqosc3mod.dbamp)
					+ (oscfeedback[3] * osc1freq * osc1freqosc4mod.dbamp)
					+ (osc1freqenvmod.dbamp * env)
			) * (osc1level.dbamp + (osc1levelenvmod.dbamp * env));
			var osc2 = SinOsc.ar(
				osc2freq
					+ (oscfeedback[0] * osc2freq * osc2freqosc1mod.dbamp)
					+ (oscfeedback[1] * osc2freq * osc2freqosc2mod.dbamp)
					+ (oscfeedback[2] * osc2freq * osc2freqosc3mod.dbamp)
					+ (oscfeedback[3] * osc2freq * osc2freqosc4mod.dbamp)
					+ (osc2freqenvmod.dbamp * env)
			) * (osc2level.dbamp + (osc2levelenvmod.dbamp * env));
			var osc3 = SinOsc.ar(
				osc3freq
					+ (oscfeedback[0] * osc3freq * osc3freqosc1mod.dbamp)
					+ (oscfeedback[1] * osc3freq * osc3freqosc2mod.dbamp)
					+ (oscfeedback[2] * osc3freq * osc3freqosc3mod.dbamp)
					+ (oscfeedback[3] * osc3freq * osc3freqosc4mod.dbamp)
					+ (osc3freqenvmod.dbamp * env)
			) * (osc3level.dbamp + (osc3levelenvmod.dbamp * env));
			var osc4 = SinOsc.ar(
				osc4freq
					+ (oscfeedback[0] * osc4freq * osc4freqosc1mod.dbamp)
					+ (oscfeedback[1] * osc4freq * osc4freqosc2mod.dbamp)
					+ (oscfeedback[2] * osc4freq * osc4freqosc3mod.dbamp)
					+ (oscfeedback[3] * osc4freq * osc4freqosc4mod.dbamp)
					+ (osc4freqenvmod.dbamp * env)
			) * (osc4level.dbamp + (osc4levelenvmod.dbamp * env));
			LocalOut.ar([osc1, osc2, osc3, osc4]);
			Out.ar(
				out,
				(osc1 * osc1outlevel.dbamp) +
				(osc2 * osc2outlevel.dbamp) +
				(osc3 * osc3outlevel.dbamp) +
				(osc4 * osc4outlevel.dbamp)
			);
		}
	}

	*lagTimes {
		^[
			nil, // in, // TODO: not used yet
			nil, // out,
			// envattack,
			// envdecay,
			// envsustain,
			// envrelease,
			// envgate,
			// osc1freq,
			// osc1freqenvmod,
			// osc1freqosc1mod,
			// osc1freqosc2mod,
			// osc1freqosc3mod,
			// osc1freqosc4mod,
			// osc1level,
			// osc1levelenvmod,
			// osc1outlevel,
			// osc2freq,
			// osc2freqenvmod,
			// osc2freqosc1mod,
			// osc2freqosc2mod,
			// osc2freqosc3mod,
			// osc2freqosc4mod,
			// osc2level,
			// osc2levelenvmod,
			// osc2outlevel,
			// osc3freq,
			// osc3freqenvmod,
			// osc3freqosc1mod,
			// osc3freqosc2mod,
			// osc3freqosc3mod,
			// osc3freqosc4mod,
			// osc3level,
			// osc3levelenvmod,
			// osc3outlevel,
			// osc4freq,
			// osc4freqenvmod,
			// osc4freqosc1mod,
			// osc4freqosc2mod,
			// osc4freqosc3mod,
			// osc4freqosc4mod,
			// osc4level,
			// osc4levelenvmod,
			// osc4outlevel
		]
	}
}

RTheNewPoleModule : RModule {
	*params {
		^[
			'lowpassfiltercutoff' -> ControlSpec(20, 10000, 'exp', 0, 440, " Hz"),
			'lowpassfilterres' -> \unipolar.asSpec,
			'highpassfiltercutoff' -> ControlSpec(20, 10000, 'exp', 0, 440, " Hz"),
			'highpassfilterres' -> \unipolar.asSpec,
			'amplevel' -> \db.asSpec,
			'envattack' -> ControlSpec(0, 4, 'lin', 0, 0.01, "secs"),
			'envdecay' -> ControlSpec(0, 4, 'lin', 0, 0.3, "secs"),
			'envsustain' -> \unipolar.asSpec,
			'envrelease' -> ControlSpec(0, 4, 'lin', 0, 1, "secs"),
			'envgate' -> \unipolar.asSpec,
			'lforate' -> \lofreq.asSpec,
			'lowpassfiltercutoffenvmod' -> \db.asSpec,
			'lowpassfiltercutofflfomod' -> \db.asSpec,
			'lowpassfilterresenvmod' -> \db.asSpec,
			'lowpassfilterreslfomod' -> \db.asSpec,
			'highpassfiltercutoffenvmod' -> \db.asSpec,
			'highpassfiltercutofflfomod' -> \db.asSpec,
			'highpassfilterresenvmod' -> \db.asSpec,
			'highpassfilterreslfomod' -> \db.asSpec,
			'ampenvmod' -> \db.asSpec,
			'amplfomod' -> \db.asSpec
		]
	}

	*ugenGraphFunc {
		^{
			arg
				in,
				out,
				lowpassfiltercutoff = 10000,
				lowpassfilterres = 0,
				highpassfiltercutoff = 0,
				highpassfilterres = 0,
				amplevel = -60,
				envattack=0.01,
				envdecay=0.03,
				envsustain=0.5,
				envrelease=1,
				envgate,
				lforate = 1,
				lowpassfiltercutoffenvmod = -60,
				lowpassfiltercutofflfomod = -60,
				lowpassfilterresenvmod = -60,
				lowpassfilterreslfomod = -60,
				highpassfiltercutoffenvmod = -60,
				highpassfiltercutofflfomod = -60,
				highpassfilterresenvmod = -60,
				highpassfilterreslfomod = -60,
				ampenvmod = -60,
				amplfomod = -60
			;
			var freqSpec = ControlSpec(20, 10000, 'exp', 0, 440, " Hz");
			var rqSpec = \rq.asSpec;
			var env = EnvGen.ar(Env.adsr(envattack, envdecay, envsustain, envrelease), envgate);
			var lfo = SinOsc.ar(lforate);
			var highpassfilterrq = rqSpec.map(1-(highpassfilterres + (env * highpassfilterresenvmod.dbamp) + (lfo * highpassfilterreslfomod.dbamp)));
			var lowpassfilterrq = rqSpec.map(1-(lowpassfilterres + (env * lowpassfilterresenvmod.dbamp) + (lfo * lowpassfilterreslfomod.dbamp)));
			var sig = In.ar(in);

			sig = RHPF.ar(
				sig,
				freqSpec.map(freqSpec.unmap(highpassfiltercutoff) + (env * highpassfiltercutoffenvmod.dbamp) + (lfo * highpassfiltercutofflfomod.dbamp)),
				highpassfilterrq
			);

			sig = RLPF.ar(
				sig,
				freqSpec.map(freqSpec.unmap(lowpassfiltercutoff) + (env * lowpassfiltercutoffenvmod.dbamp) + (lfo * lowpassfiltercutofflfomod.dbamp)),
				lowpassfilterrq
			);

			Out.ar(out, sig * (amplevel.dbamp + (env * ampenvmod.dbamp) + (lfo * amplfomod.dbamp)));
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
