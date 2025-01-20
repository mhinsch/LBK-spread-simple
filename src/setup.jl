using NeutralLandscapes


function setup_world(pars)
	world = World(
		generate_suitability(pars),
		zeros(pars.lsc_y, pars.lsc_x),
		zeros(Bool, pars.lsc_x, pars.lsc_y),
		zeros(pars.lsc_y÷pars.wth_zoom+1, pars.lsc_x÷pars.wth_zoom+1),
		[ [] for y in 1:pars.lsc_y÷pars.hhc_zoom, x in 1:pars.lsc_x÷pars.hhc_zoom ],
		[], []
		)
		
	calc_quality!(world, pars)
		
	generate_population!(world, pars)
		
	setup_population!(world, world, pars)
	
	generate_households!(world, pars)
	
	world
end


function generate_suitability(pars)
	rand(DiamondSquare(H=pars.lsc_ruggedness), (pars.lsc_x, pars.lsc_y))
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
				@inbounds world.quality[y,x] += world.lsc[yy,xx]
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


function setup_population!(world, pars)
	for person in world.pop
		person.sex = rand(0:1)
		person.age = rand() * 60
		person.coop = rand()
		person.dispersal = rand()
		person.culture = rand()
	end
end		


function generate_households!(world, pars)	
	y = size(world.lsc)[1]
	
	quals = [ (x, world.quality[y,x]) for x in 1:size(world.lsc)[2] ]
	sort!(quals, by=q->q[2])
	
	# TODO households, families
	for hh in 1:pars.ini_n_hh
		for x in length(quals):-1:1
			if is_unoccupied((x,y), world, pars.min_hh_dist)
				break
			end
			pop!(quals)
		end
		
		length(quals) > 0 || error("no initial settlement possible") 
			
		push!(world.households, Household(quals[end], [], []))
	end
end


