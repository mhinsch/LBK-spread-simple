using NeutralLandscapes


function generate_suitability(pars)
	rand(DiamondSquare(H=pars.lsc_ruggedness), (pars.lsc_x+1, pars.lsc_y+1))
end

function calc_quality!(world, pars)
	dist = pars.qual_dist
	sz = size(world.lsc)
	
	for x in 1:(sz[2])
		minx = max(1, x - dist)
		maxx = min(sz[2], x + dist)
		for y in 1:(sz[1])
			miny = max(1, y - dist)
			maxy = min(sz[1], y + dist)

			for xx in minx:maxx,  yy in miny:maxy
				if sq_dist((x,y), (xx,yy)) > dist^2
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


function setup_population!(pop, lsc, pars)
	for person in pop
		person.sex = rand(0:1)
		person.age = rand() * 60
		person.coop = rand()
		person.dispersal = rand()
		person.culture = rand()
	end
end


function setup_world!(world, pars)
	world = World(
		Landscape(generate_suitability(pars)),
		zeros(pars.lsx_x, pars.lsc_y),
		zeros(pars.lsx_x÷pars.wth_zoom+1, pars.lsc_y÷pars.wth_zoom+1),
		[], []
		)
		
	calc_quality!(world, pars)
		
	generate_population!(world, pars)
		
	setup_population!(world.pop, world.lsc)
end
