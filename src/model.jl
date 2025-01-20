include("util.jl")

include("world.jl")
include("params.jl")
include("production.jl")
include("exchange.jl")
include("death.jl")
include("reproduction.jl")
include("migration.jl")
include("marriage.jl")
include("setup.jl")


using CompositeStructs


mutable struct Model
	world :: World
	time :: Int
end


@composite @kwdef struct AllParams
	Params...
	
	seed :: Int = 42
	n_steps :: Int = 500
end


function setup_model(pars)
	world = setup_world(pars)
	
	Model(world, 0)
end


function step!(model, pars)
	
	world = model.world

	weather!(world, pars)
	
	shuffle!(world.households)
	for hh in world.households
		production!(hh, world, pars)
	end
	
	shuffle!(world.households)
	for hh in world.households
		provisioning!(hh, pars)
	end
	
	shuffle!(world.households)
	for hh in world.households
		exchange!(hh, world, pars)
	end
	
	shuffle!(world.pop)
	# iterate in reverse so that births and deaths don't invalidate
	for person in Iterators.reverse(world.pop)
		person_updates!(person, world, pars)
	end
	
	remove_all_dead!(world.pop)
end


