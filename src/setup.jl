using NeutralLandscapes


function setup_world(pars)
	hhc_zoom = 8
	wth_x, wth_y = ceil.(Int, (pars.lsc_x/pars.wth_zoom, pars.lsc_y/pars.wth_zoom))
	hhc_x, hhc_y = ceil.(Int, (pars.lsc_x/hhc_zoom, pars.lsc_y/hhc_zoom))
	world = World(
		generate_suitability2(pars),
		zeros(pars.lsc_y, pars.lsc_x),
		zeros(Bool, pars.lsc_y, pars.lsc_x),
		zeros(wth_y, wth_x),
		Cache2D{Household{Person}}((hhc_y, hhc_x), hhc_zoom),
		[], []
		)

	calc_quality!(world, pars)
		
	generate_population!(world, pars)
		
	setup_population!(world, pars)
	
	generate_households!(world, pars)
	
	setup_households!(world, pars)

	check_consistency(world)
	
	world
end


function generate_suitability(pars)
	rand(DiamondSquare(H=pars.lsc_ruggedness), (pars.lsc_x, pars.lsc_y)) .*
		pars.lsc_range .+ pars.lsc_min
end

function generate_suitability2(pars)
	rand(PerlinNoise(periods=(10,10), octaves=4), (pars.lsc_x, pars.lsc_y)) .*
		pars.lsc_range .+ pars.lsc_min
end

function calc_quality!(world, pars)
	dist = pars.qual_dist
	dist2 = dist^2
	sz = size(world.lsc)
	
	for x in 1:sz[2]
		minx = max(1, x - dist)
		maxx = min(sz[2], x + dist)
		for y in 1:sz[1]
			miny = max(1, y - dist)
			maxy = min(sz[1], y + dist)

			for xx in minx:maxx,  yy in miny:maxy
				if sq_dist((x,y), (xx,yy)) > dist2
					continue
				end
				world.quality[y,x] += world.lsc[yy,xx]
			end
		end
	end
	nothing
end


function generate_population!(world, pars)
	pop = world.pop
	for i in 1:pars.ini_pop_size
		push!(pop, Person())
	end
end

rnd_in_range(rng) = rand() * (rng[2]-rng[1]) + rng[1]

function setup_population!(world, pars)
	for person in world.pop
		person.sex = rand(0:1)
		# triangular age pyramid
		person.age = min(rand() * 60, rand() * 60)
		person.coop = rnd_in_range(pars.ini_coop)
		person.dispersal = rnd_in_range(pars.ini_dispersal)
		person.dens_dispersal = rnd_in_range(pars.ini_dens_dispersal)
		person.culture = rand()
	end
end		


function generate_households!(world, pars)	
	xrng = (pars.ini_x_ctr - pars.ini_x_range÷2):(pars.ini_x_ctr + pars.ini_x_range ÷ 2)
	yrng = (pars.ini_y_ctr - pars.ini_y_range÷2):(pars.ini_y_ctr + pars.ini_y_range ÷ 2)

	quals = Tuple{Pos, Float64}[]
	for x in xrng, y in yrng
		push!(quals, ((y,x), world.quality[y,x]))
	end
	sort!(quals, by=q->q[2])
	
	# TODO households, families
	for hh in 1:pars.ini_n_hh
		# find the first unoccupied field
		for qi in length(quals):-1:1
			if is_unoccupied(world, quals[qi][1], pars.min_hh_dist)
				break
			end
			pop!(quals)
		end
		
		length(quals) > 0 || error("no initial settlement possible") 
			
		add_household!(world, Household{eltype(world.pop)}(quals[end][1]))
		pop!(quals)
	end
end


function setup_households!(world, pars)
	for p in world.pop
		hh = rand(world.households)
		add_to_household!(hh, p)
	end
	
	for hh in world.households
		try_gain_fields!(hh, world, pars)
		setup_pop_in_hh!(hh, pars)
	end
end


function setup_pop_in_hh!(hh, pars)
	women = eltype(hh.members)[]
	men = eltype(hh.members)[]
	children = eltype(hh.members)[]
	
	for p in hh.members
		if p.age < pars.min_repr_age
			push!(children, p)
		elseif is_female(p)
			push!(women, p)
		else
			push!(men, p)
		end
	end
	
	# assign partners
	for w in women
		if rand() < pars.ini_p_married
			for m in men
				if m.partner == nothing 
					m.partner = w
					w.partner = m
					break
				end
			end
		end
	end
	
	adults = [women; men]
	
	for c in children
		# let's try a couple of times
		for i in 1:5
			parent = rand(adults)
			if parent.age - c.age > pars.min_repr_age
				push!(c.parents, parent)
				push!(c.contacts, parent)
				push!(parent.children, c)
				push!(parent.contacts, c)
				if parent.partner != nothing
					push!(c.parents, parent.partner)
					push!(c.contacts, parent.partner)
					push!(parent.partner.children, c)
					push!(parent.partner.contacts, c)
				end
				break
			end
		end
	end
end
