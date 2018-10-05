// UGens featured in the Engine
/*
FM7
Lag
StartUp
Dictionary
ParGroup
NodeWatcher
*/

(
var notes, synth, on, off;

MIDIClient.init;
MIDIIn.connectAll;

notes = Array.newClear(128);

synth = SynthDef(\fm7, { | out, freq, amp |
	var ctrl, mod, osc;
	ctrl = [[freq,0,amp],
		[0,0,0],
		[0,0,0],
		[0,0,0],
		[0,0,0],
		[0,0,0]];

	mod = [[0,0,0,0,0,0],
		[0,0,0,0,0,0],
		[0,0,0,0,0,0],
		[0,0,0,0,0,0],
		[0,0,0,0,0,0],
		[0,0,0,0,0,0],
		[0,0,0,0,0,0]];

	osc = FM7.ar(ctrl,mod);
	Out.ar(out, osc);
}).add;

on = MIDIFunc.noteOn({ | veloc,num,chan,src |
	notes[num] = Synth(\fm7, [\freq,num.midicps,
		\amp, veloc * 0.00315
	]);
});

off = MIDIFunc.noteOff({ | veloc, num, chan, src |
	notes[num].release;
});

q = {on.free; off.free };
)
q.value;

(
{
    var ctls = [
        // freq, phase, amp
        [LFNoise1.kr(0.5).range(300, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1]
    ];
    FM7.arAlgo(10, ctls, MouseX.kr(0, 2))
}.play
)

(
{
    var ctls, mods, chans;
	/*
    ctls = [
        // freq, phase, amp
        [LFNoise1.kr(0.5).range(300, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1]
    ];
	*/
	var hz_;
	hz_ = 440;
	//hz_ = Lag.kr(MouseX.kr(60,440), 0.01);
	ctls = [ [ hz_, 0,    1   ],
		  [ hz_ * 2, 0, 0.5   ],
		  [ hz_ * 3.3, 0,    0.5 ],
		  [ 0,   0,    0   ],
		  [ 0,   0,    0   ],
		  [ 0,   0,    0   ] ];

    mods = [
        [0, 0, 0, 0, 0, 0],
		[MouseX.kr(0,0.5), 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0]
    ];
    chans = [0, 1];
    FM7.ar(ctls, mods).slice(chans) * -12.dbamp; // using "slice" to select specific channels
}.play;
)