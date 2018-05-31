---
---

# Ack

Simple sample player

## Features

- 8 voice sample playback of mono or stereo samples
- Dynamic sample start / end and loop positions
- Resonant multimode filter
- Envelopes for volume and filter cutoff

## Commands

_Note: channels are indexed 0-7 in commands._

### Triggering

- trig i: trig single channel given channelnum
- multiTrig iiiiiiii: trigger multiple channels. one 1/0 argument for each channel. 1 means trigger.

### Channel Settings

First argument is always channelnum.

- loadSample is: load sample given an absolute path
- sampleStart if: set position at which sample starts to play, expressed in 0-1. position is fixed after a sample has been triggered
- sampleEnd if: set position at which sample ends playing or starts to loop, expressed in 0-1. position is fixed after a sample has been triggered. if sample end is lower than sample start sample will playback reversed.
- loopPoint if: set position within sample start - end at which loop will start, expressed in 0-1.
- enableLoop i: enables loop
- disableLoop i: disable loop
- speed if: playback speed. 0-5 where 1 is normal playback.
- volume if: if: playback volume expressed in dB.
- volumeEnvAttack if: volume envelope attack time
- volumeEnvRelease if: volume envelope release time
- pan if: pan -1...1.
- filterCutoff if: filter cutoff expressed in Hz.
- filterRes if: filter resonance 0-1.
- filterMode: 0=lowpass, 1=bandpass, 2=highpass, 3=notch, 4=peak
- filterEnvAttack if: filter envelope attack time
- filterEnvRelease if: filter envelope release time
- filterEnvMod if: filter envelop modulation -1...1.
- delaySend if: delay send expressed in dB.
- reverbSend if: reverb send expressed in dB.

### Effects Settings

- delayTime f: delay time in seconds 0.0001 .. 5.
- delayFeedback f: reverb feedback 0 .. 1.25.
- delayLevel f: reverb level expressed in dB.
- reverbRoom f: reverb room 0 .. 1.
- reverbDamp f: reverb damp 0 .. 1.
- reverbLevel f: reverb level expressed in dB.

## Using the Ack Lua Module

_Note: In lua channels are indexed from 1-8._

Default Ack parameters to control channel and effects settings can be added to the global paramset using the Ack lua module.

Require the Ack module:

```
local Ack = require 'lib/jah/ack'
```

To add all params:

```
function init()
	--- ...
	Ack.add_params()
	--- ...
end
```

To add params for the first channel:

```
function init()
	--- ...
	Ack.add_channel_params(1)
	--- ...
end
```

### Default Parameters

Parameters are self-explanatory. See details and ranges below.

Settings per channel:

- sample start/end/loop point/loop: sample will play from start % position to end %, then loop from loop point % within start and end point if loop is enabled
- speed: 0-500%
- volume: expressed in dB
- volume env atk: 1-3000 ms
- volume env rel: 1-3000 ms
- pan: L100 to MID to R100
- filter cutoff: 20-20000 Hz
- filter res: 0-100%
- filter mode: lowpass/bandpass/highpass/notch/peak
- filter env atk: 1-3000 ms
- filter env rel: 1-3000 ms
- filter env mod: bipolar -100..100%
- delay send: expressed in dB
- reverb send: expressed in dB

Effects settings:

- delay time f: 0.001-5 seconds
- delay feedback f: 0-125%
- delay level: expressed in dB
- reverb room: room size 0-100%
- reverb damp: reverb damp 0-100%
- reverb level: expressed in dB

