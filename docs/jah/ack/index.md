---
---

# Ack

Simple sample player

## Features

- 8 voice sample playback of mono or stereo samples.
- Sample start / end and loop positions.
- Resonant multimode filter.
- AR envelopes for volume and filter cutoff.
- Master delay and reverb.

## Commands

_Note: channels are indexed 0-7 in commands._

### Triggering

- `trig i` - triggers single channel.
- `multiTrig iiiiiiii` - triggers multiple channels. one 1/0 argument for each channel. 1 means trigger.
- `kill i` - mute single channel.
- `killTrig iiiiiiii` - mutes multiple channels. one 1/0 argument for each channel. 1 means mute.

### Channel Settings

First argument is always channel.

- `loadSample is` - load sample given an absolute path.
- `sampleStart if` - set position at which sample starts to play, expressed in 0-1. position is fixed after a sample has been triggered.
- `sampleEnd if` - set position at which sample ends playing or starts to loop, expressed in 0-1. position is fixed after a sample has been triggered. if sample end is lower than sample start sample will playback reversed.
- `loopPoint if` - set position within sample start - end at which loop will start, expressed in 0-1.
- `enableLoop i` - enables loop.
- `disableLoop i` - disables loop, sample is played as a oneshot.
- `speed if` - playback speed. 0-5 where 1 is normal playback.
- `volume if` - playback volume expressed in dB.
- `volumeEnvAttack if` - volume AR envelope attack time.
- `volumeEnvRelease if` - volume AR envelope release time.
- `pan if` - pan -1...1.
- `filterCutoff if` - filter cutoff expressed in Hz.
- `filterRes if` - filter resonance 0-1.
- `filterMode ii` - 0=lowpass, 1=bandpass, 2=highpass, 3=notch, 4=peak.
- `filterEnvAttack if` - filter AR envelope attack time.
- `filterEnvRelease if` - filter AR envelope release time.
- `filterEnvMod if` - filter AR envelope cutoff modulation -1...1.
- `dist if` - distorsion amount 0...1.
- `includeInMuteGroup ii` - 0 or 1. 1 means channel will be muted if other channel in mute group is played.
- `delaySend if` - delay send expressed in dB.
- `reverbSend if` - reverb send expressed in dB.

### Effects Settings

- `delayTime f` - delay time in seconds 0.0001 .. 5.
- `delayFeedback f` - reverb feedback 0 .. 1.25.
- `delayLevel f` - reverb level expressed in dB.
- `reverbRoom f` - reverb room 0 .. 1.
- `reverbDamp f` - reverb damp 0 .. 1.
- `reverbLevel f` - reverb level expressed in dB.

## Using the Ack Lua Module

_Note: channels are indexed 1-8 in the ack lua module._

Default Ack parameters to control channel and effects settings can be added to the global paramset using the Ack lua module.

Require the Ack module:

``` lua
local Ack = require 'lib/jah/ack'
```

To add all params:

``` lua
function init()
  --- ...
  Ack.add_params()
  --- ...
end
```

To add params for the first channel:

``` lua
function init()
  --- ...
  Ack.add_channel_params(1)
  --- ...
end
```

### Default Parameters

Parameters are self-explanatory. See details and ranges below.

Settings per channel:

- `sample` - sample to play
- `sample start` - position in sample where playback will start
- `sample end` - position in sample where playback will end (if oneshot sample) or loop (if loop is enabled)
- `loop point` - position within sample start / end where sample will retrigger if loop is enabled
- `loop` - loop enable / disable
- `speed` - 5-500%
- `volume` - expressed in dB
- `volume env atk` - 0-1000 ms
- `volume env rel` - 0-3000 ms
- `pan` - L100 to MID to R100
- `filter mode` - lowpass/bandpass/highpass/notch/peak
- `filter cutoff` - 20-20000 Hz
- `filter res` - 0-100%
- `filter env atk` - 0-1000 ms
- `filter env rel` - 0-3000 ms
- `filter env mod` - bipolar -100..100%
- `dist` - unipolar 0..100%
- `in mutegroup` - mutegroup enable / disable
- `delay send` - expressed in dB
- `reverb send` - expressed in dB

Effects settings:

- `delay time` - 0-5000 ms
- `delay feedback` - 0-125%
- `delay level` - expressed in dB
- `reverb room size` - 0-100%
- `reverb damp` - 0-100%
- `reverb level` - expressed in dB

