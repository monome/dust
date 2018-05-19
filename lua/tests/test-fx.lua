fx = require 'effects'
audio = require 'audio'

audio.output_level(1.0)
audio.input_level(1, 1.0)
audio.input_level(2, 1.0)

-- insert effects are applied after monitor
audio.monitor_on()
audio.monitor_mono()
audio.monitor_level(1.0)

-- insert effects (compression)
fx.insert_fx_on()
fx.insert_fx_param("threshold", -30);
fx.insert_fx_param("ratio", 10);
fx.insert_fx_param("makeup_gain", 10);
fx.insert_fx_param("attack", 4);
fx.insert_fx_param("release", 12);


--- aux effects (reverb)
fx.aux_fx_on()
fx.aux_fx_param("in_delay", 60.0)
fx.aux_fx_param("lf_x", 200.0)
fx.aux_fx_param("low_rt60", 8.0) -- really long
fx.aux_fx_param("mid_rt60", 6.0)
fx.aux_fx_param("hf_damping", 6000.0)
fx.aux_fx_param("eq1_freq", 315.0)
fx.aux_fx_param("eq1_level", 0.0)
fx.aux_fx_param("eq2_freq", 1500.0)
fx.aux_fx_param("eq2_level", 0.0)
fx.aux_fx_param("dry_wet_mix", 0.0)
fx.aux_fx_param("level", -6.0)

		
-- these levels are in dB! (sorry)
--- route input to aux
fx.aux_fx_input_level(1, 0)
fx.aux_fx_input_level(2, 0)
fx.aux_fx_return_level(0)

--- and/or, route output to aux (before insert)
fx.aux_fx_output_level(0)
