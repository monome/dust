---
---

# mlr

an in-progress re-imagining of the multi-generational live sample cutting platform, now with a heightened focus on audio input.

## main interface

![](mlr.png)

## NAV + MODE

the top nav controls stay the same across modes.

MODE changes the lower section of the grid, described below.

### MODE: REC / SPEED

the diagram above shows the lower controls.

- REC - toggles recording
- FOCUS - change which track the screen shows. use KEY2 to toggle params shown, ENC2/3 to change.
- REV - reverse speed
- SPEED - set speed
- PLAY - toggle playback

### MODE: CUT

each track shows playback position. push a position to jump there. hold a position and touch another to create a loop on release.

### MODE: CLIP

lets you select which sound clip (1-16) is being used for the track. you can select which clip is being used per track on the grid interface.

scroll with ENC2 to select and KEY2 to load a file. KEY3 lets you resize the clip (according to the multiplier set by ENC3 and the current tempo).

### PATTERNS

record cut, loop, and speed changes by activating pattern record.

touch again to stop. then touch again to toggle playback.

ALT-touch to erase pattern. there are four patterns.

### QUANTIZE

touch to toggle quantization. ALT-Q to change tempo and division.

in REC/SPEED mode use ALT-FOCUS to toggle tempo-mapping.

a tempo-mapped clip will follow the tempo.

## RECORDING QUICKSTART

- in the menu, go to LEVELS (leftmost screen) to confirm you're getting audio input (center bars)
- new startup of mlr script
- go into CUT (second top grid key), start a small loop on the first track (row below the top row) by holding one position and pressing another position 2-3 spots to the right. (this is simply so you hear results faster)
- go back to REC/SPEED (first top grid key), you'll see that play (rightmost) for track 1 is on, so activate record (leftmost for the track row).
- play something into the input. make sure REC level is 1.0 (full, use ENC2) and then slowly turn up OVERDUB and eventually you're in echo territory.

## TODO / FUTURE MAYBE PLANS

- 7 tracks, mute groups
- save/load sessions with audio
- RECALL function keys 
- speed lag parameter per track
- step length parameter per track
- buffer operations (clearing, etc)
- input routing (internal resampling)
- second quantize level
- momentary record
- start/stop recording (and set clip length)
- level monitoring on screen
- cut modes: normal/single/hold
- loop moving, loop sub-tuning
- cc mapping
