include("main.jl")

if !isinteractive()
    @time run(model, log_freq)
end
