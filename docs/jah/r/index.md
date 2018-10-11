---
---

# R

General purpose audio patching engine

## Features

- Arbitrarily create and connect audio generators and processors (_modules_).
- Control module parameters from Lua scripting layer.

## Commands

- `new ss <modulename> <moduletype>` - creates a uniquely named module of given type (refer to section "Modules" for available types).
	- Examples: `new Osc MultiOsc`, `new Out SoundOut`
- `connect ss <modulename/output> <modulename/input>` - connects a module output to a module input.
	- Examples: `connect Osc/Pulse Out/Left`, `connect Osc/Pulse Out/Right`
- `disconnect ss <modulename/output> <modulename/input>` - disconnects a module output from a module input.
	- Example: `disconnect Osc/Out Out/Left`
- `set sf <modulename.parameter> <value>` - sets a module parameter to the given value.
	- Examples: `set Osc.Tune -13`, `set Osc.PulseWidth 0.5`
- `delete s <modulename>` - removes a module.
	- Example: `delete Osc`

### Bulk Commands

- `bulkset s <bundle>` - sets multiple module parameters to values given a bundle of `modulename.parameter` `value` pairs serialized as a string.
	- Example: `bulkset "Osc.Tune -1 Osc.PulseWidth 0.7"` has the same effect as sending `set Osc.Tune -1` and `set Osc.PulseWidth 0.7`. All value changes of a bundle are performed at the same time. TODO: floating point precision?

### Macro Commands

- `newmacro ss <macroname> <modulename.parameters...>` - creates a uniquely named macro for simultaneous control of a list of space delimited module parameters. All included parameters should adhere to the same spec.
	- Example: given `SineOsc` and `PulseOsc` modules named `Osc1` and `Osc2` the command `newmacro Tune "Osc1.Tune Osc2.Tune"` defines a new macro controlling `Tune` parameter for both modules.
- `macroset sf <macroname> <value>` - sets value for module parameters included in a macro. Controlling multiple parameters with a macro is more efficient than using multiple `set` commands. It is also faster than using `bulkset`. All value changes of parameters in a macro are performed at the same time.
	- Example: given `Tune` macro above command `macroset Tune 30` has the same effect as commands `set Osc1.Tune 30` and `set Osc2.Tune 30`.
- `deletemacro s <macroname>` - removes a macro.
	- Example: `deletemacro Tune`.

### Debug Commands

- `trace i <boolean>` - determines whether to post debug output in SCLang Post Window (`1` = yes, `0` = no)

## Modules

### 44Matrix

4x4 Matrix

- Inputs: `1`, `2`, `3`, `4`
- Outputs: `1`, `2`, `3`, `4`
- Parameters:
	- `FadeTime`
	- `Gate_1_1`
	- `Gate_1_2`
	- `Gate_1_3`
	- `Gate_1_4`
	- `Gate_2_1`
	- `Gate_2_2`
	- `Gate_2_3`
	- `Gate_2_4`
	- `Gate_3_1`
	- `Gate_3_2`
	- `Gate_3_3`
	- `Gate_3_4`
	- `Gate_4_1`
	- `Gate_4_2`
	- `Gate_4_3`
	- `Gate_4_4`

### 88Matrix

8x8 Matrix

- Inputs: `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`
- Outputs: `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`
- Parameters:
	- `FadeTime`
	- `Gate_1_1`
	- `Gate_1_2`
	- `Gate_1_3`
	- `Gate_1_4`
	- `Gate_1_5`
	- `Gate_1_6`
	- `Gate_1_7`
	- `Gate_1_8`
	- `Gate_2_1`
	- `Gate_2_2`
	- `Gate_2_3`
	- `Gate_2_4`
	- `Gate_2_5`
	- `Gate_2_6`
	- `Gate_2_7`
	- `Gate_2_8`
	- `Gate_3_1`
	- `Gate_3_2`
	- `Gate_3_3`
	- `Gate_3_4`
	- `Gate_3_5`
	- `Gate_3_6`
	- `Gate_3_7`
	- `Gate_3_8`
	- `Gate_4_1`
	- `Gate_4_2`
	- `Gate_4_3`
	- `Gate_4_4`
	- `Gate_4_5`
	- `Gate_4_6`
	- `Gate_4_7`
	- `Gate_4_8`
	- `Gate_5_1`
	- `Gate_5_2`
	- `Gate_5_3`
	- `Gate_5_4`
	- `Gate_5_5`
	- `Gate_5_6`
	- `Gate_5_7`
	- `Gate_5_8`
	- `Gate_6_1`
	- `Gate_6_2`
	- `Gate_6_3`
	- `Gate_6_4`
	- `Gate_6_5`
	- `Gate_6_6`
	- `Gate_6_7`
	- `Gate_6_8`
	- `Gate_7_1`
	- `Gate_7_2`
	- `Gate_7_3`
	- `Gate_7_4`
	- `Gate_7_5`
	- `Gate_7_6`
	- `Gate_7_7`
	- `Gate_7_8`
	- `Gate_8_1`
	- `Gate_8_2`
	- `Gate_8_3`
	- `Gate_8_4`
	- `Gate_8_5`
	- `Gate_8_6`
	- `Gate_8_7`
	- `Gate_8_8`

