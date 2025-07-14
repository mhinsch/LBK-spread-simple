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



using SSDL
using SimpleGraph
using SimpleGui


### draw GUI

# draw world to canvas
function draw_world(canvas, model)
	xs = canvas.xsize - 1
	ys = canvas.ysize - 1

	world = model.world
	pars = model.pars

	lsc = world.lsc
	weather = world.weather
	zoomy = size(lsc)[1] / ys
	zoomx = size(lsc)[2] / xs

	for y in 1:size(lsc)[1], x in 1:size(lsc)[2]
		p = floor.(Int, (y,x) ./ (zoomy, zoomx)) .+ (1,1)

		q = limit(0.0, lsc[y,x], 1.0)

		col = rgb(q*155, q*155, q*155)
		put(canvas, p[2], p[1], col)
	end

	for hh in world.households
		x, y = floor.(Int, (hh.pos[2]/zoomx, hh.pos[1]/zoomy))
		circle_fill(canvas, x, y, 1, rgb(250, 0, 0), true)
		for f in hh.fields 
			q = limit(0.0, harvest(f[1], world, pars), 1.0)
			col = rgb((1-q)*255, q*255, 0)
			xx, yy = floor.(Int, (f[1][2]/zoomx, f[1][1]/zoomy))
			if 0<xx<=canvas.xsize && 0<yy<=canvas.ysize
				put(canvas, xx, yy, col)
			end
		end
	end
end

# draw both panels to video memory
function draw(model, graphs1, graphs2, graphs3, graphs4, gui)
	bg = rgb(100, 100, 100)
	redraw_at!(gui, 1, bg) do canvas
		draw_world(canvas, model)
	end

	redraw_at!(gui, 2, bg) do canvas
		draw_graph(canvas, graphs1)
	end

	redraw_at!(gui, 3, bg) do canvas
		draw_graph(canvas, graphs2)
	end

	redraw_at!(gui, 4, bg) do canvas
		draw_graph(canvas, graphs3)
	end
	
	redraw_at!(gui, 5, bg) do canvas
		draw_graph(canvas, graphs4)
	end
end

