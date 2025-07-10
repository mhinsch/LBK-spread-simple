"Model parameters"
@kwdef struct Params
	# landscape
	"landscape width"
	lsc_x :: Int = 1025
	"landscape height"
	lsc_y :: Int = 1025
	"ruggedness used during landscape generation"
	lsc_ruggedness :: Float64 = 0.7
	"range of suitability"
	lsc_range :: Float64 = 1.0
	"minimum suitability"
	lsc_min :: Float64 = 0.0
	
	# weather
	"scale of weather map vs landscape"
	wth_zoom :: Int = 2
	"ruggedness used during weather generation"
	wth_ruggedness :: Float64 = 0.5
	wth_mean :: Float64 = 1.0
	wth_range :: Float64 = 0.5
	
	"probability to spontaneously migrate (per year)"
	ini_dispersal :: Vector{Float64} = [0.0, 0.0]
	ini_dens_dispersal :: Vector{Float64} = [0.0, 0.0]
	ini_coop :: Vector{Float64} = [0.0, 1.0]
	p_mut :: Float64 = 0.1
	d_mut :: Float64 = 0.05
	influence :: Float64 = 0.05
	
	n_auto_genes :: Int = 64
	n_auto_mutate :: Int = 5
	rate_crossover :: Float64 = 1.0
	n_sex_genes :: Int = 64
	n_sex_mutate :: Int = 5
	
	
	"minimum age for reproduction"
	min_repr_age :: Int = 16
	"maximum age for reproduction"
	max_repr_age :: Int = 40
	"probability to reproduce (per year and woman)"
	repr_prob :: Float64 = 0.6
	
	"minimum age for migration"
	minor_age :: Int = 16
	join_prob :: Float64 = 0.1
	mig_radius :: Int = 100
	n_searches :: Int = 5
	search_angle_s :: Float64 = 0.1
	
	"fatality per year"
	death_prob :: Float64 = 0.06
	
	marriage_radius :: Int = 150
	prob_candidate :: Float64 = 0.7
	
	"maximum distance for resource exchange"
	exch_radius :: Int = 100
	exch_prob :: Float64 = 0.5
	exch_ratio :: Float64 = 0.5 
	
	"maximum distance for fields"
	max_field_dist :: Int = 10
	"food used per person per year"
	food_use :: Float64 = 1
	"food produced per field"
	yield :: Float64 = 1.35
	
	"distance used to calculate quality of a location"
	qual_dist :: Int  = 10
	"minimum distance between settlements"
	min_hh_dist :: Int = 20
	
	ini_pop_size :: Int = 600
	ini_n_hh :: Int = 4
	ini_p_married :: Float64 = 0.75

	ini_x_range :: Int = 150
	ini_x_ctr :: Int = 513
	ini_y_range :: Int = 150
	ini_y_ctr :: Int = 513
end
