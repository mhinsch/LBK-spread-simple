
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


function move_or_create_household!(person, new_pos, world, pars)
	leavers = [person]
	
	# we assume that the partner always lives at the same place
	if person.partner != nothing
		push!(leavers, partner)
	end
	
	# young children always join, others decide as adults
	for child in person.children
		if child.home == person.home && 
			(child.age < pars.age_minor || wants_to_join(child, person, pars))
			
			push!(leavers, child)	
		end
	end
	
	# other adults leave at random
	for mem in person.home.members
		if mem != person && mem != person.partner && !(person in mem.parents) && 
			(person.age >= pars.age_minor && wants_to_join(mem, person, pars))
			
			push!(leavers, mem)
		end
	end
	
	new_hh = Household{typeof(person)}(new_pos)
	
	move_to_household!(leavers, new_hh, world, pars)
	
	nothing
end


