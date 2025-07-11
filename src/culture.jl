


function culture!(hh, world, pars)
	pop_values = zeros(length(instances(Tokens)))
	
	for m in hh.members
		for t in instances(Tokens)
			pop_values[Int(t)] += token(m, t)
		end
	end

	pop_values ./= length(hh.members)

	for m in hh.members
		for t in instances(Tokens)
			set_token!(m, t, (1.0 - pars.influence) * token(m, t) + pars.influence * pop_values[Int(t)])
		end
	end
	nothing
end
