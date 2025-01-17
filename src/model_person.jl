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


can_reproduce(person, pars) = is_female(person) && pars.min_repr_age <= person.age <= pars.max_repr_age

function repr_prob(person, pars) = pars.repr_prob

function reproduce!(mother, father, world, pars)
	child = Person(parent.home, rand(0:1), 0.0, 
		[mother, father], [], [mother, father],
		parent.coop, parent.dispersal, parent.culture)
		
	for parent in (mother, father)
		push!(parent.children, child)
		push!(parent.contacts, child)
	end
	
	add_to_household!(mother.home, child)
	add_to_world!(world, child)
	
	
	child
end


can_decide_migrate(person, pars) = person.age > pars.min_mig_age

mig_prob(person, pars) = pars.mig_prob

function migrate!(person, world, pars)
	new_pos = find_new_home(person, world, pars)[1:2]
	move_or_create_household!(person, new_pos, world, pars)
end


function find_new_home(pos, world, pars)
	# centre of gravity of settlements in radius
	cog = household_cog(world, pos, pars.mig_radius)
	
	# go into the opposite direction of centre of gravity
	dir = pos .- cog
	angle = atan(dir[2], dir[1])
	
	# pick line roughly in direction and try to find good place
	ptq = pos..., 0.0
	for i in 1:pars.n_searches
		search_angle = angle + rand(Normal(0.0, i*pars.search_angle_s))
		ptq = search_point(pos, angle, world, pars)
		if ptq != (pos..., 0.0)
			break
		end
	end
	
	ptq
end


function search_point(pos, angle, world, pars)
	end_point = pos .+ pars.mig_radius .* (cos(angle), sin(angle))
	
	points = Vector{Tuple{Float64, Float64, Float64}}()
	
	bresenham_apply!(pos, end_point, size(world.quality)) begin p
			q = world.quality[p]
			# we don't want other hhs nearby, so quality is 0 if we find any
			for hh in local_households(p, pars.min_hh_dist)
				q = 0.0
				break
			end
			if q > 0.0
				push!(points, (p..., q))
			end
			nothing
		end
	if isempty(points)
		return (pos..., 0.0)
	end
	
	#return best point
	findmax(p->p[3], points)
end


death_prob(person, pars) = pars.death_prob


function die!(person, world, pars)
	person.age = -1.0 # hacky death marker, so that we can remove all dead at the same time
	for p in person.parents
		find_remove!(p.children, person)
	end
	
	for c in person.contacts
		find_remove!(c.contacts, person)
	end
	
	for c in person.children
		find_remove!(c.parents, person)
	end
	
	find_remove!(person.home.members, person)	
	
	nothing
end


function attempt_marriage!(person, world, pars)
	candidates = typeof(person)[]
	for hh in local_households(world, person.home.pos, pars.marriage_radius)
		collect_candidates!(candidates, hh, person, pars)
	end
	
	if !isempty(candidates)
		marriage!(person, rand(candidates), pars)
	end
	
	nothing	
end


function collect_candidates!(cand, hh, person, pars)
	for p in hh.members
		if p.sex != person.sex && p.age > pars.min_age_marry && 
			!(p in person.children) && !(p in person.parents) && 
			!(intersects(p.parents, person.parents)) && rand() pars.prob_candidate
			push!(cand, p)
		end
	end
end


function marriage!(p1, p2, pars)
	@assert p1.partner == p2.partner == nothing
	
	p1.partner = p2
	p2.partner = p1
	
	move, stay = rand(0:1) ?
		p1, p2 : p2, p1
		
	leavers = [move]
	for child in leavers.children
		if child.age < pars.age_minor
			push!(leavers, child)
		end
	end
	
	move_to_household!(leavers, new_hh, world, pars)
	
	nothing
end
	
