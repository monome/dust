Engine_Pusher : CroneEngine {
	classvar maxSampleLength = 8;
	classvar delayTimeSpec;
	classvar decayTimeSpec;
	classvar rqSpec;
	classvar cutoffSpec;
	classvar rateSpec;
	classvar volumeSpec;
	classvar percentageSpec;
	classvar resonanceSpec;

	var buffer;
	var sampleLength;
	var recSynth;
	var playSynth;
	var serverLatency;
	var stopRecordingRoutine;
	var startedRecording;

	*initClass {
		rateSpec = ControlSpec(0.125, 8, 'exp', 0, 1, "");
		delayTimeSpec = ControlSpec(0.0001, 3, 'exp', 0, 0.3, "secs");
		decayTimeSpec = ControlSpec(0, 100, 'lin', 0, 1, "secs");
		cutoffSpec = ControlSpec(20, 10000, 'exp', 0, 10000, "Hz");
		volumeSpec = ControlSpec(-60, 0, 'lin', 0, 0, "dB");
		percentageSpec = ControlSpec(0, 100, 'lin', 0, 0, "%");
		resonanceSpec = ControlSpec(0, 100, 'lin', 0, 13, "%");
		rqSpec = \rq.asSpec;
	}

	alloc {
		var monoRecSynthDef;
		var stereoRecSynthDef;
		var playSynthDef;

		monoRecSynthDef = SynthDef(\monoRecord, {
            arg
                in,
                bufnum,
                gate=1,
                monitor
            ;
			// var fade = 0.01; // TODO: move fade env to play
			var env;
			var sig;
			// env = EnvGen.ar(Env.asr(fade, 1, fade), gate, doneAction: Done.freeSelf);
			EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
			sig = In.ar(in) ! 2;
			// sig = sig * env;
			RecordBuf.ar(sig, bufnum, loop: 0);
            Out.ar(monitor, sig);
		}).add;

		stereoRecSynthDef = SynthDef(\stereoRecord, {
            arg
                in, // TODO: assume adjacent in busses and SynthDef.wrap
                bufnum,
                gate=1,
                monitor
            ;
			// var fade = 0.01; // TODO: move fade env to play
			var env;
			var sig;
			// env = EnvGen.ar(Env.asr(fade, 1, fade), gate, doneAction: Done.freeSelf);
			EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
			sig = In.ar(in, 2); // TODO: why are inbusses 2xmono ?
			RecordBuf.ar(sig, bufnum, loop: 0);
            Out.ar(monitor, sig);
		}).add;

/*
    TODO
		var makeRecSynthDef = { |defName, numChannels|
			SynthDef(defName, {
	            arg
	                in,
	                bufnum,
	                gate=1,
	                monitor
	            ;
				// var fade = 0.01; // TODO: move fade env to play
				var env;
				var sig;
				// env = EnvGen.ar(Env.asr(fade, 1, fade), gate, doneAction: Done.freeSelf);
				EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
				sig = In.ar(in, numChannels) ! (numChannels-1); // TODO: why are inbusses 2xmono ?
				// sig = sig * env;
				RecordBuf.ar(sig, bufnum, loop: 0, doneAction: Done.freeSelf);
	            Out.ar(monitor, sig);
			});
		};

		makeRecSynthDef.value(\monoRecord, 1).add;
		makeRecSynthDef.value(\stereoRecord, 2).add;
*/

		playSynthDef = SynthDef(\play, {
			arg
				out,
				bufnum,
				numFrames,
				gate=1,
				phasorFreq=1,
				startPos,
				endPos,
				delaySend,
				delayTime,
				decayTime,
				cutoffFreq,
				rq,
				reverbSend,
				reverbRoom,
				reverbDamp
			;
			var env;
			var playhead;
			var sig;

			env = EnvGen.ar(Env.cutoff(0.01), gate, doneAction: Done.freeSelf);
			playhead = Phasor.ar(0, BufRateScale.kr(bufnum) * phasorFreq * sign(startPos-endPos) * (-1), numFrames*startPos, numFrames*endPos);
			// TODO: add miller puckette-style amp window to remove clicks
			sig = BufRd.ar(2, bufnum, playhead, interpolation: 4);

			sig = RLPF.ar(sig, cutoffFreq, rq);
			sig = sig + CombC.ar(delaySend.dbamp * sig, maxdelaytime: delayTimeSpec.maxval, delaytime: delayTime, decaytime: decayTime);
			sig = sig + FreeVerb2.ar(reverbSend.dbamp * sig, reverbSend.dbamp * sig, 1.0, reverbRoom, reverbDamp);
			Out.ar(out, sig);
		},
            [ // lag times...
                nil, // out
                nil, // bufnum
                nil, // numFrames
                nil, // gate
                0.02, // phasorFreq
                0.1, // startPos
                0.1, // endPos
                0.02, // delaySend
                0.25, // delayTime
                0.02, // decayTime
                0.02, // cutoffFreq
                0.02, // rq
                0.02, // reverbSend
                0.02, // reverbRoom
                0.02 // reverbDamp
            ]).add;

		buffer = Buffer.alloc(numChannels: 2, numFrames: this.maxBufferNumFrames);

		context.server.sync;

		this.addCommand("record", "") { |msg| this.record };
		this.addCommand("play", "") { |msg| this.play };
		this.addCommand("startPos", "f") { |msg| this.startPos(msg[1]) };
		this.addCommand("endPos", "f") { |msg| this.endPos(msg[1]) };
		this.addCommand("speed", "f") { |msg| this.speed(msg[1]) };
		this.addCommand("cutoff", "f") { |msg| this.cutoff(msg[1]) };
		this.addCommand("resonance", "f") { |msg| this.resonance(msg[1]) };
		this.addCommand("delaySend", "f") { |msg| this.delaySend(msg[1]) };
		this.addCommand("delayTime", "f") { |msg| this.delayTime(msg[1]) };
		this.addCommand("decayTime", "f") { |msg| this.decayTime(msg[1]) };
		this.addCommand("reverbSend", "f") { |msg| this.reverbSend(msg[1]) };
		this.addCommand("reverbRoom", "f") { |msg| this.reverbRoom(msg[1]) };
		this.addCommand("reverbDamp", "f") { |msg| this.reverbDamp(msg[1]) };
		this.addCommand("readBuffer", "s") { |msg| this.readBuffer(msg[1]) }; // TODO: use for between-session persistance
		this.addCommand("writeBuffer", "s") { |msg| this.writeBuffer(msg[1]) }; // TODO: use for between-session persistance
	}

	free {
		buffer.free;
		recSynth.release;
		playSynth.release;
		// TODO: probably d_free synthdefs too to really clean up and not cause clashes
	}

	record {
		startedRecording = SystemClock.seconds;
		context.server.makeBundle(serverLatency) {
			recSynth !? _.release;
			playSynth !? {
                playSynth.release;
			    playSynth = nil;
            };
			recSynth = Synth(
                // \monoRecord, // TODO: stereoRecord
                \stereoRecord,
                args: [
                    \in, context.in_b,
                    \bufnum, buffer,
                    \monitor, context.out_b
                ],
                target: context.xg,
                addAction: \addToTail
            );
		};
		postln("started recording");
		stopRecordingRoutine = fork {
			maxSampleLength.wait;
            maxSampleLength.debug(\maxSampleTimeReached);
            this.play;
		};
	}

	play {
		if (startedRecording.notNil) {
			sampleLength = SystemClock.seconds - startedRecording;
			postln("seconds sampled:" + sampleLength);
            stopRecordingRoutine.stop;
		};
		context.server.makeBundle(serverLatency) {
			recSynth !? {
                recSynth.release;
                recSynth = nil;
            };
			playSynth !? _.release;
			playSynth = Synth(
                \play,
                args: [
                    \out, context.out_b,
                    \bufnum, buffer,
                    \numFrames, this.actualBufferNumFrames,

				    \startPos, 0,
				    \endPos, 1,
				    \phasorFreq, 1, // speed
                    // pitch
				    \cutoffFreq, cutoffSpec.default,
				    \rq, rqSpec.map((resonanceSpec.unmap(resonanceSpec.default.debug(\resonance_in)).debug(\resonance_unmapped).neg+1).debug(\resonance_unmapped_neg_plus_1)).debug(\rq_mapped),
				    \delaySend, -60,
				    \reverbSend, -60,
				    \delayTime, delayTimeSpec.default,
				    \decayTime, decayTimeSpec.default,
				    \reverbRoom, 0.5,
				    \reverbDamp, 0.5
                ],
                target: context.xg,
                addAction: \addToHead
            );
		};
	}

	actualBufferNumFrames {
		^(sampleLength*context.server.sampleRate).ceil
	}

	maxBufferNumFrames {
		^(maxSampleLength*context.server.sampleRate).ceil
	}

	writeBuffer { |path| buffer.write(path) }

	readBuffer { |path| buffer.read(path, numFrames: this.actualBufFrames) }

	startPos { |value|
		playSynth !? {
            playSynth.set( \startPos, percentageSpec.unmap(value.debug(\startPos_in)).debug(\startPos_unmapped) )
        };
	}

	endPos { |value|
		playSynth !? {
            playSynth.set( \endPos, percentageSpec.unmap(value.debug(\endPos_in)).debug(\endPos_unmapped) )
        };
	}

	speed { |value|
		playSynth !? {
            playSynth.set( \phasorFreq, rateSpec.constrain(value.debug(\speed_in)).debug(\speed_constrained) )
        };
	}

	cutoff { |value|
		playSynth !? {
            playSynth.set( \cutoffFreq, cutoffSpec.constrain(value.debug(\cutoff_in)).debug(\cutoff_constrained) )
        };
	}

	resonance { |value|
		playSynth !? {
            playSynth.set( \rq, rqSpec.map((percentageSpec.unmap(value.debug(\resonance_in)).debug(\resonance_unmapped).neg+1).debug(\resonance_unmapped_neg_plus_1)).debug(\rq_mapped) )
        };
	}

	delaySend { |value|
		playSynth !? {
			playSynth.set( \delaySend, volumeSpec.constrain(value.debug(\delaySend_in)).debug(\delaySend_constrained) )
		};
	}

	reverbSend { |value|
		playSynth !? {
			playSynth.set( \reverbSend, volumeSpec.constrain(value.debug(\reverbSend_in)).debug(\reverbSend_constrained) )
		};
	}

	delayTime { |value|
		playSynth !? {
			playSynth.set( \delayTime, delayTimeSpec.constrain(value.debug(\delayTime_in)).debug(\delayTime_constrained) )
		};
	}

	decayTime { |value|
		playSynth !? {
			playSynth.set( \decayTime, decayTimeSpec.constrain(value.debug(\decayTime_in)).debug(\decayTime_constrained) )
		};
	}

	reverbRoom { |value|
		playSynth !? {
			playSynth.set( \reverbRoom, percentageSpec.unmap(value.debug(\reverbRoom_in)).debug(\reverbRoom_unmapped) )
		};
	}

	reverbDamp { |value|
		playSynth !? {
            playSynth.set( \reverbDamp, percentageSpec.unmap(value.debug(\reverbDamp_in)).debug(\reverbDamp_unmapped) )
        };
	}

}
