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
Array
Multichannel
Control
Mix
*/
(
SynthDef.new(\polyFM7, {
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
        mods = [[hz1_to_hz1, hz1_to_hz2, hz1_to_hz3, hz1_to_hz4, hz1_to_hz5, hz1_to_hz6],
               [hz2_to_hz1, hz2_to_hz2, hz2_to_hz3, hz2_to_hz4, hz2_to_hz5, hz2_to_hz6],
               [hz3_to_hz1, hz3_to_hz2, hz3_to_hz3, hz3_to_hz4, hz3_to_hz5, hz3_to_hz6],
               [hz4_to_hz1, hz4_to_hz2, hz4_to_hz3, hz4_to_hz4, hz4_to_hz5, hz4_to_hz6],
               [hz5_to_hz1, hz5_to_hz2, hz5_to_hz3, hz5_to_hz4, hz5_to_hz5, hz5_to_hz6],
               [hz6_to_hz1, hz6_to_hz2, hz6_to_hz3, hz6_to_hz4, hz6_to_hz5, hz6_to_hz6]];

        // returns a six channel array of OutputProxy objects
        osc = FM7.ar(ctrls,mods);

        chan_vec = [carrier1,carrier2,carrier3,carrier4,carrier5,carrier6];
        osc_mix = Mix.new(chan_vec.collect({|v,i| osc[i]*v}));
        amp = Lag.ar(K2A.ar(amp), amplag);
        // an amplitude envelope with ADSR controls
        aenv = EnvGen.ar(
                  Env.adsr( ampAtk, ampDec, ampSus, ampRel, 1.0, ampCurve),
                  gate, doneAction:2);
        // the output bus, is this multiplication the right way to do this?
        // oscilator times envelope times vca.
        Out.ar(out, (osc_mix * aenv * amp).dup);
}).add(s);

x = Synth.new(\polyFM7, [\gate, 1, \hz, 330]);
x.set(\hz1, 1.25);
x.set(\hz2, 2.0);
x.set(\hz3, 2.25);
x.set(\hz4, 3.0);
x.set(\hz5, 3.5);
x.set(\hz6, 4.5);

Routine {
	10.do {
		6.do({|i| x.set(("carrier"++(i+1)).asSymbol, 0.2 + 0.5.rand)});
		0.2.wait;
	};
}.play;
)