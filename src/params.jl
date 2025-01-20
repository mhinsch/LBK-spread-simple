"Model parameters"
@kwdef struct Params
	# landscape
	"landscape width"
	lsc_x :: Int = 2049
	"landscape height"
	lsc_y :: Int = 2049
	"ruggedness used during landscape generation"
	lsc_ruggedness :: Float64 = 0.5
	
	# weather
	"scale of weather map vs landscape"
	wth_zoom :: Int = 2
	"ruggedness used during weather generation"
	wth_ruggedness :: Float64 = 0.5
	
	"how many cells to cache together in household cache"
	hhc_zoom :: Int = 8
	
	"minimum age for reproduction"
	min_repr_age :: Int = 16
	"maximum age for reproduction"
	max_repr_age :: Int = 40
	"probability to reproduce (per year and woman)"
	repr_prob :: Float64 = 0.5
	
	"minimum age for migration"
	min_mig_age :: Int = 18
	"probability to spontaneously migrate (per year)"
	mig_prob :: Float64 = 0.1
	
	"fatality per year"
	death_prob :: Float64 = 0.06
	
	"maximum distance for resource exchange"
	exch_radius :: Float64 = 2
	
	"maximum distance for fields"
	max_field_dist :: Float64 = 20
	"food used per person per year"
	food_use :: Float64 = 1
	
	"distance used to calculate quality of a location"
	qual_dist :: Int  = 10
	"minimum distance between settlements"
	min_hh_dist :: Int = 50
	
	ini_pop_size :: Int = 200
	ini_n_hh :: Int = 4
end
