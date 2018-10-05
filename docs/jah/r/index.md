---
---

# R

Text based patching engine

## Features

- Freely patch audio generators and processors (_modules_).
- Control module parameters from Lua scripting layer (_set_ and related commands).

## Commands

- `new ss` - creates module named `[arg1]` of type `[arg2]`. See section "Available Modules" below.
	- Examples: `new Osc SquareOsc`, `new Out SoundOut`
- `delete s` - removes module named `[arg1]`.
	- Example: `delete Osc`
- `connect ss` - send module output referenced in `[arg1]` (expressed as `[ModuleName]/[Output]`) to module input referenced in `[arg2]` (expressed as `[ModuleName]/[Input]`).
	- Examples: `connect Osc/Out Out/Left`, `connect Osc/Out Out/Right`
- `disconnect ss` - disconnect module output referenced in `[arg1]` (expressed as `[ModuleName]/[Output]`) from module input referenced in `[arg2]` (expressed as `[ModuleName]/[Input]`).
	- Example: `disconnect Osc/Out Out/Left`
- `set sf` - sets module parameter referenced in `[arg1]` (expressed as `[ModuleName].[Parameter]`) to `[arg2]`.
	- Examples: `set Osc.Frequency 432`, `set Osc.PulseWidth 0.5`
- `trace i` - determines whether to post debug output in sclang Post Window (1 means yes, 0 no)

### Commands for optimized OSC messaging

- `polyset sfi` - sets parameters for a number of modules by convention suffixed with an index (1..`[arg3]`).
	- Example: `polyset Osc.Frequency 220 3` is the same thing as sending `set Osc1.Frequency 220`, `set Osc2.Frequency 220`, `set Osc3.Frequency 220`.
- `bulkset s` - sets module parameters in bulk serialized in a string.
	- Example: `bulkset "Osc.Frequency 432 Osc.PulseWidth 0.5"` is the same thing as sending `set Osc.Frequency 432` and `set Osc.PulseWidth 0.5` TODO: floating point precision?
- `bulkpolyset si` - sets module parameters in bulk for a number of modules by convention suffixed with an index (1..`[arg2]`).
	- Example: `bulkpolyset "Osc.Frequency 432 Osc.PulseWidth 0.5" 3` is the same thing as sending `set Osc1.Frequency 432`, `set Osc1.PulseWidth 0.5`, `set Osc2.Frequency 432`, `set Osc2.PulseWidth 0.5`, `set Osc3.Frequency 432` and `set Osc3.PulseWidth 0.5`

## Available Modules

### ADSREnv

ADSR Envelope inspired by A-140.

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
- Outputs: `Out` - TODO: By convention -0.5 to 0.5
- Parameters:
	- `Level`

### DAmp

Amplifier inspired by A-130/A-131.

- Inputs: `GainModulation`, `In1`, `In2`
- Outputs: `Out`
- Parameters:
	- `Gain`
	- `GainModulation`
	- `In1`
	- `In2`
	- `Out`
	- `Mode`

### Delay
- Inputs: `In`, `DelayTimeModulation`
- Outputs: `Out`
- Parameters:
	- `DelayTime`
	- `DelayTimeModulation`

### FreqGate

CV/Gate thing (TODO)

- Inputs: None
- Outputs: `Frequency`, `Gate`, `Trig` - TODO: By convention 0.1 per octave
- Parameters:
	- `Frequency`
	- `Gate`

### FreqModGate

CV/Gate thing (TODO)

- Inputs: None
- Outputs: `Frequency`, `Gate`, `Mod1`, `Mod2`, `Trig`
- Parameters:
	- `Frequency`
	- `Gate`
	- `Mod1`
	- `Mod2`

### FreqShift
- Inputs: `Left`, `Right`, `FM`
- Outputs: `Left`, `Right`
- Parameters:
	- `Frequency`
	- `FM`

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

