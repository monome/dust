// scapes

// granular delay
// oscillator / ringmod bank
// distortion / filter / reverb bus ?

Engine_Scapes {

	classvar <num_grain_del;
	classvar <num_osc;

	var <grain_del; // array of GrainDelayVoices


	*initClass {
		num_grain_del = 4;
		num_osc = 16;
	}

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		var c = Crone.ctx;
		var s = Crone.server;

		grain_del = Array.fill(num_grain_del, {
			GrainDelayVoice.new(s, c.in_b[0], c.out_b[0], c.xg);
		});


		// #[\hz, \amp, \pan, \amplag, \hzlag, \panlag].do({
		// 	arg name;
		// 	this.addCommand(name, "if", {
		// 		arg msg;
		// 		var i = msg[1] -1;
		// 		if(i<num && i >= 0, {
		// 			synth[msg[1]].set(name, msg[2]);
		// 		});
		// 	});
		// });

	}

	free {
		grain_del.do({ |gd| gd.free; });
		super.free;
	}


}

