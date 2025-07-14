using MiniObserve

# mean and variance
const MVA = MeanVarAcc{Float64}
# maximum, minimum
const MMA = MaxMinAcc{Float64}


@observe Data world t pars begin
    @record "time" Int t
    @record "N" Int length(world.pop)


    for p in world.pop
        @stat("married", CountAcc) <| (! is_single(p))
        @stat("single", CountAcc) <| (p.age > pars.minor_age && is_single(p))
        @stat("coop", MVA) <| token(p, coop)
        @stat("dispersal", MVA) <| token(p, dispersal)
        @stat("ddispersal", MVA) <| token(p, dens_dispersal)
        @stat("join", MVA) <| token(p, join_disp)
        @stat("mig", MVA) <| (1-(1-token(p, dispersal)^3)^40)
    end

    for hh in world.households
        @stat("hh_size", MVA, MMA) <| 1.0*length(hh.members)
        @stat("hh_res", MVA) <| hh.resources
    end
end


function ticker(out, model, data)
    um = data.single.n / (data.single.n + data.married.n)
    println(out, "$(data.time) - N: $(data.N), UM: $um, coop: $(data.coop.mean), mig: $(data.dispersal.mean), dmig: $(data.ddispersal.mean)")
end
