limit(mi, v, ma) = max(mi, min(ma, v))


function intersect(c1, c2)
	for c in c1
		if c in c2
			return true
		end
	end

	false
end


function remove_unsorted!(cont, obj)
    for (i, el) in enumerate(cont)
        if el == obj
            remove_unsorted_at!(cont, i)
            return
        end
    end

    error("obj not found!")
end

function remove_unsorted_at!(cont, idx)
    cont[idx] = cont[end]
    pop!(cont)
end


close_by(o1, o2, r) = sq_dist(o1.pos, o2.pos) < r^2

sq_dist(a, b) = sum((a[1]-b[1], a[2]-b[2]).^2)



struct Cache2D{ELT}
	data :: Matrix{Vector{ELT}}
	zoom :: Int
end


Cache2D{ELT}(sz::Tuple{Int, Int}, zoom::Int) where {ELT} = 
	Cache2D{ELT}([ ELT[] for y in 1:sz[1], x in 1:sz[2]], zoom)
	
pos2cache_idx(cache, pos) = pos[1]÷cache.zoom + 1, pos[2]÷cache.zoom + 1
	
function add_to_cache!(cache, item, pos)
	push!(cache.data[pos2cache_idx(cache, pos)...], item)
end

function remove_from_cache!(cache, item, pos)
	remove_unsorted!(cache.data[pos2cache_idx(cache, pos)...], item)
end


mutable struct Cache2DIter{ELT}
	cache :: Matrix{Vector{ELT}}
	pos :: Tuple{Int, Int}
	r2 :: Int
	top :: Int
	left :: Int
	ym :: Int
	xm :: Int
	i :: Int
	j :: Int
end

function iter_circle(cache, pos, radius)
	#println(pos, " ", radius)
	# coordinates of window in cache
	top_left = floor.(Int, (pos .- radius) ./ cache.zoom)
	bot_right = ceil.(Int, (pos .+ radius) ./ cache.zoom)
	sz = size(cache.data) 
	tl_clipped = max.(1, top_left)
	br_clipped = min.(sz, bot_right)
	Cache2DIter(cache.data, pos, radius^2, 
		tl_clipped[1], 
		tl_clipped[2], 
		# second set is sizes, not coordinates
		br_clipped[1] - tl_clipped[1], 
		br_clipped[2] - tl_clipped[2],
		0, 1)
end


function Base.iterate(hhci::CACHE) where {CACHE <: Cache2DIter}
	iterate(hhci, hhci)
end
	
function Base.iterate(hhci::CACHE, dummy) where {CACHE <: Cache2DIter}
	#dump(hhci)
	yo = 0
	while true
		y, x = hhci.top + hhci.i%(hhci.ym+1), hhci.left + hhci.i÷(hhci.ym+1)
		if yo != y
			yo = y
			#println()
		end
		#print("$y,$x,$(hhci.i)|")
		vec = hhci.cache[y, x]
		if hhci.j <= length(vec)
			el = vec[hhci.j]
			hhci.j += 1
			if sum((el.pos .- hhci.pos).^2) < hhci.r2
				#print("!")
				return el, hhci
			end
		else
			hhci.i += 1
			if hhci.i >= (hhci.xm+1) * (hhci.ym+1)
				#println(".")
				return nothing
			end
			hhci.j = 1
		end
	end
end


# based on this code:
# https://stackoverflow.com/questions/40273880/draw-a-line-between-two-pixels-on-a-grayscale-image-in-julia
function bresenham(f :: Function, x1::Int, y1::Int, x2::Int, y2::Int)
	#println("b: ", x1, ", ", y1)
	#println("b: ", x2, ", ", y2)
	# Calculate distances
	dx = x2 - x1
	dy = y2 - y1

	# Determine how steep the line is
	is_steep = abs(dy) > abs(dx)

	# Rotate line
	if is_steep == true
		x1, y1 = y1, x1
		x2, y2 = y2, x2
	end

	# Swap start and end points if necessary 
	if x1 > x2
		x1, x2 = x2, x1
		y1, y2 = y2, y1
	end
	# Recalculate differentials
	dx = x2 - x1
	dy = y2 - y1

	# Calculate error
	error = round(Int, dx/2.0)

	if y1 < y2
		ystep = 1
	else
		ystep = -1
	end

	# Iterate over bounding box generating points between start and end
	y = y1
	for x in x1:x2
		if is_steep == true
			coord = (y, x)
		else
			coord = (x, y)
		end

		f(coord[1], coord[2])

		error -= abs(dy)

		if error < 0
			y += ystep
			error += dx
		end
	end

end
