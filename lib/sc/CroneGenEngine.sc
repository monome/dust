CroneGenEngine : CroneEngine {
	classvar <>debug = true;
	classvar defaultPolyphony = 6;
	var synthDesc;
	var metadata;
	var <controlBusses; // TODO: make private
	var synths;
	var buffers;
	var savedArgs;
	var polyphony;

	*new { |context, callback|
		^super.new(context, callback).initCroneGenEngine;
	}

	initCroneGenEngine {
		var synthDef;
		synthDef = this.class.synthDef;

		if (synthDef.name == 'nil') { // TODO: even needed, or should this simply be overwritten to classname?
			synthDef.name = this.asString.asSymbol;
		};
		synthDef.add;
		synthDesc=SynthDescLib.global[synthDef.name];

		metadata = CroneSynthDefIntrospectionUtil.inspectSynthDesc(synthDesc);

        if (metadata[\inControlName].isNil and: metadata[\outControlName].isNil) {
            Error("a mono or stereo in or out must be defined.").throw;
        };
	}

	alloc {
		var controlsNotToExposeAsCommands;
		var controlsToExposeAsCommands;
		var controlBusArgs;
		var args;
		var specs;

        var inControlName = metadata[\inControlName];
        var outControlName = metadata[\outControlName];
		var type = metadata[\type];

		controlsNotToExposeAsCommands = [
			'gate',
			'freq',
			inControlName,
			outControlName, // TODO: was 'out', instead check output_data and filter out correct out argument
			'amp_env0', // TODO: possibly map amp_env in synth output bus index to this argument
			'amp_env1', // TODO: possibly map amp_env in synth output bus index to this argument
			'pitch_trk0', // TODO: possibly map pitch out synth output bus index to this argument, not sure about whether pitch is before or after processing, so skip for now
			'pitch_trk1' // TODO: possibly map pitch out synth output bus index to this argument, not sure about whether pitch is before or after processing, so skip for now
		] ++ if (inControlName.notNil, [inControlName], []) ++ if (outControlName.notNil, [outControlName], []);

		controlsToExposeAsCommands = synthDesc.controls.reject { |control|
			controlsNotToExposeAsCommands.includes(control.name);
		};

		controlBusses = IdentityDictionary.new;

        args = this.autorouteInputs(inControlName, args);
		this.class.trace(\autorouteInputs, args);
        args = this.autorouteOutputs(outControlName, args);
		this.class.trace(\autorouteOutputs, args);
        args = this.autorouteAmplitudeEnvelope(args);
		this.class.trace(\autorouteAmp, args);
        args = this.autoroutePitchTracker(args);
		this.class.trace(\autoroutePitch, args);

		this.class.trace(\type, type);

		switch (type)
			{\persistent} {
				// 1:1 synth and engine, synths is spawned until engine is changed
				// context.server.sync;

				// synths = [ Synth(synthDef.name, args: args, target: context.xg) ];
				// context.server.sync;
				this.addCommand(
					"run",
					"i",
					{ |msg| synths.first.run(msg[1]); }
				);
			}
/*
			TODO: sc-side voice allocation
			{\polyphonicFreeSelf} {
				// gate and freq means synth is considered polyphonic, synths are spawned on note ons and released on note offs
				// TODO: how to handle polyphony / voice allocation?
				// synths = Array.fill(128); // TODO: number of midi notes

				// TODO: gate and freq reserved for noteOns/Offs
				controlsToExposeAsCommands = controlsToExposeAsCommands.reject { |control| [\gate, \freq].includes(control.name) };
				// TODO: also free controlBusses

				// TODO: currently, amp gets reserved for midi note on velocity
				if (synthDesc.hasControlNamed(\amp)) {
					// TODO: or multiply amp with command main volume (??)
					// TODO: if excluded from commands also free controlBus
					controlsToExposeAsCommands = controlsToExposeAsCommands.reject { |control| control.name == \amp };
				};

				this.addCommand(
					"noteOn",
					"ii", // midinote + velocity
					{ |msg|
						var midinote = msg[1];
						var velocity = msg[2];
						var noteOnArgs = [\gate, 1, \freq, midinote.midicps].addAll(args);
						if (synthDesc.hasControlNamed(\amp)) {
							noteOnArgs = [\amp, \midivelocity.asSpec.unmap(velocity)].addAll(noteOnArgs); // TODO: fix amp curve
						};
						this.class.trace(\noteOnArgs, noteOnArgs);
						context.server.makeBundle(nil, {
							synths[midinote] !? _.release;
							synths[midinote] = Synth(
								synthDesc.name,
								args: noteOnArgs,
								target: context.xg
							);
						});
					}
				);
				this.addCommand(
					"noteOff",
					"i", // midinote
					{ |msg|
						var midinote = msg[1];
						synths[midinote] !? _.release;
						synths[midinote] = nil;
					}
				);
				this.addCommand(
					"allNotesOff",
					"",
					{ |msg|
						synths do: _.release;
					}
				);
				this.addCommand(
					"polyphony",
					"i",
					{ |msg|
						// if polyphony is set to less than before, kill currentrunning - polyphony synths (the "oldest")
					}
				);
				this.addCommand(
					"unison",
					"",
					{ |msg|
						// kill currentrunning synths - all
					}
				);
				this.addCommand(
					"unisonDetune",
					"f", // detune
					{ |msg|
						// TODO: checkout \detune.asSpec -20 +20 hz
						// detune all currentrunning synths ?
					}
				);
				if (synthDesc.hasControlNamed(\pan)) {
					this.addCommand(
						"unisonSpread",
						"f", // stereo spread
						{ |msg|
							// spread currentrunning synths ?
						}
					);
				};
			}
*/
			{\polyphonicReuseSynths} {
				// a synth having a gate argument is considered polyphonic, but synths cannot free themselves hence [polyphony] number of synths are spawned and reused (good for deterministic engine performance characteristics)
				// args = args.addAll([\gate, 0]);
				// context.server.sync;
				this.addCommand(
					"gate",
					"if",
					{ |msg|
						var voicenum = msg[1];
						var gate = msg[2];
						
						if (voicenum < polyphony) {
							synths[voicenum].set(\gate, gate);
						} {
							"gate command ignored: voicenum % referred, only % voices available".format(voicenum, polyphony).warn;
						};
					}
				);
				if (synthDesc.hasControlNamed(\freq)) {
					this.addCommand(
						"noteOn",
						"if",
						{ |msg|
							synths[msg[1]].set(\gate, 1, \freq, msg[2]); // TODO: or midinote?
						}
					);
					this.addCommand(
						"noteOff",
						"i",
						{ |msg|
							synths[msg[1]].set(\gate, 0);
						}
					);
				};
				this.addCommand(
					"polyphony",
					"i",
					{ |msg|
						this.polyphonicReuseSynthsRespawnSynths(polyphony = msg[1]);
					}
				);
			};

		if (synthDesc.hasControlNamed(\bufnum)) {
			this.addCommand(
				"buffers", // TODO: naming? what about channel count? delegated to SynthDef / Engine creator?
				"i",
				{ |msg|
	 				// TODO: free / allocate buffers as needed, probably free all also
				}
			);
			this.addCommand(
				"loadSample", // TODO: naming? what about channel count? delegated to SynthDef / Engine creator?
				"is",
				{ |msg|
					// TODO: bufnum implies buffers are used, so command to load buffers is exposed
	 				// TODO: bufnum index must be offset / made correct i -> real bufnum
				}
			);
		};

		context.server.sync;

		specs = synthDesc.metadata !? { |metadata| metadata.specs } ? ();
		// this.class.trace(\specs, specs);

		args = this.addCommandsForControlsToExposeAsCommands(controlsToExposeAsCommands, specs, args);

		this.class.trace(\argsComplete, args);

		context.server.sync; // TODO: don't think this is needed, test

		switch (type)
		{\persistent} {
			// 1:1 synth and engine, synth is spawned until engine is changed

			synths = [ Synth(synthDesc.name, args: args, target: context.xg) ];
		}
/*
		{\polyphonicFreeSelf} {
			synths = Array.fill(128); // TODO: number of midi notes - should be limited by polyphony
		}
*/
		{\polyphonicReuseSynths} {
			// args = args.addAll([\gate, 0]); TODO: shouldn't be needed, there's a controlBus for this probably set to 0
			savedArgs = args;
			this.polyphonicReuseSynthsRespawnSynths(polyphony = defaultPolyphony);
		};

		context.server.sync;
	}

    autorouteInputs { |controlName, args|
		^if (controlName.notNil) { args.addAll([controlName, context.in_b]) } { args }
    }

    autorouteOutputs { |controlName, args|
		^if (controlName.notNil) { args.addAll([controlName, context.out_b]) } { args } // TODO: fix mono -> stereo ?
    }

    autorouteAmplitudeEnvelope { |args|
		// autoroute input amp envelope (would be better to allocate adjacent stereo busses in AudioContext and bundle these into one for SynthDesc control named \amp_env
		if (synthDesc.hasControlNamed(\amp_env0)) {
			args = args.addAll([\amp_env0, context.amp_in_b[0].asMap]);
		};

		if (synthDesc.hasControlNamed(\amp_env1)) {
			args = args.addAll([\amp_env1, context.amp_in_b[1].asMap]);
		};
        ^args;
    }

    autoroutePitchTracker { |args|
		// autoroute pitch tracker (would be better to allocate adjacent stereo busses in AudioContext and bundle these into one for SynthDesc control named \pitch
		if (synthDesc.hasControlNamed(\pitch_trk0)) {
			args = args.addAll([\pitch_trk0, context.pitch_in_b[0].asMap]);
		};

		if (synthDesc.hasControlNamed(\pitch_trk1)) {
			args = args.addAll([\pitch_trk1, context.pitch_in_b[1].asMap]);
		};
        ^args;
    }

	addCommandsForControlsToExposeAsCommands { |controls, specs, args|
		controls.do { |control|
			var controlName = control.name;
			var spec;
			var busArgs;
			this.class.trace(\controlName, controlName);
			spec = if (specs[controlName].notNil) { specs[controlName].asSpec } { controlName.asSpec };
			controlBusses[controlName] = Bus.control;
			if (spec.notNil) {
				spec.default !? { |default|
					controlBusses[controlName].set(default); // TODO: right now spec default is picked up, but not argument default (ie. index = 3 above)
				};
			};
			busArgs = [controlName, controlBusses[controlName].asMap];
			args = args.addAll(busArgs);
			this.class.trace(\controlBusArg, busArgs);
			this.addCommand( // TODO: these controls are suited as possible direct-to-scsynth commands
				controlName.asString,
				"f",
				if (spec.notNil) {
					{ |msg|
						var value = msg[1];
						var constrainedValue = spec.constrain(value);
						this.class.trace(\speccedControlBusCommand, [controlName, controlBusses[controlName], value, constrainedValue]);
						controlBusses[controlName].set(constrainedValue);
					}
				} {
					{ |msg|
						var value = msg[1];
						this.class.trace(\unspeccedControlBusCommand, [controlName, controlBusses[controlName], value]);
						controlBusses[controlName].set(value);
					}
				}
			);
		};
		^args;
	}

	polyphonicReuseSynthsRespawnSynths { |polyphony|
		synths do: _.free;
		synths = polyphony.collect { Synth.tail(context.xg, synthDesc.name, savedArgs) };
	}

	free {
		(thisMethod.ownerClass.asString ++ "." ++ thisMethod.name.asString).debug(\pre);
		synths do: _.free;
		controlBusses do: _.free;
		buffers do: _.free;
		super.free;
		(thisMethod.ownerClass.asString ++ "." ++ thisMethod.name.asString).debug(\post);
	}

/*
	(make CroneGenEngine a subclass of CroneEngine)

	*new { |context, callback| ^super.new(context, callback).initCroneGenEngine }

	initCroneGenEngine {
		var synthDef, synthDesc;
		synthDef = this.synthDef;

		if (synthDef.name == 'nil') { // TODO: even needed, or should this simply be overwritten to classname?
			synthDef.name = this.asString.asSymbol;
		};
		synthDef.add;
		synthDesc=SynthDescLib.global[synthDef.name];

		CroneSynthDefIntrospectionEngine.new(context, synthDesc);
		^super.new.initCroneGenEngine(context);
	}
*/
	*synthDef {
        ^if (this.ugenGraphFunc.notNil) {
            var synthDef = this.wrapOut(
				// TODO: effectively filter out synthdefs from automatic lookup in Crone?
                ("No_" ++ this.name.asString).asSymbol, // TODO: assumes class name has Engine_ prefix (this could be validated)
                this.ugenGraphFunc,
                this.rates, // TODO: remove this, assume all rates kr
                this.prependArgs // TODO: needed at all?
            );
            synthDef.metadata = this.specs !? { |specs| (specs: specs.asDict) };
			synthDef;
/*
		TODO: below is support for in-memory and on-disk synthdefs based on symbol in *defName
        } {
			this.defName !? { |defName|
				var synthDesc;
				synthDesc = SynthDescLib.global.synthDescs[defName];
				if (synthDesc.notNil) {
					"synthdef % found in memory".format(defName).inform;
					^synthDesc.def;
				} {
					var path = thisProcess.platform.userAppSupportDir + "synthdefs" +/+ defName ++ ".scsyndef";
					if (PathName(path).isFile) {
						"synthdef % found on disk".format(defName).inform;
						SynthDescLib.global.read(path);
						"synthdef % read from file %".format(defName, path).inform;
						if (synthDesc.notNil) {
							^synthDesc.def;
						};
					} {
						"synthdef % not found on disk".format(defName).inform;
					}
				}
			}
*/
		};
	}

    *ugenGraphFunc { ^nil }
    *specs { ^nil }
    *rates { ^nil } // TODO: remove this, assume all rates kr
    *prependArgs { ^nil } // TODO: needed at all?

    // adapted from *wrapOut in GraphBuilder
    *wrapOut { arg name, func, rates, prependArgs, outClass=\Out, fadeTime;
        ^SynthDef.new(name, { arg i_out=0;
            var result, rate, env;
            result = SynthDef.wrap(func, rates, prependArgs).asUGenInput;
            rate = result.rate;
            if(rate.isNil or: { rate === \scalar }) {
                // Out, SendTrig, [ ] etc. probably a 0.0
                result
            } {
                if(fadeTime.notNil) {
                    result = this.makeFadeEnv(fadeTime) * result;
                };
                outClass = outClass.asClass;
                outClass.replaceZeroesWithSilence(result.asArray);
                outClass.multiNewList([rate, i_out]++result)
            }
        })
    }

	*trace { |what, args|
		if (debug) { args.debug(what) };
	}
}