### ADSREnv

ADSR Envelope.

- Inputs: `Gate`
- Outputs: `Out`
- Parameters:
	- `Attack`
	- `Decay`
	- `Sustain`
	- `Release`
	- `Gate`

### Amp

Simple amplifier with level parameter and exponential or linear gain modulation.

- Inputs: `Exp`, `Lin`, `In`
- Outputs: `Out`
- Parameters:
	- `Level`

### Amp2

Amplifier with two inputs, level parameter and variable exponential or linear gain modulation.

- Inputs: `GainModulation`, `In1`, `In2`
- Outputs: `Out`
- Parameters:
	- `Gain`
	- `GainModulation`
	- `In1`
	- `In2`
	- `Out`
	- `Mode`

### DbMixer

Mixer suited for audio signals.

- Inputs: `In1`, `In2`, `In3`, `In4`
- Outputs: `Out`
- Parameters:
	- `In1`
	- `In2`
	- `In3`
	- `In4`
	- `Out`

### Delay

Delay line.

- Inputs: `In`, `DelayTimeModulation`
- Outputs: `Out`
- Parameters:
	- `DelayTime`
	- `DelayTimeModulation`

### FMVoice

FM voice (TODO: untested)

- Inputs: `Modulation`
- Outputs: `Out`
- Parameters:
	- `Freq`
	- `Timbre`
	- `Osc1Gain`
	- `Osc1Partial`
	- `Osc1Fixed`
	- `Osc1Fixedfreq`
	- `Osc1Index`
	- `Osc1Outlevel`
	- `Osc1_To_Osc1Freq`
	- `Osc1_To_Osc2Freq`
	- `Osc1_To_Osc3Freq`
	- `Osc2Gain`
	- `Osc2Partial`
	- `Osc2Fixed`
	- `Osc2Fixedfreq`
	- `Osc2Index`
	- `Osc2Outlevel`
	- `Osc2_To_Osc1Freq`
	- `Osc2_To_Osc2Freq`
	- `Osc2_To_Osc3Freq`
	- `Osc3Gain`
	- `Osc3Partial`
	- `Osc3Fixed`
	- `Osc3Fixedfreq`
	- `Osc3Index`
	- `Osc3Outlevel`
	- `Osc3_To_Osc3Freq`
	- `Osc3_To_Osc2Freq`
	- `Osc3_To_Osc1Freq`
	- `Mod_To_Osc1Gain`
	- `Mod_To_Osc2Gain`
	- `Mod_To_Osc3Gain`
	- `Mod_To_Osc1Freq`
	- `Mod_To_Osc2Freq`
	- `Mod_To_Osc3Freq`

### FShift

Frequency shifter.

- Inputs: `Left`, `Right`, `FM`
- Outputs: `Left`, `Right`
- Parameters:
	- `Frequency`
	- `FM`

### FreqGate

CV/Gate thing.

- Inputs: None
- Outputs: `Frequency`, `Gate`, `Trig`
- Parameters:
	- `Frequency`
	- `Gate`

### LPFilter

Lowpass SVF filter.

- Inputs: `In`, `FM`, `ResonanceModulation`
- Outputs: `Out`
- Parameters:
	- `AudioLevel`
	- `Frequency`
	- `Resonance`
	- `FM`
	- `ResonanceModulation`

### LPLadder

Lowpass ladder filter.

- Inputs: `In`, `FM`, `ResonanceModulation`
- Outputs: `Out`
- Parameters:
	- `Frequency`
	- `Resonance`
	- `FM`
	- `ResonanceModulation`

### LinMixer

Mixer suited for control signals

