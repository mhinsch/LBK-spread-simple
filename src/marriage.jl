

want_to_marry(person, pars) = person.age > pars.minor_age && is_single(person)


function attempt_marriage!(person, world, pars)
	candidates = typeof(person)[]
	for hh in local_households(world, person.home.pos, pars.marriage_radius)
		collect_candidates!(candidates, hh, person, pars)
	end
	
	if !isempty(candidates)
		marriage!(person, rand(candidates), world, pars)
	end
	
	nothing	
end


function collect_candidates!(cand, hh, person, pars)
	for p in hh.members
		if p.sex != person.sex && p.age > pars.minor_age && is_single(p) && 
			!(p in person.children) && !(p in person.parents) && 
			!intersect(p.parents, person.parents) && rand() < pars.prob_candidate
			push!(cand, p)
		end
	end
end


function marriage!(p1, p2, world, pars)
	@assert p1.partner == p2.partner == nothing
	@assert p1.sex != p2.sex
	
	p1.partner = p2
	p2.partner = p1
	
	# already living together
	if p1.home == p2.home
		return
	end

	# one of them has to move
	move, stay = rand(Bool) ? (p1, p2) : (p2, p1)
		
	leavers = [move]
	for child in move.children
		if child.age <= pars.minor_age && child.home == move.home
			push!(leavers, child)
		end
	end
	
	move_to_household!(leavers, stay.home, world, pars)

	@assert p1.home == p2.home
	
	nothing
end
	
