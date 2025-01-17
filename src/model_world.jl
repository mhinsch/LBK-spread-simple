
function world_updates!(world, pars)
	
	weather!(world, pars)
	
	shuffle!(world.households)
	for hh in world.households
		production!(hh, world, pars)
	end
	
	shuffle!(world.households)
	for hh in world.households
		provisioning!(hh, pars)
	end
	
	shuffle!(world.households)
	for hh in world.households
		exchange!(hh, world, pars)
	end
	
	shuffle!(world.pop)
	# iterate in reverse so that births and deaths don't invalidate
	for person in Iterators.reverse(world.pop)
		person_updates!(person, world, pars)
	end
	
	remove_all_dead!(world.pop)
end


function weather!(world, pars)
	rand!(world.weather, DiamondSquare(H=pars.wth_ruggedness))
end


function harvest(pos, world, pars)
	world.lsc[pos] * weather_at(pos..., world, pars)
end


function add_to_world!(world, child)
	push!(world.pop, child)
end


function remove_all_dead!(pop)
	for i in length(pop):-1:1
		if is_dead(pop[i])
			pop[i] = pop[end]
			pop!(pop)
		end
	end
	nothing
end		
