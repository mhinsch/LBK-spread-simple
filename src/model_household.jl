

"""
Try to get one field per member; produce food.
"""
function production!(household, world, pars)
	if length(household.fields) < length(household.members)
		try_gain_fields!(household, world, pars)
	end
	
	if length(household.fields) > length(household.members)
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


function provisioning!(household, pars)
	household.resources -= length(household.members)
	nothing
end


function exchange!(household, world, pars)
	household.resources >= 0 && return
	
	exchange_locally!(household, world, pars)
	
	household.resources >= 0 && return
	
	exchange_contacts!(household, world, pars)
	
	nothing
end

# TODO zoom hh cache
function exchange_locally!(self, world, pars)
	for hh in local_households(world, self.pos, pars.exch_radius)
		if hh.resources > 0 && willing_to_exchange(hh, self, pars)
			amount = min(hh.resources, -self.resources)
			self.resources += amount
			hh.resources -= amount
		end
		
		self.resources >= 0 && break
	end
	
	nothing
end


function exchange_contacts!(self, world, pars)
	contacts = Household{Person}[]
	# TODO maybe keep only remote contacts as optimisation
	for p in self.members
		for c in p.contacts
			push!(contacts, c.home)
		end
	end
	
	sort!(contacts, by=objectid)
	unique!(contacts)
	
	for hh in contacts
		if hh == self || close_by(self, hh, pars.exch_radius)
			continue
		end
		
		if hh.resources > 0 && willing_to_exchange(hh, self, pars)
			amount = min(hh.resources, -self.resources)
			self.resources += amount
			hh.resources -= amount
		end
		
		self.resources >= 0 && break
	end
	
	nothing
end


function willing_to_exchange(donor, recip, pars)
	true
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


function move_to_household!(leavers, new_hh, world, pars)
	for p in leavers
		find_remove!(p.home.members, p)
		p.pos = new_hh
	end
	append!(new_hh.members, leavers)
	
	try_gain_fields!(new_hh, world, pars)
end	
