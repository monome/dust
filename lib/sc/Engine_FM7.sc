// CroneEngine_FM7
// A DX7 Frequency Modulation synth model
Engine_FM7 : CroneEngine {
  var <synth;

  classvar <polyDef;
  classvar <paramDefaults;
  classvar <maxNumVoices;

  var <ctlBus;
  var <mixBus;
  var <gr;
  var <voices;

  *initClass {
    maxNumVoices = 16;
    // StartUp registers functions to perform an action after the library has been compiled, and after the startup file has run.
    StartUp.add {
      polyDef = SynthDef.new(\polyFM7, {
        // args for whole instrument
        arg out, amp=0.2, amplag=0.02, gate=1, hz,
        // operator frequencies
        hz1=440, hz2=220, hz3=0, hz4=0, hz5=0, hz6=0,
        // operator amplitudes
        amp1=1,amp2=0.5,amp3=0.3,amp4=1,amp5=1,amp6=1,
        // operator phases
        phase1=0,phase2=pi/2,phase3=0,phase4=0,phase5=0,phase6=0,
        // envelope for each voice
        ampAtk=0.05, ampDec=0.1, ampSus=1.0, ampRel=1.0, ampCurve=-1.0;

        var ctrls, mods, osc, snd, aenv;

        // the 6 oscillators, their frequence, phase and amplitude
        ctrls = [[ Lag.kr(hz1,0.01), phase1, Lag.kr(amp1,0.01) ],
                 [ Lag.kr(hz2,0.01), phase2, Lag.kr(amp2,0.01) ],
                 [ Lag.kr(hz3,0.01), phase3, Lag.kr(amp3,0.01) ],
                 [ Lag.kr(hz4,0.01), phase4, Lag.kr(amp4,0.01) ],
                 [ Lag.kr(hz5,0.01), phase5, Lag.kr(amp5,0.01) ],
                 [ Lag.kr(hz6,0.01), phase6, Lag.kr(amp6,0.01) ]];

        // All the operaters modulation params, this is 36 params, which could be exposed and mapped to a Grid.
        mods = [[0,0,0,0,0,0],
                [0,0,0,0,0,0],
                [0,0,0,0,0,0],
                [0,0,0,0,0,0],
                [0,0,0,0,0,0],
                [0,0,0,0,0,0]];

        // The FM7 class also has a .algoAr() method which implements all 32 algorithms in the DX7
        osc = FM7.ar(ctrls,mods);     
        amp = Lag.ar(K2A.ar(amp), amplag);
        aenv = EnvGen.ar(
                  Env.adsr( ampAtk, ampDec, ampSus, ampRel, 1.0, ampCurve),
                  gate, doneAction:2);
        Out.ar(out, (osc * amp * aenv).dup);
      });

      // Tell Crone about our SynthDef
      CroneDefs.add(polyDef);

      // this is exposed as a class variable and it's how we get all the params exposed to Maiden (Matron?) 
      paramDefaults = Dictionary.with(
        \amp -> -12.dbamp, \amplag -> 0.02,
        \hz1 -> 440, \hz2 -> 220, \hz3 -> 0, \hz4 -> 0, \hz5 -> 0, \hz6 -> 0,
        \amp1 -> 1,\amp2 -> 0.5,\amp3 -> 0.3,\amp -> 1,\amp5 -> 1,\amp6 -> 1,
        \phase1 -> 0,\phase2 -> pi/2,\phase3 -> 0,\phase4 -> 0,\phase5 -> 0,\phase6 -> 0,
        \ampAtk -> 0.05, \ampDec -> 0.1, \ampSus -> 1.0, \ampRel -> 1.0, \ampCurve -> -1.0;       
      );
    }
  }

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    gr = ParGroup.new(context.xg);
    
    // put our voices into a dictionary
    voices = Dictionary.new;
    // put our control bug into a dictionary
    ctlBus = Dictionary.new;

    polyDef.allControlNames.do({ arg ctl;
      var name = ctl.name;
      postln("control name: " ++ name);
      // weird logic here. These params are not in paramDefaults so why not loop through that collection?
      if((name != \gate) && (name != \hz) && (name != \out), {
        ctlBus.add(name -> Bus.control(context.server));
        ctlBus[name].set(paramDefaults[name]);
      });
    });
    ctlBus.postln;

    ctlBus[\level].setSynchronous( 0.2 );

    this.addCommand(\start, "if", { arg msg;
      this.addVoice(msg[1], msg[2], true);
    });

    this.addCommand(\solo, "i", { arg msg;
      this.addVoice(msg[1], msg[2], false);
    });

    this.addCommand(\stop, "i", { arg msg;
      this.removeVoice(msg[1]);
    });

    this.addCommand(\stopAll, "", { 
      gr.set(\gate,0);
      voices.clear;
    });

    // another loop to expose everything in the ctlBus dictionary as a param to Matron
    ctlBus.keys.do({ arg name;
      this.addCommand(name, "f", {arg msg; ctlBus[name].setSynchronous(msg[1]); });
    });
  }

  addVoice { arg id, hz, map=true;

  }

  removeVoice { arg id;

  }

  free {

  }
}
