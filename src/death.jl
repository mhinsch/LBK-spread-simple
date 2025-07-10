
function death_prob(person, pars)
	hh = person.home
	prov = hh.resources < 0 ?
		1.0 + hh.resources/length(hh.members) : 1.0
	
	1.0 - (1.0-pars.death_prob) * prov
end


function die!(person, world, pars)
	person.age = -1.0 # hacky death marker, so that we can remove all dead at the same time
	for p in person.parents
		remove_unsorted!(p.children, person)
	end
	
	for c in person.contacts
		remove_unsorted!(c.contacts, person)
	end
	
	for c in person.children
		remove_unsorted!(c.parents, person)
	end
	
	if !is_single(person)
		person.partner.partner = nothing
		person.partner = nothing
	end
	
	remove_unsorted!(person.home.members, person)
	
	nothing
end

