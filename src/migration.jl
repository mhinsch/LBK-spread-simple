using Distributions

can_migrate(person, pars) = person.age > pars.minor_age

mig_prob(person, pars) = pars.mig_prob

function migrate!(person, world, pars)
	new_pos = find_new_home(person, world, pars)
	# didn't find anything
	if new_pos == person.home.pos
		return
	end

	move_or_create_household!(person, new_pos, world, pars)
	nothing
end


function find_new_home(person, world, pars)
	pos = person.home.pos
	# centre of gravity of settlements in radius
	cog = household_cog(world, pos, pars.mig_radius)
	
	# go into the opposite direction of centre of gravity
	dir = pos .- cog
	angle = dir == (0.0, 0.0) ? rand() * 2 * pi : atan(dir[1], dir[2])
	@assert ! isnan(angle)
	
	# pick line roughly in direction and try to find good place
	ptq = pos
	for i in 1:pars.n_searches
		search_angle = angle + rand(Normal(0.0, i*pars.search_angle_s))
		ptq = search_point(pos, angle, world, pars)
		if ptq != pos
			break
		end
	end
	
	ptq
end


function search_point(pos, angle, world, pars)
	end_point = round.(Int, pos .+ (pars.mig_radius .* sincos(angle)))
	
	points = Vector{Tuple{Pos, Float64}}()

	sz = size(world.quality)
	
	bresenham(pos[2], pos[1], end_point[2], end_point[1]) do x,y
		if y < 0 || x < 0 || y > sz[1] || x > sz[2]
			return
		end
		
		q = world.quality[y,x]
		p = y,x
		
		if q > 0.0 && is_unoccupied(world, p, pars.min_hh_dist)
			push!(points, (p, q))
		end
		nothing
	end
	if isempty(points)
		return pos
	end

	#return best point
	points[findmax(p->p[2], points)[2]][1]
end


wants_to_join(person, migrant, pars) = rand() < pars.join_prob


function move_or_create_household!(person, new_pos, world, pars)
	leavers = [person]
	
	# other adults leave at random
	for mem in person.home.members
		if mem != person && mem != person.partner && mem.age > pars.minor_age &&
			wants_to_join(mem, person, pars)
			
			push!(leavers, mem)
		end
	end

	for i in length(leavers):-1:1
		leaver = leavers[i]
		# we assume that the partner always lives at the same place
		if !is_single(leaver) && !(leaver.partner in leavers)
			@assert leaver.partner.home == leaver.home
			push!(leavers, leaver.partner)
		end
	
		# young children always join
		for child in leaver.children
			if child.home == leaver.home && child.age <= pars.minor_age && !(child in leavers)
				# not necessarily true, depends on param values
				@assert is_single(child)
				@assert !(child in leavers)
				push!(leavers, child)
			end
		end
	end
	
	#sort!(leavers, by=objectid)
	#unique!(leavers)
	
	new_hh = Household{typeof(person)}(new_pos)
	add_household!(world, new_hh)
	
	move_to_household!(leavers, new_hh, world, pars)
	
	nothing
end


