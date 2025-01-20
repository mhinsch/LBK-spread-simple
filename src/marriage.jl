
function attempt_marriage!(person, world, pars)
	candidates = typeof(person)[]
	for hh in local_households(world, person.home.pos, pars.marriage_radius)
		collect_candidates!(candidates, hh, person, pars)
	end
	
	if !isempty(candidates)
		marriage!(person, rand(candidates), pars)
	end
	
	nothing	
end


function collect_candidates!(cand, hh, person, pars)
	for p in hh.members
		if p.sex != person.sex && p.age > pars.min_age_marry && 
			!(p in person.children) && !(p in person.parents) && 
			!(intersects(p.parents, person.parents)) && rand() < pars.prob_candidate
			push!(cand, p)
		end
	end
end


function marriage!(p1, p2, pars)
	@assert p1.partner == p2.partner == nothing
	
	p1.partner = p2
	p2.partner = p1
	
	move, stay = rand(0:1) ?
		p1, p2 : p2, p1
		
	leavers = [move]
	for child in leavers.children
		if child.age < pars.age_minor
			push!(leavers, child)
		end
	end
	
	move_to_household!(leavers, new_hh, world, pars)
	
	nothing
end
	
