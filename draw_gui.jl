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
	zoomy = size(lsc)[1] / ys
	zoomx = size(lsc)[2] / xs

	for y in 1:size(lsc)[1], x in 1:size(lsc)[2]
		p = floor.(Int, (y,x) ./ (zoomy, zoomx)) .+ (1,1)

		col = rgb((1.0-lsc[y,x])*255, lsc[y,x]*255, 0)
		put(canvas, p[2], p[1], col)
	end

	for hh in world.households
		x, y = floor.(Int, (hh.pos[2]/zoomx, hh.pos[1]/zoomy))
		circle_fill(canvas, x, y, 2, WHITE, true)
		for f in hh.fields 
			xx, yy = floor.(Int, (f[1][2]/zoomx, f[1][1]/zoomy))
			put(canvas, xx, yy, blue(floor(UInt32, 100*f[2] + 155)))
		end
	end
end

# draw both panels to video memory
function draw(model, graphs, gui)
	clear!(gui.canvas)
	draw_world(gui.canvas, model)
	SimpleGui.update!(gui.panels[1,1], gui.canvas)

	clear!(gui.canvas)
	draw_graph(gui.canvas, graphs)
	SimpleGui.update!(gui.panels[2, 1], gui.canvas)
end

