using MiniObserve

# mean and variance
const MVA = MeanVarAcc{Float64}
# maximum, minimum
const MMA = MaxMinAcc{Float64}


@observe Data world t pars begin
    @record "time" Int t

    # dummy (macrotools bug)
    x=1
end


function ticker(out, model, data)
    println(out, "N: $(length(model.world.pop))")
end
