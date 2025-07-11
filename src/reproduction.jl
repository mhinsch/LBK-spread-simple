
can_reproduce(person, pars) = is_female(person)  && ! is_single(person) &&
	pars.min_repr_age <= person.age <= pars.max_repr_age

repr_prob(person, pars) = pars.repr_prob

function reproduce!(mother, father, world, pars)
	@assert mother.home == father.home
	
	sex = rand((true, false))
	
	child = Person(mother.home, sex, 0.0, 
		nothing, [mother, father], [], [mother, father],
		copy(mother.tokens),
		(copy(mother.auto_genes[rand(1:2)]), copy(father.auto_genes[rand(1:2)])),
		(sex ? copy(mother.sex_gene) : copy(father.sex_gene)),
		mother.culture)

	mutate_genes!(child, pars)
	
	if rand() < pars.p_mut
		mutate!(child, pars)
	end
	
	for parent in (mother, father)
		push!(parent.children, child)
		push!(parent.contacts, child)
	end
	
	add_to_household!(mother.home, child)
	add_to_world!(world, child)
	
	child
end


function crossover!(gene1, gene2, pars)
	n_co = rand(Poisson(pars.rate_crossover))

	if n_co < 1
		return
	end

	co_sites = rand(1:length(gene1), n_co) |> sort! |> unique!

	flip = rand((true, false))
	c = 1

	for i in 1:length(gene1)
		if c <= length(co_sites) && co_sites[c] == i
			flip = !flip
			c += 1
		end

		if flip
			gene1[i], gene2[i] = gene2[i], gene1[i]  
		end
	end

	nothing
end


function mutate_genes!(child, pars)
	crossover!(child.auto_genes..., pars)
	
	for c in 1:2, i in 1:pars.n_auto_mutate
		chrom = child.auto_genes[c]
		m = rand(1:length(chrom))
		chrom[m] = !chrom[m]
	end

	for i in 1:pars.n_sex_mutate
		m = rand(1:length(child.sex_gene))
		child.sex_gene[m] = !child.sex_gene[m]
	end
end

function mutate!(child, pars)
	for t in instances(Tokens)
		set_token!(child, t, limit(0.0, token(child, t) + rand(Normal(0.0, pars.d_mut)), 1.0))
	end
end
