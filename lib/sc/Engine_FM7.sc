// CroneEngine_FM7
// A DX7 Frequency Modulation synth model
Engine_FM7 : CroneEngine {
  var <synth;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    synth = {
      arg out, hz=440, amp=0.5, amplag=0.02;
      var amp_,hz_, ctrls, mods;
      hz_ = Lag.kr(hz, 0.01);
      ctrls = [[ LFNoise1.kr(0.5).range(300, 310), 0,    1   ],
                   [ hz_, pi/2, 1   ],
                   [ 730, 0,    0.5 ],
                   [ 0,   0,    0   ],
                   [ 0,   0,    0   ],
                   [ 0,   0,    0   ]];

      mods = [[0,0,0,0,0,0],
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

    this.addCommand("hz", "f", {arg msg;
      synth.set(\hz, msg[1]);
    });
  }

  free {
    synth.free;
  }
}
