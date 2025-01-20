
death_prob(person, pars) = pars.death_prob


function die!(person, world, pars)
	person.age = -1.0 # hacky death marker, so that we can remove all dead at the same time
	for p in person.parents
		find_remove!(p.children, person)
	end
	
	for c in person.contacts
		find_remove!(c.contacts, person)
	end
	
	for c in person.children
		find_remove!(c.parents, person)
	end
	
	find_remove!(person.home.members, person)	
	
	nothing
end