- Inputs: `In1`, `In2`, `In3`, `In4`
- Outputs: `Out`
- Parameters:
	- `In1`
	- `In2`
	- `In3`
	- `In4`
	- `Out`

### MGain

Audio fader with db gain control and mute.

- Inputs: `In`
- Outputs: `Out`
- Parameters:
	- `Gain`
	- `Mute`

### MMFilter

Multimode filter.

- Inputs: `In`, `FM`, `ResonanceModulation`
- Outputs: `Notch`, `Highpass`, `Bandpass`, `Lowpass`
- Parameters:
	- `AudioLevel`
	- `Frequency`
	- `Resonance`
	- `FM`
	- `ResonanceModulation`

### MultiLFO

LFO featuring multiple waveforms.

- Inputs: `Reset`
- Outputs: `InvSaw`, `Saw`, `Sine`, `Triangle`, `Pulse`
- Parameters:
	- `Frequency`
	- `Reset`

### MultiOsc

Oscillator featuring multiple waveforms.

- Inputs: `FM`, `PWM`
- Outputs: `Sine`, `Triangle`, `Saw`, `Pulse`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`
	- `PulseWidth`
	- `PWM`

### Noise

White noise generator.

- Inputs: None
- Outputs: `Out`
- Parameters: None

### OGain

8-in/8-out audio fader with db gain control and mute.

- Inputs: `In1`, `In2`, `In3`, `In4`, `In5`, `In6`, `In7`, `In8`
- Outputs: `Out1`, `Out2`, `Out3`, `Out4`, `Out5`, `Out6`, `Out7`, `Out8`
- Parameters:
	- `Gain`
	- `Mute`

### PShift

Pitch shifter.

- Inputs: `Left`, `Right`, `PitchRatioModulation`, `PitchDispersionModulation`, `TimeDispersionModulation`
- Outputs: `Left`, `Right`
- Parameters:
	- `PitchRatio`
	- `PitchDispersion`
	- `TimeDispersion`
	- `PitchRatioModulation`
	- `PitchDispersionModulation`
	- `TimeDispersionModulation`

### PulseOsc

Pulse/square oscillator with pulse width control.

- Inputs: `FM`, `PWM`
- Outputs: `Out`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`
	- `PulseWidth`
	- `PWM`

### QGain

4-in/4-out audio fader with db gain control and mute.

- Inputs: `In1`, `In2`, `In3`, `In4`
- Outputs: `Out1`, `Out2`, `Out3`, `Out4`
- Parameters:
	- `Gain`
	- `Mute`

### RingMod

Ring modulator.

- Inputs: `In`, `Carrier`
- Outputs: `Out`
- Parameters: None

### SGain

2-in/2-out audio fader with db gain control and mute.

- Inputs: `Left`, `Right`
- Outputs: `Left`, `Right`
- Parameters:
	- `Gain`
	- `Mute`

### SampHold

Sample and hold module.

- Inputs: `In`, `Trig`
- Outputs: `Out`
- Parameters: None

### SawOsc

Sawtooth oscillator.

- Inputs: `FM`
- Outputs: `Out`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`

### SineLFO

Sine LFO.

- Inputs: `Reset`
- Outputs: `Out`
- Parameters:
	- `Frequency`
	- `Reset`

### SineOsc

Sine oscillator.

- Inputs: `FM`
- Outputs: `Out`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`

### SoundIn

- Inputs: None
- Outputs: `Left`, `Right`
- Parameters: None

### SoundOut

- Inputs: `Left`, `Right`
- Outputs: None
- Parameters: None

### TestGen

- Inputs: None
- Outputs: `Out`
- Parameters:
	- `Frequency`
	- `Amplitude`
	- `Wave`

### TriOsc

Triangle oscillator (non-bandlimited).

- Inputs: `FM`
- Outputs: `Out`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`

### XFader

Crossfader

- Inputs: `InALeft`, `InARight`, `InBLeft`, `InBRight`
- Outputs: `Left`, `Right`
- Parameters:
	- `Fade`
	- `TrimA`
	- `TrimB`
	- `Master`

## Example Usage

``` lua
-- Spawn three modules
engine.new("LFO", "MultiLFO")
engine.new("Osc", "PulseOsc")
engine.new("SoundOut", "SoundOut")

-- Modulate OSC pulse width by LFO sine wave
engine.connect("LFO/Sine", "Osc/PWM")

-- Hook up oscillator to audio outputs
engine.connect("Osc/Out", "SoundOut/Left")
engine.connect("Osc/Out", "SoundOut/Right")

