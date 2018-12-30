-- softcut test
-- half sec loop 75% decay
--
-- KEY3 to toggle HOLD


function init()
	audio.level_adc_cut(1)
	audio.level_input_cut(0, 0, 1.0)
	audio.level_input_cut(1, 0, 1.0)
	audio.level_cut(0, 1.0)
	audio.pan_cut(0, 0.5)

	audio.cut_rate(0, 1)
	audio.cut_loop_start(0, 1)
	audio.cut_loop_end(0, 1.5)
	audio.cut_loop_flag(0, 1)
	audio.cut_fade_time(0, 0.1)
	audio.cut_rec_flag(0, 1)
	audio.cut_rec_level(0, 1)
	audio.cut_pre_level(0, 0.5)
	audio.cut_position(0, 1)
	audio.cut_enable(0, 1)

	audio.cut_filter_dry(0, 0.125);
	audio.cut_filter_fc(0, 1200);
	audio.cut_filter_lp(0, 0);
	audio.cut_filter_bp(0, 1.0);
	audio.cut_filter_rq(0, 2.0);

	hold = 0
end

function redraw()
	screen.clear()
	screen.level(hold == 1 and 15 or 2)
	screen.move(10,50)
	screen.text("halfsecond")
	screen.update()
end

function key(n,z)
	if n==3 and z==1 then
		hold = 1 - hold
		audio.cut_pre_level(0, hold==1 and 1 or 0.75)
		audio.cut_rec_level(0, hold==1 and 0 or 1)
		redraw()
	end
end

