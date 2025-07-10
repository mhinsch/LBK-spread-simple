


function culture!(hh, world, pars)
	disp = 0.0
	coop = 0.0
	ddisp = 0.0

	for m in hh.members
		disp += m.dispersal
		coop += m.coop
		ddisp += m.dens_dispersal
	end

	disp /= length(hh.members)
	coop /= length(hh.members)
	ddisp /= length(hh.members)

	for m in hh.members
		m.dispersal = (1.0 - pars.influence) * m.dispersal + pars.influence * disp
		m.coop = (1.0 - pars.influence) * m.coop + pars.influence * coop
		m.dens_dispersal = (1.0 - pars.influence) * m.dens_dispersal + pars.influence * ddisp
	end
	nothing
end
