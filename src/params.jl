@kwdef struct Params
	lsc_x :: Int = 2049
	lsc_y :: Int = 2049

	wth_ruggedness :: Float64 = 0.5
	wth_zoom :: Int = 2
	
	min_repr_age :: Int = 16
	max_repr_age :: Int = 40
	repr_prob :: Float64 = 0.5
	
	min_mig_age :: Int = 18
	mig_prob :: Float64 = 0.1
	
	death_prob :: Float64 = 0.06
	
	
	exch_radius :: Float64 = 2
	
	max_field_dist :: Float64 = 20
	food_use :: Float64 = 0.5
	
	seed :: Int = 42
	n_steps :: Int = 500
	obs_freq :: Int = 1
end
