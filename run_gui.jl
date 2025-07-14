#   Copyright (C) 2020 Martin Hinsch <hinsch.martin@gmail.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.



include("main_util.jl")
include("src/model.jl")
include("analysis.jl")


using SimpleDirectMediaLayer.LibSDL2
import Colors
using Colors: distinguishable_colors, RGB

push!(LOAD_PATH, pwd())


using SimpleGui

include("draw_gui.jl")



### run simulation with given setup and parameters

function run(model, gui, graphs1, graphs2, graphs3, graphs4, logfile)
	t = 1.0
	last = 0

	pause = false
	quit = false
	while ! quit
		# don't do anything if we are in pause mode
		if pause
			sleep(0.03)
		else
			t1 = time()
			step!(model) # run internal scheduler up to the next time step
			data = observe(Data, model.world, t, model.pars)
		
			# print all stats to file
			#print_stats(logfile, model)
			# this is suboptimal, as all these are calculated in print_stats as well
			# solution forthcoming
			add_value!(graphs1[1], data.N)
			
			add_value!(graphs2[1], data.coop.mean)

			add_value!(graphs3[1], data.dispersal.mean)
			add_value!(graphs3[2], data.ddispersal.mean)
			add_value!(graphs3[3], data.join.mean)
			add_value!(graphs3[4], data.mig.mean)
			
			add_value!(graphs4[1], data.hh_size.mean)
			add_value!(graphs4[2], data.hh_size.max)
			add_value!(graphs4[3], data.hh_res.mean)

			t += 1

			ticker(stdout, model, data)
		end

		event_ref = Ref{SDL_Event}()
        while Bool(SDL_PollEvent(event_ref))
            evt = event_ref[]
            evt_ty = evt.type
			if evt_ty == SDL_QUIT
                quit = true
                break
            elseif evt_ty == SDL_KEYDOWN
                scan_code = evt.key.keysym.scancode
                if scan_code == SDL_SCANCODE_ESCAPE || scan_code == SDL_SCANCODE_Q
					quit = true
					break
                elseif scan_code == SDL_SCANCODE_P || scan_code == SDL_SCANCODE_SPACE
					pause = !pause
                    break
                else
                    break
                end
            end
		end

		# draw gui to video memory
		draw(model, graphs1, graphs2, graphs3, graphs4, gui)
		# copy to screen
		render!(gui)
	end
end


function setup_logs(data_fname)
    file = open(data_fname, "w")

    print_header(file, Data)

    file
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

const gui = setup_Gui("SRM", 2000, 1000, (1:2, 1:2), (3,1), (3,2), (4,1), (4,2))

const rawcolors = distinguishable_colors(8, [RGB(1,1,1), RGB(0,0,0)], dropseed=true)
const colors = map(c->(Colors.red(c), Colors.green(c), Colors.blue(c)).*255, rawcolors)

const graphs1 = [Graph{Int}(rgb(colors[1]...), "N")] 

const graphs2 = [Graph{Float64}(rgb(colors[1]...), "coop")] 

const graphs3 = [
	Graph{Float64}(rgb(colors[1]...), "mig"), 
	Graph{Float64}(rgb(colors[2]...), "dens mig"), 
	Graph{Float64}(rgb(colors[3]...), "join mig"), 
	Graph{Float64}(rgb(colors[4]...), "lt mig")] 


const graphs4 = [
	Graph{Float64}(rgb(colors[1]...), "hh size"), 
	Graph{Float64}(rgb(colors[2]...), "max hh size"), 
	Graph{Float64}(rgb(colors[3]...), "hh res")] 
## run

run(model, gui, graphs1, graphs2, graphs3, graphs4, log_file)



## cleanup

close(log_file)

#SDL2.Quit()
