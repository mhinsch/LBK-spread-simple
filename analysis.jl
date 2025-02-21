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
    end
end


function ticker(out, model, data)
    um = data.single.n / (data.single.n + data.married.n)
    println(out, "N: $(data.N), UM: $um")
end
