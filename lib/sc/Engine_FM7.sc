// CroneEngine_FM7
// A DX7 Frequency Modulation synth model
Engine_FM7 : CroneEngine {
  classvar <polyDef;
  classvar <paramDefaults;
  classvar <maxNumVoices;

  var <ctlBus;
  // this is not used in the implementation here. Is this something needed by CroneEngine?
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
        // operator frequencies. these can be partials or custom intervals
        hz1=1, hz2=2, hz3=0, hz4=0, hz5=0, hz6=0,
        // operator amplitudes
        amp1=1,amp2=0.5,amp3=0.3,amp4=1,amp5=1,amp6=1,
        // operator phases
        phase1=0,phase2=0,phase3=0,phase4=0,phase5=0,phase6=0,
        // envelope for each voice
        ampAtk=0.05, ampDec=0.1, ampSus=1.0, ampRel=1.0, ampCurve= -1.0,
        // phase modulation params
        hz1_to_hz1=0, hz1_to_hz2=0, hz1_to_hz3=0, hz1_to_hz4=0, hz1_to_hz5=0, hz1_to_hz6=0,
        hz2_to_hz1=0, hz2_to_hz2=0, hz2_to_hz3=0, hz2_to_hz4=0, hz2_to_hz5=0, hz2_to_hz6=0,
        hz3_to_hz1=0, hz3_to_hz2=0, hz3_to_hz3=0, hz3_to_hz4=0, hz3_to_hz5=0, hz3_to_hz6=0,
        hz4_to_hz1=0, hz4_to_hz2=0, hz4_to_hz3=0, hz4_to_hz4=0, hz4_to_hz5=0, hz4_to_hz6=0,
        hz5_to_hz1=0, hz5_to_hz2=0, hz5_to_hz3=0, hz5_to_hz4=0, hz5_to_hz5=0, hz5_to_hz6=0,
        hz6_to_hz1=0, hz6_to_hz2=0, hz6_to_hz3=0, hz6_to_hz4=0, hz6_to_hz5=0, hz6_to_hz6=0,
	// boolean if the carrier is output
	carrier1=1,carrier2=1,carrier3=0,carrier4=0,carrier5=0,carrier6=0;

        // declare some vars for this scope
        var ctrls, mods, osc, aenv, chans, chan_vec, osc_mix;

        // the 6 oscillators, their frequence, phase and amplitude
        ctrls = [[ Lag.kr(hz * hz1,0.01), phase1, Lag.kr(amp1,0.01) ],
                 [ Lag.kr(hz * hz2,0.01), phase2, Lag.kr(amp2,0.01) ],
                 [ Lag.kr(hz * hz3,0.01), phase3, Lag.kr(amp3,0.01) ],
                 [ Lag.kr(hz * hz4,0.01), phase4, Lag.kr(amp4,0.01) ],
                 [ Lag.kr(hz * hz5,0.01), phase5, Lag.kr(amp5,0.01) ],
                 [ Lag.kr(hz * hz6,0.01), phase6, Lag.kr(amp6,0.01) ]];

        // All the operaters modulation params, this is 36 params, which could be exposed and mapped to a Grid.
        mods = [[hz1_to_hz1, hz2_to_hz1, hz3_to_hz1, hz4_to_hz1, hz5_to_hz1, hz6_to_hz1],
                [hz1_to_hz2, hz2_to_hz2, hz3_to_hz2, hz4_to_hz2, hz5_to_hz2, hz6_to_hz2],
                [hz1_to_hz3, hz2_to_hz3, hz3_to_hz3, hz4_to_hz3, hz5_to_hz3, hz6_to_hz3],
                [hz1_to_hz4, hz2_to_hz4, hz3_to_hz4, hz4_to_hz4, hz5_to_hz4, hz6_to_hz4],
                [hz1_to_hz5, hz2_to_hz5, hz3_to_hz5, hz4_to_hz5, hz5_to_hz5, hz6_to_hz5],
                [hz1_to_hz6, hz2_to_hz6, hz3_to_hz6, hz4_to_hz6, hz5_to_hz6, hz6_to_hz6]];

        // returns a six channel array of OutputProxy objects
        osc = FM7.ar(ctrls,mods);

        chan_vec = [carrier1,carrier2,carrier3,carrier4,carrier5,carrier6];
        osc_mix = Mix.new(chan_vec.collect({|v,i| osc[i]*v}));
        amp = Lag.ar(K2A.ar(amp), amplag);
        // an amplitude envelope with ADSR controls
        aenv = EnvGen.ar(
                  Env.adsr( ampAtk, ampDec, ampSus, ampRel, 1.0, ampCurve),
                  gate, doneAction:2);
        Out.ar(out, (osc_mix * aenv * amp).dup);
      });

      // Tell Crone about our SynthDef
      CroneDefs.add(polyDef);

      // set all the defaults. Why aren't these values the same as the the values for the SynthDef args?
      // DRY it up?
      paramDefaults = Dictionary.with(
        \amp -> -12.dbamp, \amplag -> 0.02,
        \hz1 -> 1, \hz2 -> 2, \hz3 -> 0, \hz4 -> 0, \hz5 -> 0, \hz6 -> 0,
        \amp1 -> 1,\amp2 -> 0.5,\amp3 -> 0.3,\amp -> 1,\amp5 -> 1,\amp6 -> 1,
        \phase1 -> 0,\phase2 -> 0,\phase3 -> 0,\phase4 -> 0,\phase5 -> 0,\phase6 -> 0,
        \ampAtk -> 0.05, \ampDec -> 0.1, \ampSus -> 1.0, \ampRel -> 1.0, \ampCurve -> -1.0,
        \hz1_to_hz1 -> 0, \hz1_to_hz2 -> 0, \hz1_to_hz3 -> 0, \hz1_to_hz4 -> 0, \hz1_to_hz5 -> 0, \hz1_to_hz6 -> 0,
        \hz2_to_hz1 -> 0, \hz2_to_hz2 -> 0, \hz2_to_hz3 -> 0, \hz2_to_hz4 -> 0, \hz2_to_hz5 -> 0, \hz2_to_hz6 -> 0,
        \hz3_to_hz1 -> 0, \hz3_to_hz2 -> 0, \hz3_to_hz3 -> 0, \hz3_to_hz4 -> 0, \hz3_to_hz5 -> 0, \hz3_to_hz6 -> 0,
        \hz4_to_hz1 -> 0, \hz4_to_hz2 -> 0, \hz4_to_hz3 -> 0, \hz4_to_hz4 -> 0, \hz4_to_hz5 -> 0, \hz4_to_hz6 -> 0,
        \hz5_to_hz1 -> 0, \hz5_to_hz2 -> 0, \hz5_to_hz3 -> 0, \hz5_to_hz4 -> 0, \hz5_to_hz5 -> 0, \hz5_to_hz6 -> 0,
        \hz6_to_hz1 -> 0, \hz6_to_hz2 -> 0, \hz6_to_hz3 -> 0, \hz6_to_hz4 -> 0, \hz6_to_hz5 -> 0, \hz6_to_hz6 -> 0,       
	\carrier1 -> 1,\carrier2 -> 1,\carrier3 -> 0,\carrier4 -> 0,\carrier5 -> 0,\carrier6 -> 0;
      );
    }
  }

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  // allocate all the controls and parameters
  alloc {
    // allocate a control group in parallel
    gr = ParGroup.new(context.xg);
    
    // put our voices into a dictionary
    voices = Dictionary.new;
    // put our control bus into a dictionary
    ctlBus = Dictionary.new;

    // loop through all the control names (are these the args from the SynthDef?)
    polyDef.allControlNames.do({ arg ctl;
      var name = ctl.name;
      postln("control name: " ++ name);
      // weird logic here. These params are not in paramDefaults so why not loop through that collection?
      // it looks like we're doing some kind of map filtering
      if((name != \gate) && (name != \hz) && (name != \out), {
        // add this control name to the Bus for the server context
        ctlBus.add(name -> Bus.control(context.server));
        // set this control name to have default value from the first dictionary.
        ctlBus[name].set(paramDefaults[name]);
      });
    });
    ctlBus.postln;

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
    // the output is the out bus of our client context, the pitch is the value of hz
    var params = List.with(\out, context.out_b.index, \hz, hz);
    var numVoices = voices.size;

    if(voices[id].notNil, {
      voices[id].set(\gate,1);
      voices[id].set(\hz, hz);
    }, { 
      if(numVoices < maxNumVoices, { 
        ctlBus.keys.do({ arg name;
          params.add(name);
          params.add(ctlBus[name].getSynchronous);
        });
        // add a new Synth from our SynthDef into the voices dictionary
        // the doneAction:2 param for the envelope should free the synth implicitly
        voices.add(id -> Synth.new(\polyFM7, params, gr));
        // NodeWatcher informs the client of the server state, so we get free voice information from there?
        NodeWatcher.register(voices[id]);
        voices[id].onFree({
          voices.removeAt(id);
        });

        if(map, {
          ctlBus.keys.do({ arg name;
            voices[id].map(name, ctlBus[name]);
          });
        });
      });
    });
  }

  removeVoice { arg id;
    if(true, {
      voices[id].set(\gate,0);
    });
  }

  free {
    gr.free;
    ctlBus.do({ arg bus,i; bus.free; });
  }
}
