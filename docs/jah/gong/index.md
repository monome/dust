---
---

# Gong

FM synthesizer engine

## Features

- Configurable polyphony.
- 3 intermodulating sine oscillators per voice.
- Resonant high and lowpass filter.
- LFO and ADSR envelope routable to oscillators and filters.

## Commands

_Note: voice numbers are indexed from 0 in commands._

### Triggering

First argument is always voice number.

- `on i` - activate voice (gate on).
- `off i` - release voice (gate off).
- `freqOn if` - activate voice and set voice base frequency.
- `noteOn ii` - activate voice and set voice base frequency according to midi note value.

### Synth Voice Parameters

- `freq if` - set voice base frequency.

### Synth Parameters

The following commands will apply to all synth voices.

*General*

- `timbre f` - oscillator frequency modulation macro control: 0 .. 5. Default is 1.
- `timemod f` - LFO and ADSR envelope attack/decay/sustain macro control: 0 .. 5. Default is 1.

*Oscillator Parameters*

For each oscillator 1 .. 3:

- `osc[oscnum]gain f` - oscillator gain 0 .. 1.
- `osc[oscnum]fixed f` - if set to 1 osc[oscnum]fixedfreq determines oscillator frequency, if set to 0 otherwise osc[oscnum]partial * note on freq. default is 0.
- `osc[oscnum]fixedfreq f` - oscillator frequency when oscillator is fixed. 0.1 .. 20 000 Hz.
- `osc[oscnum]partial f` - determines oscillator frequency multiplier based on noteOn frequency when oscillator is _not_ fixed. 0.5 .. 12. default is 1.
- `osc[oscnum]index f` - oscillator modulation index. 0 .. 24. default is 3.
- `osc[oscnum]outlevel f` - signal out level 0 .. 1.
- `osc1_to_osc[oscnum]freq f` - inter-oscillator modulation amount 0 .. 1. Note: feedback modulation (modulating an osc having an index smaller than the modulating osc) introduce a one block (64 samples) delay.
- `osc2_to_osc[oscnum]freq f` - inter-oscillator modulation amount 0 .. 1. Note: feedback modulation (modulating an osc having an index smaller than the modulating osc) introduce a one block (64 samples) delay.
- `osc3_to_osc[oscnum]freq f` - inter-oscillator modulation amount 0 .. 1. Note: feedback modulation (modulating an osc having an index smaller than the modulating osc) introduce a one block (64 samples) delay.

*Filter and Amp Parameters*

- `lpfcutoff f` - Lowpass filter cutoff 20 .. 10 000 Hz.
- `lpfres f` - Lowpass filter resonance amount 0 .. 1.
- `hpfcutoff f` - Highpass filter cutoff 20 .. 10 000 Hz.
- `hpfres f` - Highpass filter resonance amount 0 .. 1.
- `ampgain f` - Base amplitude level 0 .. 1.

*Envelope and LFO Parameters*

- `envattack f` - ADSR envelope attack time: 0 .. 5 000 ms.
- `envdecay f` - ADSR envelope decay time: 0 .. 5 000 ms.
- `envsustain f` - ADSR envelope sustain level: 0 .. 1.
- `envrelease f` - ADSR envelope release time: 0 .. 5 000 ms.
- `lforate f` - LFO rate: 0.125 .. 8 Hz.

*Envelope and LFO Modulation Parameters*

- `lfo_to_lpfcutoff f` - LFO lowpass filter cutoff modulation: -1 .. 1.
- `lfo_to_lpfres f` - LFO lowpass filter resonance modulation: -1 .. 1.
- `lfo_to_hpfcutoff f` - LFO highpass filter cutoff modulation: -1 .. 1.
- `lfo_to_hpfres f` - LFO highpass filter resonance modulation: -1 .. 1.
- `lfo_to_ampgain f` - LFO amplitude level modulation: -1 .. 1.
- `env_to_lpfcutoff f` - ADSR envelope lowpass filter cutoff modulation: -1 .. 1.
- `env_to_lpfres f` - ADSR envelope lowpass filter resonance modulation: -1 .. 1.
- `env_to_hpfcutoff f` - ADSR envelope highpass filter cutoff modulation: -1 .. 1.
- `env_to_hpfres f` - ADSR envelope highpass filter resonance modulation: -1 .. 1.
- `env_to_ampgain f` - ADSR envelope amplitude level modulation: -1 .. 1.

### Synth Voice Parameters

_Note: not implemented yet_

All synth parameters have corresponding commands to control one given synth voice. These commands are prefixed with `voice_` and has an additional first `i` argument for supplying a voice number.

Example:

- `voice_osc1gain if` - oscillator gain 0 .. 1 of a specific voice.

### General Settings

_Note: not implemented yet_

- `polyphony i` - set maximum number of notes possible to play. set this to 1 to make gong monophonic. too high polyphony will cause performance issues. default is 6.

## Voice Allocation

Voice allocation is delegated to the Lua script layer.

## Using the Gong Lua Module

_Note: voice numbers are indexed from 1 in the gong lua module._

Gong synth parameters can be added to the global paramset using the Gong lua module.

Require the Gong module:

``` lua
local Gong = require 'lib/jah/gong'
```

To add all params:

``` lua
function init()
  --- ...
  Gong.add_params()
  --- ...
end
```

To add params for the first synth voice (_Note: not implemented yet_):

``` lua
function init()
  --- ...
  Gong.add_voice_params(1)
  --- ...
end
```

