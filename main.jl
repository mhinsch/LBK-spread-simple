include("main_util.jl")
include("src/model.jl")
include("analysis.jl")


function setup_logs(data_fname)
    file = open(data_fname, "w")

    print_header(file, Data)

    file
end


function run(model, log_freq, log_file = nothing, ticker_file=stdout)
    data = observe(Data, model.world, 0, model.pars)
    for i in 1:model.pars.n_steps
        step!(model)
        data = observe(Data, model.world, i, model.pars)
        if ticker_file != nothing
            ticker(ticker_file, model, data)
        end
        if log_file != nothing
            log_results(log_file, data)
        end
    end
end

using Random

const allpars, args = load_parameters(ARGS, AllParams, cmdl = ( 
    ["--log-freq"],
    Dict(:help => "set time steps between log calls", :default => 23*60, :arg_type => Int),
    ["--output", "-o"],
    Dict(:help => "set data output file name", :default => "data.tsv", :arg_type => String)))
    
const pars = allpars[1]

Random.seed!(pars.seed)

println(rand(5))

const model = setup_model(pars)
const log_freq = args[:log_freq]
const data_fname = args[:output]
const log_file = setup_logs(data_fname)