-- Set module parameter values
engine.set("Osc.PulseWidth", 0.25)
engine.set("LFO.Frequency", 0.5)
engine.set("Osc.PWM", 0.2)
```

See tutorial scripts in `scripts/r_tutorial`, hacks in `scripts/r_hacks` and jah scripts `moln`, `rymd`, `bob` and `shifty` for more elaborate examples.

## The R Lua Module

The R Lua module contains:
- Default specs for all included modules.
- A number of convenience functions for working with the R engine (polyphonic set ups and more).
- Other utility functions.

Require the R module:

``` lua
local R = require 'jah/r'
```

### Module Specs

`R.specs` contains default specs for all modules, ie.:

``` lua
R.specs.MultiOsc.Tune -- returns ControlSpec.new(-600, 600, "linear", 0, 0, "cents")
```

These can be copied and overriden, if needed:

``` lua
local my_testgen_spec = R.specs.TestGen.Frequency:copy() -- returns ControlSpec.WIDEFREQ
my_testgen_spec.minval = 80
my_testgen_spec.maxval = 8000
```

### Engine Functions

``` lua
R.engine.poly_new("Osc", "MultiOsc", 3) -- creates MultiOsc modules Osc1, Osc2 and Osc3
R.engine.poly_new("Filter", "MMFilter", 3) -- creates MMFilter modules Filter1, Filter2 and Filter3

R.engine.poly_connect("Osc/Saw", "Filter/In", 3) -- connects Osc1/Saw to Filter1/In, Osc2/Saw to Filter2/In and Osc3/Saw to Filter3/In
```

### Utility Functions

``` lua
R.util.split_ref("Osc.Frequency") -- returns {"Osc", "Frequency"}
R.util.poly_expand("Osc", 3) -- returns "Osc1 Osc2 Osc3"
```

## Considerations

- Modules can be connected to feedback but a delay of one processing buffer (64 samples) is introduced. There is no single-sample feedback.
- Shooting a lot of commands to too fast R may cause commands to be delayed. Setting parameter values using `macroset` instead of `set`might help.

## Extending R

Modules are written by way of subclassing the `RModule` class. A subclass supplies a unique module type name (by overriding `*shortName`), an array of specs for each module parameter (`*params`) and a SynthDef Ugen Graph function (`*ugenGraphFunc`) whose function arguments prefixed with `param_`, `in_` and `out_` are treated as parameter controls and input and output busses. The R engine will introspect the ugenGraphFunc and together with the parameter specs provide scaffolding necessary to supply parameter values and interconnect modules.

Note: If a dictionary is supplied for a parameter in the `*params` array, its `Spec` key value will be used as spec and its `LagTime` value will be used as fixed lag rate for the parameter.
Annotated example:

``` supercollider
RTestModule : RModule { // subclassing RModule makes this a module

	*shortName { ^'Test' } // module type used in engine new command

	*params { // description of the module parameters
		^[
			'Frequency' -> \widefreq.asSpec, // first parameter
			'FrequencyModulation' -> (
				Spec: \unipolar.asSpec, // second parameter
				LagTime: 0.05 // 50 ms lag
			)
		]
	}

	*ugenGraphFunc { // regular SynthDef ugenGraphFunc function describing DSP
		^{
			|
				in_FM, // will reference a bus to be used for audio input
				out_Out, // will reference a bus to be used for audio output
				param_Frequency, // refer to first parameter's value...
				param_FrequencyModulation // ... and second parameter's value
			|

			var sig_FM = In.ar(in_FM);
			var sig = SinOsc.ar(param_Frequency + (1000 * sig_FM * param_FrequencyModulation)); // linear FM
			Out.ar(out_Out, sig);
		}
	}

}
```

### Updating the R Lua module

To be usable with functions in the R Lua module `R.engine` table module parameter metadata has to be included in the `R.specs` table. `R.specs` can be generated from RModule metadata using the `Engine_R.generateLuaSpecs` method.

Module documentation stubs may be generated using the `Engine_R.generateModulesDocSection` method.

### Gotchas

If one of the parameters of a module has a `ControlSpec` not compatible with Lag (ie. the standard `db` `ControlSpec`) lag time should not be used for any of the parameters. This is a known SuperCollider issue. (TODO: decsribe workaround)

## Status

- Beta-stage. Engine commands are fixed. A few modules are not tested. Expect changes to module parameter/input/output ranges.

