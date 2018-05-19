Engine_Sixes {

	var <defs;
	var <def_names;
	var <def_params;
	
	alloc {
		
		defs = Array.with(
			SynthDef.new(\sixes_sub, {
				arg out, amp, hz1, hz2, shape1, shape2, ratio, mod, spread, noise,
				hz_lag=0.005, shape_lag=0.005, ratio_lag=0.005, mod_lag=0.005,
				amp_atk, amp_dec, amp_sus, amp_rel;

				
				
			}),
			
			SynthDef.new(\sixes_fm, {
				
			}),

			SynthDef.new(\sixes_colors, {
				
			}),


		);
		
	}

	
}