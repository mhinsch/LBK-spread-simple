const Pos = @NamedTuple{x::Int, y::Int}


mutable struct Household{PERS}
	home :: Pos
	members :: Vector{PERS}
	fields :: Vector{Pos}
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
	households :: Vector{Household{Person}}
	hh_cache :: Matrix{Vector{Household{Person}}
	pop :: Vector{Person}
end

weather_at(x, y, world, pars) = world.weather[x÷pars.wth_zoom+1, y÷pars.wth_zoom+1]


mutable struct HHCacheIter
	cache :: Matrix{Vector{Household{Person}}
	pos :: Pos
	r2 :: Float64
	top, left :: Int
	xm, ym :: Int
	i, j :: Int
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


function household_cog(world, pos, radius)
	n = 0
	cog = 0,0
	for hh in local_households(world, pos, radius)
		cog .+= hh.pos
		n += 1
	end
	
	cog ./ n
end
