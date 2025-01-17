using MiniEvents


@events person :: Person begin
	@debug
	
	@rate(r_rate(person, @sim().pars)) ~
		is_female(person) && can_reproduce(person, @sim().pars) => begin
			child = reproduce!(person, @sim().model, @sim().pars)
			spawn!(child, @sim())
			@r person 
		end
		
	# TODO think about refresh
	@rate(death_rate(person, @sim().pars)) ~
		true => begin
			die!(person, @sim().model)
			@kill person
		end
		
	@rate(mig_rate(person, @sim().pars)) ~
		can_decide_migrate(person, @sim().pars) => begin
			affected = migrate!(person, @sim().model, @sim().pars)
			@r person affected
		end
		
	@rate(trade_rate(person, @sim().model, pars)) ~
		can_trade(person, @sim().pars) => begin
			affected = trade!(person, @sim().model, @sim().pars)
			@r person affected
		end
end


@events model :: Model begin
	@repeat(1.0, 0.5) => begin
		world_updates!(model, @sim().pars)
		@r model.pop
	end
end
