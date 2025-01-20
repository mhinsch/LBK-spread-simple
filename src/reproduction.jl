
can_reproduce(person, pars) = is_female(person) && pars.min_repr_age <= person.age <= pars.max_repr_age

repr_prob(person, pars) = pars.repr_prob

function reproduce!(mother, father, world, pars)
	child = Person(parent.home, rand(0:1), 0.0, 
		[mother, father], [], [mother, father],
		parent.coop, parent.dispersal, parent.culture)
		
	for parent in (mother, father)
		push!(parent.children, child)
		push!(parent.contacts, child)
	end
	
	add_to_household!(mother.home, child)
	add_to_world!(world, child)
	
	child
end
