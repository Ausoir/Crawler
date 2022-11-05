var vaults = preload("res://world/vaults.gd").new()
var width
var height
var terrains
var objects

func generate(size):
	width = size.x
	height = size.y
	terrains = make_base(width, height, ' ')
	objects = make_base(width, height, null)
	G.rng.set_seed(G.vars.seed + 3456789)
#	place_poi("town", [0,2,4,6], G.rng.f())
	generate_wild()

func place_poi(structure, dirs, ssd, flip=false, crop=null):
	if vaults.load_vault(structure, terrains, objects):
		var dir = G.rng.r_arr(dirs)
		if dir != null:
			vaults.rot = dir
		if flip:
			if dir < 2:
				vaults.flip = G.rng.ir(0, 1)
			elif dir < 4:
				vaults.flip = 2 if G.rng.b() else 0
			elif dir < 6:
				vaults.flip = G.rng.ir(0, 1)
			else:
				vaults.flip = 2 if G.rng.b() else 0
		var bounds = [0,0,width-1, height-1]
		vaults.make_vault(ssd, bounds, crop)

func make_base(sx, sy, val):
	var r = []
	for _y in range(sy):
		var row = []
		for _x in range(sx):
			row.append(val)
		r.append(row)
	return r

func make_random(sx, sy):
	var r = []
	for _y in range(sy):
		var row = []
		for _x in range(sx):
			row.append(G.rng.f())
		r.append(row)
	return r

func make_smooth(map, level):
	var w = len(map[0])
	var h = len(map)
	var r = []
	var period = 2 << level
	var frequency = 1.0 / period
	for y in range(h):
		var sample1 = int(y / period) * period
		var sample2 = int((sample1 + period) % h)
		var horizontal_blend = (y - sample1) * frequency
		var row = []
		for x in range(w):
			var sample3 = int(x / period) * period
			var sample4 = int((sample3 + period) % w)
			var vertical_blend = (x - sample3) * frequency
			var top = interpolate(map[sample1][sample3], map[sample2][sample3], horizontal_blend)
			var bot = interpolate(map[sample1][sample4], map[sample2][sample4], horizontal_blend)
			row.append(interpolate(top, bot, vertical_blend))
		r.append(row)
	return r
		
func interpolate(arg1, arg2, alpha):
	return arg1 * (1 - alpha) + alpha * arg2

func make_perlin(sx, sy, levels=5, start=1):
	var r = make_random(sx, sy)
	var map = make_base(sx, sy, 0)
	var max_value = 0
	for i in range(start, levels+1):
		max_value += float(1)/i
	for level in range(start, levels+1):
		var graph = make_smooth(r, level)
		for y in range(sy):
			for x in range(sx):
				map[y][x] += graph[y][x] * 1/level
	for y in range(sy):
		for x in range(sx):
			map[y][x] /= max_value
	return map

func generate_wild():
	var vals = make_perlin(width, height)
	var area_data = G.data.vars.area.surface
	for ty in range(height):
		for tx in range(width):
			var value = vals[ty][tx]
			var area = assign_area(area_data, value)
			if area != null:
				terrains[ty][tx] = area[1]
				objects[ty][tx] = area[2]
			else:
				print("Could not find area data "+str(value))

func assign_area(area_data, value):
	for area in area_data:
		if value < area[0]:
			return area

func get_direction_to(tgt, neighbors):
	var dir = []
	var count = 0
	for neighbor in neighbors:
		if neighbor == tgt:
			dir.append(count)
		count += 1
	return dir
