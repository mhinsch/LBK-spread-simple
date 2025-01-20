include("main_util.jl")
include("src/model.jl")
include("analysis.jl")

include("main.jl")

if !isinteractive()
    @time run(model, pars, log_freq, log_file)
end