CroneSynthDefIntrospectionUtil {
	*inspectSynthDesc { |synthDesc|
		var type = (case
			{ synthDesc.hasControlNamed(\gate) and: synthDesc.canFreeSynth.not } {
				\polyphonicReuseSynths
			}
			{ synthDesc.hasControlNamed(\gate) and: synthDesc.canFreeSynth } {
				\polyphonicFreeSelf
			} ? \persistent).debug(\type);

		var inControlName = this.retrieveInputControlName(synthDesc).debug(\inControlName);
		var outControlName = this.retrieveOutputControlName(synthDesc).debug(\outControlName);
		var controlsToExposeAsCommands = synthDesc.controls.reject { |control|
			[
				'gate',
				// TODO: 'freq', or 'midinote', ??
				inControlName,
				outControlName, // TODO: was 'out', instead check output_data and filter out correct out argument
				'amp_env0',
				'amp_env1',
				'pitch_trk0',
				'pitch_trk1'
			].includes(control.name)
		}.debug(\controlsToExposeAsCommands);

		^(
			type: type,
        	inControlName: inControlName,
			outControlName: outControlName,
			ampenvControls: [],
			pitchtrkControls: [],
			controlsToExposeAsCommands: controlsToExposeAsCommands
		);
	}

    *retrieveInputControlName { |synthDesc|
        ^this.detectMonoOrStereoAudioIO(synthDesc.inputs) !? { |iodesc| iodesc.startingChannel }
    }

    *retrieveOutputControlName { |synthDesc|
        ^this.detectMonoOrStereoAudioIO(synthDesc.outputs) !? { |iodesc| iodesc.startingChannel }
    }

    *detectMonoOrStereoAudioIO { |iodescs|
        ^iodescs.detect { |iodesc|
            (iodesc.rate == 'audio')
            and:
            (iodesc.numberOfChannels < 3)
            and:
            (iodesc.startingChannel.class == Symbol)
        }
    }
}

+ SynthDesc {
	hasControlNamed { |controlName|
		^this.controls.any {|control| control.name == controlName};
	}
}
