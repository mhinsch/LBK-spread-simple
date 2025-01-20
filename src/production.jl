
"""
Try to get one field per member; produce food.
"""
function production!(household, world, pars)
	if length(household.fields) < length(household.members)
		try_gain_fields!(household, world, pars)
	elseif length(household.fields) > length(household.members)
		lose_fields!(household, world, pars)
	end

	household.resources = 0
	for pos in household.fields 
		household.resources += harvest(pos, world, pars)
	end
	nothing
end	


function try_gain_fields!(hh, world, pars)
	minx = max(1, hh.pos.x - pars.max_field_dist)
	miny = max(1, hh.pos.y - pars.max_field_dist)
	maxx = min(length(world.lsc)[2], hh.pos.x + pars.max_field_dist)
	maxy = min(length(world.lsc)[1], hh.pos.y + pars.max_field_dist)
	max_dist2 = pars.max_field_dist^2
	fields = Vector{Tuple{Int, Int, Float64}}()
	for y in minx:maxx
		for x in miny:maxx
			if sq_dist(hh.pos, (y,x)) < max_dist2 && !world.owned[y,x]
				push!(fields, (x, y, world.lsc[y, x]))
			end
		end
	end
	
	# we want the fields with the highest quality
	sort!(fields, by=x->x[3])
	
	n_needed = min(length(hh.members) - length(hh.fields), length(fields))
	for i in 0:n_needed-1
		f = fields[end-i]
		push!(hh.fields, (x=f[1], y=f[2]), f[3])
		world.owned[f[2], f[1]] = true
	end
	
	nothing
end


function lose_fields!(hh, world, pars)
	sort!(hh.fields, by = f->f[2], rev = true)
	n = length(hh.fields) - length(hh.members)
	for i in 1:n
		world.owned[hh.fields[end].pos] = false
		pop!(hh.fields)
	end
	
	nothing
end



