const Pos = @NamedTuple{x::Int, y::Int}


mutable struct Household{PERS}
	home :: Pos
	members :: Vector{PERS}
	fields :: Vector{Tuple{Pos, Float64}}
end

Household{P}(pos) where{P} = Household{P}(pos, P[], [])

add_to_household!(hh, person) = push!(hh.members, person)


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
	
	culture :: Float64
end


const UnknownHousehold = Household{Person}((0,0), [], [])


Person() = Person(UnknownHousehold, true, 0.0,
	nothing, [], [], [],
	0.0, 0.0,
	0.0)
	
const UnknownPerson = Person()

is_female(person) = person.sex

is_dead(person) = person.age < 0


mutable struct World
	lsc :: Matrix{Float64}
	quality :: Matrix{Float64}
	owned :: Matrix{Bool}
	weather :: Matrix{Float64}
	hh_cache :: Matrix{Vector{Household{Person}}}
	households :: Vector{Household{Person}}
	pop :: Vector{Person}
end

weather_at(x, y, world, pars) = world.weather[x÷pars.wth_zoom+1, y÷pars.wth_zoom+1]


mutable struct HHCacheIter
	cache :: Matrix{Vector{Household{Person}}}
	pos :: Pos
	r2 :: Float64
	top :: Int
	left :: Int
	xm :: Int
	ym :: Int
	i :: Int
	j :: Int
end

# TODO change to Int pos
# TODO borders
function iterate(hhci::HHCacheIter, dummy=hhci)
	while true
		y, x = hhci.top + hhci.i÷hhci.xm, hhci.left + hhci.i%hhci.xm
		vec = hhci.cache[y, x]
		if hhci.j <= length(vec)
			el = vec[hhci.j]
			hhci.j += 1
			if sum((el.pos .- hhci.pos).^2) < hhci.r2
				return el, hhci
			end
		else
			hhci.i += 1
			if i > xm * ym
				return nothing
			end
			hhci.j = 1
		end
	end
end


function local_households(world, pos, radius)
	HHCacheIter(world.hh_cache, pos, radius^2, 
		max(0, floor(Int, pos[1]-radius)), 
		max(0, floor(Int, pos[2]-radius)),
		min(length(world.hh_cache)[2], ceil(Int, pos[1]+radius)), 
		min(length(world.hh_cache)[1], ceil(Int, pos[2]+radius)),
		0, 1)
end


function is_unoccupied(world, pos, radius)
	for hh in local_households(world, pos, radius)
		return false
	end
	
	true
end


function household_cog(world, pos, radius)
	n = 0
	cog = 0,0
	for hh in local_households(world, pos, radius)
		cog .+= hh.pos
		n += 1
	end
	
	cog ./ n
end


function weather!(world, pars)
	rand!(world.weather, DiamondSquare(H=pars.wth_ruggedness))
end


function harvest(pos, world, pars)
	world.lsc[pos] * weather_at(pos..., world, pars)
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

function move_to_household!(leavers, new_hh, world, pars)
	for p in leavers
		find_remove!(p.home.members, p)
		p.pos = new_hh
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
		attempt_marriage(person, world, pars)
	end
	
	nothing
end


inc_age!(person) = (person.age += 1)

