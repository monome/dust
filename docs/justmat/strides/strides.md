

# strides v1.2

---

strides is a collection of 16 pattern recorders.

8 are norns focused, expressed as encoder recorders sending midi cc's.

8 are grid focused, allowing for finger drum style recording and looping (with optional midi note out).

---

## norns

load samples, set midi notes and cc destinations in the PARAMETERS menu.


there are two operating modes in strides, grid and encoder.
to switch between grid and encoder modes, hold key1 and press key3.


#### grid mode controls

- enc1 - volume
- enc2 - delay time
- enc3 - delay feedback
- key1 = hold to access secondary encoder/ key functions
	* enc1 = distortion amount
	* enc2 = delay level
	* enc3 = ddelay send
	* key3 = change mode
- key2 = half time
- key3 = double time

nb: delay send works on all samples and tracks. if you wish to send individual samples to delay, you can do so via the PARAMETERS menu.

#### encoder mode controls

- key2 = arm record
- key3 = start/ stop pattern
- enc1 = select active pattern
- enc2 = set cc value


---

## grid

![](strides-grid1.png)

hold alt to access secondary grid functions.

- a - track selection
- b - arm record
- c - start/stop selected track
- d - alt
	* a - track stop
	* b - clear all patterns
	* c - stop all tracks
- e - sample pads



nb: as of v1.2 a midi panic/ kill button was added just above alt. hold alt to expose.

as well as secondary controls, holding alt will bring up several controls for pattern and playback speed manipulation.

![](strides-grid2.png)

- f - toggle pattern linearization
- g - double sample playback speed
- h - half pattern speed
- i - double pattern speed
- j - half sample playback speed
- k - restore pattern speed to original or linearized if selected
- l - restore all sample playback speed to original