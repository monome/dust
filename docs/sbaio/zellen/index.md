# zellen

A sequencer for Monome norns based on [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life).

## Usage

* Grid: enter/modify cell pattern
* KEY2: play/pause current generation (semi-manual mode), advance sequence (manual mode), play/pause sequence (automatic mode)
* KEY3: advance generation
* hold KEY1 and press KEY3: erase the board
* ENC1: set speed (bpm)
* ENC2: set play mode (see below)
* ENC3: set play direction (see below)

### Play Modes

Set the play mode with KEY2.
* reborn (default): Play a note for every cell that was born or reborn (= has exactly three neighbors), regardless of the previous state of the cell
* born: Play a note for every cell that was born (has exactly three neighbors and was not alive in the previous generation)
* ghost: Play a note for every cell that is dying(has less than two or more than three neighbors). Ghost notes can have a different pitch! (See the "ghost offset" setting in the parameters screen.)

### Play Direction

Set the play direction with KEY3.
* up: Cells on grid are played from top left (lowest note) to bottom right (highest note).
* down: Cells on grid are played from bottom right (highest note) to top left (lowest note).
* random: Cells are played in random order. The randomized order will be stable for a generation and will be re-randomized for every new generation.
* drunken up: Like up, but decides for each step randomly if it goes up or down.
* drunken down: Like down, but decides for each step randomly if it goes up or down.

### Sequencing modes
Set the sequencing mode in the parameters screen. Default is semi-manual.
* manual: Press KEY2 to play the next step in the sequence for a single generation.
* semi-manual: Plays the sequence for a single generation.
* automatic: Like semi-automatic, but automatically calculates the next generation and plays it.

## MIDI
Set the MIDI device number (default: 1) and MIDI velocity (default: 100) in the parameters screen. MIDI sync and more MIDI related features will be implemented in a future update.

## More Parameters
There is lots more to discover in the parameters screen, like root note, scale, and ghost offset.
