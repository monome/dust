---
---

# R

Text based patching engine

## Features

- Freely patch audio generators and processors (_modules_).
- Control module parameters from Lua scripting layer (_set_ and related commands).

## Basic Commands

- `new ss` - creates module named `[arg1]` of type `[arg2]`. See section "Available Modules" below.
	- Examples: `new Osc MultiOsc`, `new Out SoundOut`
- `delete s` - removes module named `[arg1]`.
	- Example: `delete Osc`
- `connect ss` - send module output referenced in `[arg1]` (expressed as `[ModuleName]/[Output]`) to module input referenced in `[arg2]` (expressed as `[ModuleName]/[Input]`).
	- Examples: `connect Osc/Pulse Out/Left`, `connect Osc/Pulse Out/Right`
- `disconnect ss` - disconnect module output referenced in `[arg1]` (expressed as `[ModuleName]/[Output]`) from module input referenced in `[arg2]` (expressed as `[ModuleName]/[Input]`).
	- Example: `disconnect Osc/Out Out/Left`
- `set sf` - sets module parameter referenced in `[arg1]` (expressed as `[ModuleName].[Parameter]`) to `[arg2]`.
	- Examples: `set Osc.Tune -13`, `set Osc.PulseWidth 0.5`

## Bulk Commands

- `bulkset s` - sets module parameters in bulk serialized in a string.
	- Example: `bulkset "Osc.Frequency 432 Osc.PulseWidth 0.5"` is the same thing as sending `set Osc.Frequency 432` and `set Osc.PulseWidth 0.5` TODO: floating point precision?

## Macro Commands

- `newmacro ss` - creates a macro for a list of module parameters, in order to be able to set the list of parameters simultenously to the same value. This requires the parameters to refer to the same spec.
	- Example: `newmacro A "Carrier.Frequency Operator.Frequency"`.
- `macroset sf` - sets parameters for module parameters included in the macro
	- Example: given above macro `macroset A 432` is the same thing as sending `set Carrier.Frequency 432` and `set Operator.Frequency 432`.
- `deletemacro s` - removes a registered macro.
	- Example: `deletemacro A`.

## Debug Commands

- `trace i` - determines whether to post debug output in sclang Post Window (1 means yes, 0 no)

## Available Modules

### 44Matrix
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
- Inputs: `In1`, `In2`, `In3`, `In4`
- Outputs: `Out`
- Parameters:
	- `In1`
	- `In2`
	- `In3`
	- `In4`
	- `Out`

### Delay
- Inputs: `In`, `DelayTimeModulation`
- Outputs: `Out`
- Parameters:
	- `DelayTime`
	- `DelayTimeModulation`

### FMVoice
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
- Inputs: `Left`, `Right`, `FM`
- Outputs: `Left`, `Right`
- Parameters:
	- `Frequency`
	- `FM`

### FreqGate
- Inputs: None
- Outputs: `Frequency`, `Gate`, `Trig`
- Parameters:
	- `Frequency`
	- `Gate`

### LPFilter
- Inputs: `In`, `FM`, `ResonanceModulation`
- Outputs: `Out`
- Parameters:
	- `AudioLevel`
	- `Frequency`
	- `Resonance`
	- `FM`
	- `ResonanceModulation`

### LPLadder
- Inputs: `In`, `FM`, `ResonanceModulation`
- Outputs: `Out`
- Parameters:
	- `Frequency`
	- `Resonance`
	- `FM`
	- `ResonanceModulation`

### LinMixer
- Inputs: `In1`, `In2`, `In3`, `In4`
- Outputs: `Out`
- Parameters:
	- `In1`
	- `In2`
	- `In3`
	- `In4`
	- `Out`

### MGain
- Inputs: `In`
- Outputs: `Out`
- Parameters:
	- `Gain`
	- `Mute`

### MMFilter
- Inputs: `In`, `FM`, `ResonanceModulation`
- Outputs: `Notch`, `Highpass`, `Bandpass`, `Lowpass`
- Parameters:
	- `AudioLevel`
	- `Frequency`
	- `Resonance`
	- `FM`
	- `ResonanceModulation`

