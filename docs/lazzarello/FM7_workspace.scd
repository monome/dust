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
	ctls = [ [ LFNoise1.kr(0.5).range(300, 310), 0,    1   ],
  [ hz_, pi/2, 1   ],
  [ 730, 0,    0.5 ],
  [ 0,   0,    0   ],
  [ 0,   0,    0   ],
  [ 0,   0,    0   ] ];

    mods = [
        [Line.kr(0, 0.001, 2), Line.kr(0.1, 0, 4), 0, MouseY.kr(0, 6), 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0]
    ];
    chans = [0, 1];
    FM7.ar(ctls, mods).slice(chans) * -12.dbamp; // using "slice" to select specific channels
}.play;
)