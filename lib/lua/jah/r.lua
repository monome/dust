local R = {}

local ControlSpec = require 'controlspec'

local specs = {}

specs.ADSREnv = {
	Attack = ControlSpec.new(0.1, 2000, "exp", 0, 5, "ms"),
	Decay = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms"),
	Sustain = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	Release = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms"),
	Gate = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.Amp2 = {
	Level = ControlSpec.UNIPOLAR
}

specs.DAmp = {
	Gain = ControlSpec.UNIPOLAR,
	GainModulation = ControlSpec.BIPOLAR,
	In1 = ControlSpec.UNIPOLAR,
	In2 = ControlSpec.UNIPOLAR,
	Out = ControlSpec.UNIPOLAR,
	Mode = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.Delay = {
	DelayTime = ControlSpec.new(0.1, 5000, "exp", 0, 300, "ms"),
	DelayTimeModulation = ControlSpec.BIPOLAR
}

specs.FreqGate = {
	Frequency = ControlSpec.FREQ,
	Gate = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.FreqShift = {
	Frequency = ControlSpec.new(-2000, 2000, "linear", 0, 0, "Hz"),
	FM = ControlSpec.BIPOLAR
}

specs.LPFilter = {
	AudioLevel = ControlSpec.AMP,
	Frequency = ControlSpec.WIDEFREQ,
	Resonance = ControlSpec.UNIPOLAR,
	FM = ControlSpec.BIPOLAR,
	ResonanceModulation = ControlSpec.BIPOLAR
}

specs.LPMoog = {
	Frequency = ControlSpec.WIDEFREQ,
	Resonance = ControlSpec.UNIPOLAR,
	FM = ControlSpec.BIPOLAR,
	ResonanceModulation = ControlSpec.BIPOLAR
}

specs.MGain = {
	Gain = ControlSpec.new(-math.huge, 12, "db", 0, 0, "dB"),
	Mute = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.MMFilter = {
	AudioLevel = ControlSpec.AMP,
	Frequency = ControlSpec.WIDEFREQ,
	Resonance = ControlSpec.UNIPOLAR,
	FM = ControlSpec.BIPOLAR,
	ResonanceModulation = ControlSpec.BIPOLAR
}

specs.Matrix4x4 = {
	FadeTime = ControlSpec.new(0, 1000, "linear", 0, 5, "ms"),
	Gate_1_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_4 = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.Mixer = {
	In1 = ControlSpec.UNIPOLAR,
	In2 = ControlSpec.UNIPOLAR,
	In3 = ControlSpec.UNIPOLAR,
	In4 = ControlSpec.UNIPOLAR,
	Out = ControlSpec.UNIPOLAR,
	Mode = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.MultiLFO = {
	Frequency = ControlSpec.new(0.1, 30, "exp", 0, 1, "Hz"),
	PulseWidth = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	FM = ControlSpec.UNIPOLAR,
	PWM = ControlSpec.new(0, 1, "linear", 0, 0.4, "")
}

specs.MultiLFO2 = {
	Frequency = ControlSpec.new(0.01, 50, "exp", 0, 1, "Hz"),
	Reset = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.MultiOsc = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR,
	PulseWidth = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	PWM = ControlSpec.UNIPOLAR
}

specs.Noise = {
}

specs.OGain = {
	Gain = ControlSpec.new(-math.huge, 12, "db", 0, 0, "dB"),
	Mute = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.PitchShift = {
	PitchRatio = ControlSpec.new(0, 4, "linear", 0, 1, ""),
	PitchDispersion = ControlSpec.new(0, 4, "linear", 0, 0, ""),
	TimeDispersion = ControlSpec.new(0, 1, "linear", 0, 0, ""),
	PitchRatioModulation = ControlSpec.BIPOLAR,
	PitchDispersionModulation = ControlSpec.BIPOLAR,
	TimeDispersionModulation = ControlSpec.BIPOLAR
}

specs.QGain = {
	Gain = ControlSpec.new(-math.huge, 12, "db", 0, 0, "dB"),
	Mute = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.RingMod = {
}

specs.SGain = {
	Gain = ControlSpec.new(-math.huge, 12, "db", 0, 0, "dB"),
	Mute = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.SampleHold = {
}

specs.SawOsc = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(0, 10, "linear", 0, 5, ""),
	FM = ControlSpec.UNIPOLAR
}

specs.SawOsc = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR
}

specs.SineOsc = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(0, 10, "linear", 0, 5, ""),
	FM = ControlSpec.UNIPOLAR
}

specs.SoundIn = {
}

specs.SoundOut = {
	Gain = ControlSpec.new(-math.huge, 12, "db", 0, -10, "dB")
}

specs.SquareOsc = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR,
	PulseWidth = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	PWM = ControlSpec.new(0, 1, "linear", 0, 0.4, "")
}

specs.TestGen = {
	Frequency = ControlSpec.WIDEFREQ,
	Amplitude = ControlSpec.DB,
	Wave = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs.TriOsc = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR
}

R.specs = specs

return R
