const Pos = Tuple{Int, Int}


mutable struct Household{PERS}
	pos :: Pos
	members :: Vector{PERS}
	fields :: Vector{Tuple{Pos, Float64}}
	resources :: Float64
end

Household{P}(pos) where{P} = Household{P}(pos, P[], [], 0.0)

function add_to_household!(hh, person)
	push!(hh.members, person)
	person.home = hh
end


mutable struct Person
	home :: Household{Person}
	sex :: Bool
	age :: Float64
	
	partner :: Union{Person, Nothing}
	parents :: Vector{Person}
	children :: Vector{Person}
	
	contacts :: Vector{Person}
	
	coop :: Float64
	dispersal :: Float64
	dens_dispersal :: Float64
	
	culture :: Float64
end


const UnknownHousehold = Household{Person}((0,0))


Person() = Person(UnknownHousehold, true, 0.0,
	nothing, [], [], [],
	0.0, 0.0, 0.0,
	0.0)
	
const UnknownPerson = Person()

is_female(person) = person.sex

is_dead(person) = person.age < 0

is_single(person) = person.partner == nothing


mutable struct World
	lsc :: Matrix{Float64}
	quality :: Matrix{Float64}
	owned :: Matrix{Bool}
	weather :: Matrix{Float64}
	hh_cache :: Cache2D{Household{Person}}
	households :: Vector{Household{Person}}
	pop :: Vector{Person}
end

weather_at(pos, world, pars) = world.weather[pos[1]÷pars.wth_zoom+1, pos[2]÷pars.wth_zoom+1]


function add_household!(world, hh)
	push!(world.households, hh)
	add_to_cache!(world.hh_cache, hh, hh.pos)
end


function local_households(world, pos, radius)
	iter_circle(world.hh_cache, pos, radius)
end


function is_unoccupied(world, pos, radius)
	for hh in local_households(world, pos, radius)
		return false
	end
	
	true
end


function household_cog(world, pos, radius)
	n = 0
	cogy, cogx = 0,0
	for hh in local_households(world, pos, radius)
		cogy += hh.pos[1]
		cogx += hh.pos[2]
		n += 1
	end

	@assert n > 0
	
	(cogy, cogx) ./ n
end


function weather!(world, pars)
	rand!(world.weather, DiamondSquare(H=pars.wth_ruggedness))
end


function add_to_world!(world, child)
	push!(world.pop, child)
end


function remove_all_dead!(pop)
	for i in length(pop):-1:1
		if is_dead(pop[i])
			pop[i] = pop[end]
			pop!(pop)
		end
	end
	nothing
end		


function remove_empty_households!(world, pars)
	for i in length(world.households):-1:1
		hh = world.households[i]
		isempty(hh.members) || continue

		lose_fields!(hh, world, pars)
		@assert isempty(hh.fields)

		remove_unsorted_at!(world.households, i)
		remove_from_cache!(world.hh_cache, hh, hh.pos)
	end
end


function move_to_household!(leavers, new_hh, world, pars)
	for p in leavers
		remove_unsorted!(p.home.members, p)
		p.home = new_hh
	end
	append!(new_hh.members, leavers)
	
	try_gain_fields!(new_hh, world, pars)
end	


function provisioning!(household, pars)
	household.resources -= length(household.members)
	nothing
end

function person_updates!(person, world, pars)
	inc_age!(person)
	
	if rand() < death_prob(person, pars)
		die!(person, world, pars)
		return
	end
	
	if can_reproduce(person, pars) && rand() < repr_prob(person, pars)
		reproduce!(person, person.partner, world, pars)
	end
	
	if can_migrate(person, pars) && rand() < mig_prob(person, pars)
		migrate!(person, world, pars)
	end
	
	if want_to_marry(person, pars)
		attempt_marriage!(person, world, pars)
	end
	
	nothing
end


inc_age!(person) = (person.age += 1)



function check_consistency(world)
	for x in 1:size(world.hh_cache.data)[2], y in 1:size(world.hh_cache.data)[1]
		lhh = world.hh_cache.data[y, x]
		for hh in lhh
			@assert hh in world.households
			@assert pos2cache_idx(world.hh_cache, hh.pos) == (y,x)

			for m in hh.members
				@assert m.home == hh
			end
		end
	end

	for hh in world.households
		@assert hh in world.hh_cache.data[pos2cache_idx(world.hh_cache, hh.pos)...]
	end

	for p in world.pop
		@assert !is_dead(p)
		@assert p in p.home.members
		if !is_single(p)
			@assert p.home == p.partner.home
			@assert p.partner.partner == p
		end

		for c in p.children
			@assert p in c.parents
		end

		for a in p.parents
			@assert p in a.children
		end
	end
end
