
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

function move_to_household!(leavers, new_hh, world, pars)
	for p in leavers
		find_remove!(p.home.members, p)
		p.pos = new_hh
	end
	append!(new_hh.members, leavers)
	
	try_gain_fields!(new_hh, world, pars)
end	


function provisioning!(household, pars)
	household.resources -= length(household.members)
	nothing
end

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

