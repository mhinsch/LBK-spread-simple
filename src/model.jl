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


@composite @kwdef mutable struct AllParams
	Params...
	
	seed :: Int = 42
	n_steps :: Int = 500
end


mutable struct Model
	world :: World
	time :: Int
	pars :: AllParams
end


function setup_model(pars)
	world = setup_world(pars)
	
	Model(world, 0, pars)
end


function step!(model)
	world = model.world
	pars = model.pars
	
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
	# iterate in reverse so that newborns aren't processed immediately
	for i in length(world.pop):-1:1
		person = world.pop[i]
		person_updates!(person, world, pars)
	end
	
	remove_all_dead!(world.pop)

	check_consistency(world)

	println(rand(5))
end