### MultiLFO
- Inputs: `Reset`
- Outputs: `InvSaw`, `Saw`, `Sine`, `Triangle`, `Pulse`
- Parameters:
	- `Frequency`
	- `Reset`

### MultiOsc
- Inputs: `FM`, `PWM`
- Outputs: `Sine`, `Triangle`, `Saw`, `Pulse`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`
	- `PulseWidth`
	- `PWM`

### Noise
- Inputs: None
- Outputs: `Out`
- Parameters: None

### OGain
- Inputs: `In1`, `In2`, `In3`, `In4`, `In5`, `In6`, `In7`, `In8`
- Outputs: `Out1`, `Out2`, `Out3`, `Out4`, `Out5`, `Out6`, `Out7`, `Out8`
- Parameters:
	- `Gain`
	- `Mute`

### PShift
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
- Inputs: `FM`, `PWM`
- Outputs: `Out`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`
	- `PulseWidth`
	- `PWM`

### QGain
- Inputs: `In1`, `In2`, `In3`, `In4`
- Outputs: `Out1`, `Out2`, `Out3`, `Out4`
- Parameters:
	- `Gain`
	- `Mute`

### RingMod
- Inputs: `In`, `Carrier`
- Outputs: `Out`
- Parameters: None

### SGain
- Inputs: `Left`, `Right`
- Outputs: `Left`, `Right`
- Parameters:
	- `Gain`
	- `Mute`

### SampHold
- Inputs: `In`, `Trig`
- Outputs: `Out`
- Parameters: None

### SawOsc
- Inputs: `FM`
- Outputs: `Out`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`

### SineLFO
- Inputs: `Reset`
- Outputs: `Out`
- Parameters:
	- `Frequency`
	- `Reset`

### SineOsc
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
- Inputs: `FM`
- Outputs: `Out`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`

### XFader
- Inputs: `InALeft`, `InARight`, `InBLeft`, `InBRight`
- Outputs: `Left`, `Right`
- Parameters:
	- `Fade`
	- `TrimA`
	- `TrimB`
	- `Master`

## Considerations

- Modules can be connected to feedback but a delay of one processing buffer (64 samples) is introduced. There is no single-sample feedback.
- Shooting a lot of commands to R may cause messages to be delayed. Using macros or bulkset commands might help.

## Example Usage

```
-- spawn modules
engine.new("LFO", "MultiLFO")
engine.new("Osc", "PulseOsc")
engine.new("SoundOut", "SoundOut")

-- connect LFO to Osc to modulate its PulseWidth
engine.connect("LFO/Sine", "Osc/PWM")

-- connect oscillator to audio outputs
engine.connect("Osc/Out", "SoundOut/Left")
engine.connect("Osc/Out", "SoundOut/Right")

-- set some parameter values
engine.set("Osc.PulseWidth", 0.25)
engine.set("LFO.Frequency", 0.5)
engine.set("Osc.PWM", 0.2)
```

## The R Lua Module

Prerequisite:

```
local R = require 'jah/r'
```

The R Lua module contains:

1. Specs for all included modules.

```
R.specs.PulseOsc.Tune -- returns ControlSpec.new(-600, 600, "linear", 0, 0, "cents")
```

2. A number of convenience engine functions for working with R and polyphonic modules.

```
R.engine.poly_new("Osc", "MultiOsc", 3) -- creates MultiOsc modules Osc1, Osc2 and Osc3
R.engine.poly_new("Filter", "MMFilter", 3) -- creates MMFilter modules Filter1, Filter2 and Filter3

R.engine.poly_connect("Osc/Saw", "Filter/In", 3) -- connects Osc1/Saw to Filter1/In, Osc2/Saw to Filter2/In and Osc3/Saw to Filter3/In

```

3. Various utility functions.

```
R.util.split_ref("Osc.Frequency") -- returns {"Osc", "Frequency"}
R.util.poly_expand("Osc", 3) -- returns "Osc1 Osc2 Osc3"
```

## Extending R

[TODO]
