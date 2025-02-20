
can_reproduce(person, pars) = is_female(person)  && ! is_single(person) &&
	pars.min_repr_age <= person.age <= pars.max_repr_age

repr_prob(person, pars) = pars.repr_prob

function reproduce!(mother, father, world, pars)
	@assert mother.home == father.home
	
	child = Person(mother.home, rand(0:1), 0.0, 
		nothing, [mother, father], [], [mother, father],
		mother.coop, mother.dispersal, mother.culture)
		
	for parent in (mother, father)
		push!(parent.children, child)
		push!(parent.contacts, child)
	end
	
	add_to_household!(mother.home, child)
	add_to_world!(world, child)
	
	child
end
