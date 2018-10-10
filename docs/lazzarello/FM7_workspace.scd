// UGens featured in the Engine
/*
FM7
Lag
StartUp
Dictionary
ParGroup
NodeWatcher
ControlSpec
OutputProxy
ArrayedCollection
*/
(pi).postln;
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
	var algo = 31;
    var ctls = [
        // freq, phase, amp
        [LFNoise1.kr(0.5).range(300, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1]
    ];
    //FM7.arAlgo(algo, ctls, MouseX.kr(0, 2));
	FM7.arAlgo(algo, ctls, 0);
}.play
/*
algo 1
[ [ [ 0, 1, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 1, 0, 0 ], [ 0, 0, 0, 0, 1, 0 ], [ 0, 0, 0, 0, 0, 1 ], [ 0, 0, 0, 0, 0, 0 ] ], [ 0, 2 ] ]
algo 2
[ [ [ 0, 1, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 1, 0, 0 ], [ 0, 0, 0, 0, 1, 0 ], [ 0, 0, 0, 0, 0, 1 ], [ 0, 0, 0, 0, 0, 0 ] ], [ 0, 2 ] ]
algo 3
[ [ [ 0, 1, 0, 0, 0, 0 ], [ 0, 0, 1, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 1, 0 ], [ 0, 0, 0, 0, 0, 1 ], [ 0, 0, 0, 0, 0, 0 ] ], [ 0, 3 ] ]
algo 32
[ [ [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ] ], [ 0, 1, 2, 3, 4, 5 ] ]

*/
)

(
{
    var ctls, mods, chans;

    ctls = [
        // freq, phase, amp
        [LFNoise1.kr(0.5).range(300, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1]
    ];

    mods = [
[ 0, 1, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 1, 0, 0 ], [ 0, 0, 0, 0, 1, 0 ], [ 0, 0, 0, 0, 0, 1 ], [ 0, 0, 0, 0, 0, 0 ]
    ];
    chans = [ 0, 1, 2, 3, 4, 5 ] ;
    FM7.ar(ctls, mods).slice(chans) * -12.dbamp; // using "slice" to select specific channels
}.play;
)