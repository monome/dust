// CroneEngine_FM7
// A DX7 Frequency Modulation synth model
Engine_FM7 : CroneEngine {
  var <synth;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    synth = {
      arg out, amp=0.5, amplag=0.02;
      var amp_;
      var ctrls = [[ 300, 0,    1   ],
                   [ 400, pi/2, 1   ],
                   [ 730, 0,    0.5 ],
                   [ 0,   0,    0   ],
                   [ 0,   0,    0   ],
                   [ 0,   0,    0   ]];

      var mods = [[0,0,0,0,0,0],
                  [0,0,0,0,0,0],
                  [0,0,0,0,0,0],
                  [0,0,0,0,0,0],
                  [0,0,0,0,0,0],
                  [0,0,0,0,0,0]];

      amp_ = Lag.ar(K2A.ar(amp), amplag);
      Out.ar(out, (FM7.ar(ctrls,mods) * amp_).dup);
    }.play(args: [\out, context.out_b], target: context.xg);

    this.addCommand("amp", "f", {arg msg;
      synth.set(\amp, msg[1]);
    });
  }

  free {
    synth.free;
  }
}
