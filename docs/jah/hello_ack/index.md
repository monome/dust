---
---

# Hello Ack

Sample player controlled by grid or midi

## Features

- Trigger 8 voice sample player using grid or midi device

## Operation

- ENC1 adjusts volume.
- ENC2 selects channel.
- ENC3 changes pitch of selected channel(s).
- KEY2 triggers selected channel(s).
- KEY3 select all channels (momentarily).
- GRID - first 8 buttons of row 8 triggers samples.
- MIDI notes triggers samples.

## Grid Support

Hello Ack is designed for varibright grids.

## Options

Options are available in the MENU > PARAMETERS list.

Script options:

- `grid selects channel` - yes/no.
- `midi in` - disabled/enabled. Default is enabled.
- `midi selects channel` - yes/no.
- `filter cutoff cc` - MIDI controller no changing filter cutoff of selected param(s): 0...127. default is 1.
- `filter cutoff cc type` - abs/rel.
- `filter res cc` - MIDI controller no changing filter resonance of selected param(s): 0...127. default is 2.
- `filter res cc type` - abs/rel.
- `delay send cc` - MIDI controller no changing delay send of selected param(s): 0...127. default is 3.
- `delay send cc type` - abs/rel.
- `reverb send cc` - MIDI controller no changing reverb send of selected param(s): 0...127. default is 4.
- `reverb send cc type` - abs/rel.

For each channel:

- `[channel]: midi note` - MIDI note mapped to trigger sample loaded in channel.

The script exposes [ack engine parameters](../ack) for each channel.

