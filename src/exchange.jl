
function exchange!(household, world, pars)
	household.resources >= 0 && return
	
	exchange_locally!(household, world, pars)
	
	household.resources >= 0 && return
	
	exchange_contacts!(household, world, pars)
	
	nothing
end

function willing_to_exchange(donor, recip, pars)
	p_coop = sum(m->token(m, coop), donor.members) / length(donor.members)
	
	rand() < p_coop
end

function perform_exchange!(hh, self, pars)
	if hh.resources > 0 && willing_to_exchange(hh, self, pars)
		amount = min(hh.resources, -self.resources) * pars.exch_ratio
		self.resources += amount
		hh.resources -= amount
	end
end


# TODO zoom hh cache
function exchange_locally!(self, world, pars)
	for hh in local_households(world, self.pos, pars.exch_radius)
		perform_exchange!(hh, self, pars)
		
		self.resources >= 0 && break
	end
	
	nothing
end


function exchange_contacts!(self, world, pars)
	contacts = Household{Person}[]
	# TODO maybe keep only remote contacts as optimisation
	for p in self.members
		for c in p.contacts
			if !(c.home in contacts)
				push!(contacts, c.home)
			end
		end
	end
	
	#sort!(contacts, by=objectid)
	#unique!(contacts)
	
	for hh in contacts
		if hh == self || close_by(self, hh, pars.exch_radius)
			continue
		end
		perform_exchange!(hh, self, pars)
		
		self.resources >= 0 && break
	end
	
	nothing
end


