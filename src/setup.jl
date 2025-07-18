using NeutralLandscapes


function setup_world(pars)
	hhc_zoom = 8
	wth_x, wth_y = ceil.(Int, (pars.lsc_x/pars.wth_zoom, pars.lsc_y/pars.wth_zoom))
	hhc_x, hhc_y = ceil.(Int, (pars.lsc_x/hhc_zoom, pars.lsc_y/hhc_zoom))
	lsc =
		if pars.lsc_mode == 1
			generate_suitability_ds(pars)
		elseif pars.lsc_mode == 2
			generate_suitability_pn(pars)
		elseif pars.lsc_mode == 3
			generate_suitability_hg(pars)
		elseif pars.lsc_mode == 4
			generate_suitability_vo(pars)
		else
			error("unknown lsc mode")
		end

	if pars.lsc_invert
		lsc .= 1.0 .- lsc
	end

	lsc .= lsc .* pars.lsc_range .+ pars.lsc_min
		
	world = World(
		lsc,
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


function generate_suitability_ds(pars)
	lsc = rand(DiamondSquare(H=pars.lsc_ds_ruggedness), (pars.lsc_x, pars.lsc_y))
end

function generate_suitability_pn(pars)
	rand(PerlinNoise(periods=(pars.lsc_pn_periods, pars.lsc_pn_periods), octaves=pars.lsc_pn_octaves,
			valley=Symbol(pars.lsc_pn_valley)), (pars.lsc_x, pars.lsc_y)) 
end


function generate_suitability_hg(pars)
	rand(pars.lsc_x, pars.lsc_y) 
end
	
function generate_suitability_vo(pars)
	rand(DiscreteVoronoi(pars.lsc_vo_n), (pars.lsc_x, pars.lsc_y)).^pars.lsc_vo_exp 
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

		set_token!(person, coop, rnd_in_range(pars.ini_coop))
		set_token!(person, dispersal, rnd_in_range(pars.ini_dispersal))
		set_token!(person, dens_dispersal, rnd_in_range(pars.ini_dens_dispersal))
		set_token!(person, join_disp, rnd_in_range(pars.ini_join_disp))
		person.culture = rand()

		person.auto_genes =
			BitVector(rand(Bool, pars.n_auto_genes)), BitVector(rand(Bool, pars.n_auto_genes))
		person.sex_gene = BitVector(rand(Bool, pars.n_sex_genes))
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
