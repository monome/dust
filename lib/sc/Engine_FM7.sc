// CroneEngine_FM7
// A DX7 Frequency Modulation synth model
Engine_FM7 : CroneEngine {
  var <synth;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    synth = {
      arg out, amp=0.5, amplag=0.02,
      hz1=440, hz2=220, hz3=0, hz4=0, hz5=0, hz6=0,
      amp1=1,amp2=0.5,amp3=0.3,amp4=1,amp5=1,amp6=1,
      phase1=0,phase2=pi/2,phase3=0,phase4=0,phase5=0,phase6=0;

      var amp_,ctrls, mods, osc;

      ctrls = [[ Lag.kr(hz1,0.01), phase1, Lag.kr(amp1,0.01) ],
               [ Lag.kr(hz2,0.01), phase2, Lag.kr(amp2,0.01) ],
               [ Lag.kr(hz3,0.01), phase3, Lag.kr(amp3,0.01) ],
               [ Lag.kr(hz4,0.01), phase4, Lag.kr(amp4,0.01) ],
               [ Lag.kr(hz5,0.01), phase5, Lag.kr(amp5,0.01) ],
               [ Lag.kr(hz6,0.01), phase6, Lag.kr(amp6,0.01) ]];

      mods = [[0,0,0,0,0,0],
              [0,0,0,0,0,0],
              [0,0,0,0,0,0],
              [0,0,0,0,0,0],
              [0,0,0,0,0,0],
              [0,0,0,0,0,0]];

      osc = FM7.ar(ctrls,mods);
      amp_ = Lag.ar(K2A.ar(amp), amplag);

      Out.ar(out, (osc * amp_).dup);
    }.play(args: [\out, context.out_b], target: context.xg);

    this.addCommand("amp", "f", {arg msg;
      synth.set(\amp, msg[1]);
    });
    this.addCommand("hz1", "f", {arg msg;
      synth.set(\hz1, msg[1]);
    });
    this.addCommand("hz2", "f", {arg msg;
      synth.set(\hz2, msg[1]);
    });
    this.addCommand("hz3", "f", {arg msg;
      synth.set(\hz3, msg[1]);
    });
    this.addCommand("hz4", "f", {arg msg;
      synth.set(\hz4, msg[1]);
    });
    this.addCommand("hz5", "f", {arg msg;
      synth.set(\hz5, msg[1]);
    });
    this.addCommand("hz6", "f", {arg msg;
      synth.set(\hz6, msg[1]);
    });

  }

  free {
    synth.free;
  }
}
