// Engine_Sines
// a lot of sines
Engine_Sines : CroneEngine {
	classvar num;
	var <synth;

	*initClass {  num = 64; }

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		var server = Crone.server;
		var def = SynthDef.new(\sine, {
			arg out, hz=220, amp=0.0, amplag=0.01, hzlag=0.005, pan=0, panlag=0.005;
			var amp_, hz_, pan_;
			amp_ = Lag.ar(K2A.ar(amp), amplag);
			hz_ = Lag.ar(K2A.ar(hz), hzlag);
			pan_ = Lag.ar(K2A.ar(pan), panlag);
			Out.ar(out, Pan2.ar(SinOsc.ar(hz_) * amp_, pan));
		});
		def.send(server); 
		server.sync;
		
		synth = Array.fill(num, { Synth.new(\sine, [\out, context.out_b], target: context.xg) });

		#[\hz, \amp, \pan, \amplag, \hzlag, \panlag].do({
			arg name;
			this.addCommand(name, "if", {
				arg msg;
				var i = msg[1] -1;
				if(i<num && i >= 0, { 
					synth[msg[1]].set(name, msg[2]);
				});
			});
		});

	}

	free {
		synth.do({ |syn| syn.free; });
		super.free;
	}
}