### LPMoog

Lowpass Moog ladder filter.

- Inputs: `In`, `FM`, `ResonanceModulation`
- Outputs: `Out`
- Parameters:
	- `Frequency`
	- `Resonance`
	- `FM`
	- `ResonanceModulation`

### MGain

Mono amplifier with mute parameter and dB gain.

- Inputs: `In`
- Outputs: `Out`
- Parameters:
	- `Gain`
	- `Mute`

### MMFilter

Multimode SVF filter inspired by A-121.

- Inputs: `In`, `FM`, `ResonanceModulation`
- Outputs: `Notch`, `Highpass`, `Bandpass`, `Lowpass`
- Parameters:
	- `AudioLevel`
	- `Frequency`
	- `Resonance`
	- `FM`
	- `ResonanceModulation`

### Matrix4x4

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

### Mixer

Mixer module inspired by A-138A/A-138B.

- Inputs: `In1`, `In2`, `In3`, `In4`
- Outputs: `Out`
- Parameters:
	- `In1`
	- `In2`
	- `In3`
	- `In4`
	- `Out`
	- `Mode`

### MultiLFO

LFO with multiple waveform outputs.

- Inputs: `FM`, `PWM`
- Outputs: `Sine`, `Triangle`, `Saw`, `Square`
- Parameters:
	- `Frequency`
	- `PulseWidth`
	- `FM`
	- `PWM`

### MultiLFO2

LFO with multiple waveform outputs inspired by A-145.

- Inputs: `Reset`
- Outputs: `InvSaw`, `Saw`, `Sine`, `Triangle`, `Square`
- Parameters:
	- `Frequency`
	- `Reset`

### MultiOsc

Oscillator inspired by A-110. Note: Triangle waveform is not band limited.

- Inputs: `FM`, `PWM`
- Outputs: `Sine`, `Triangle`, `Saw`, `Square`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`
	- `PulseWidth`
	- `PWM`

### Noise

Noise generator.

- Inputs: None
- Outputs: `Out`
- Parameters: None

### OGain

8-in/8-out amplifier with mute parameter and dB gain.

- Inputs: `In1`, `In2`, `In3`, `In4`, `In5`, `In6`, `In7`, `In8`
- Outputs: `Out1`, `Out2`, `Out3`, `Out4`, `Out5`, `Out6`, `Out7`, `Out8`
- Parameters:
	- `Gain`
	- `Mute`

### PitchShift

- Inputs: `Left`, `Right`, `PitchRatioModulation`, `PitchDispersionModulation`, `TimeDispersionModulation`
- Outputs: `Left`, `Right`
- Parameters:
	- `PitchRatio`
	- `PitchDispersion`
	- `TimeDispersion`
	- `PitchRatioModulation`
	- `PitchDispersionModulation`
	- `TimeDispersionModulation`

### QGain

4-in/4-out amplifier with mute parameter and dB gain.

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

Stereo amplifier with mute parameter and dB gain.

- Inputs: `Left`, `Right`
- Outputs: `Left`, `Right`
- Parameters:
	- `Gain`
	- `Mute`

### SampleHold
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

### SquareOsc

Square oscillator.

- Inputs: `FM`, `PWM`
- Outputs: `Out`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`
	- `PulseWidth`
	- `PWM`

### TestGen
- Inputs: None
- Outputs: `Out`
- Parameters:
	- `Frequency`
	- `Amplitude`
	- `Wave`

### TriOsc

Triangle oscillator. Note: not band-limited.

- Inputs: `FM`
- Outputs: `Out`
- Parameters:
	- `Range`
	- `Tune`
	- `FM`

## Considerations

- Modules can be connected to feedback but a delay of one processing buffer (64 samples) is introduced. There is no single-sample feedback.
- Shooting a lot of commands to R may cause messages to be delayed.

## Example Usage

```
[TODO]
```

## Extending R

[TODO]
