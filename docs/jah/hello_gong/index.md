---
---

# Hello Gong

6 voice FM syntheziser controlled by midi.

## Features

- 3 sine oscillators per voice.
- Resonant high and lowpass filter.
- LFO routable to oscillators and filters.
- Envelope routable to oscillators and filters.

## Operation

- ENC1 adjusts volume.
- ENC2 changes timbre.
- ENC3 changes time.
- KEY2 triggers a random note.
- MIDI notes triggers samples.

## Options

Options are available in the MENU > PARAMETERS list.

Script options:

- `midi in` - disabled/enabled. Default is enabled.
- `filter cutoff cc` - MIDI controller no changing filter cutoff of selected param(s): 0...127. default is 1.
- `filter cutoff cc type` - abs/rel.
- `filter res cc` - MIDI controller no changing filter resonance of selected param(s): 0...127. default is 2.
- `filter res cc type` - abs/rel.
- `osc 1 partial cc` - MIDI controller no changing delay send of selected param(s): 0...127. default is 3.
- `osc 1 partial cc type` - abs/rel.
- `osc 2 partial cc` - MIDI controller no changing reverb send of selected param(s): 0...127. default is 4.
- `osc 2 partial cc type` - abs/rel.

The script exposes [gong engine synth parameters](../gong).

