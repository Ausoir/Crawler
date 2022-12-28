var vaults = preload("res://world/vaults.gd").new()
var width
var height
var terrains
var objects
var terrain_biomes
var spawn_points

func generate_base():
	var biome = "base"
	width = 2
	height = 1
	terrains = make_base(width, height, 'X')
	objects = make_base(width, height, null)
	terrain_biomes = make_base(width, height, 0)
	G.rng.set_seed(G.vars.seed + 3456789)
	place_poi(Vector2(0, 0), biome, [0], 0)
	paint_palette(biome)
	objects.append({"name": "prepare", "pos": [1, 0]})

func generate_dungeon(biome):
	var landscape = int(G.vars.seed) % 2 == 0
	if landscape:
		width = 60
		height = 40
	else:
		width = 40
		height = 60
	terrains = make_base(width, height, ' ')
	objects = make_base(width, height, null)
	terrain_biomes = make_base(width, height, 0)
	G.rng.set_seed(G.vars.seed + 3456789)
	if landscape:
		place_poi(Vector2(0, 0), "dungeon_c", [0], G.rng.f())
		place_poi(Vector2(10, 0), "dungeon_s", [0], G.rng.f(), G.rng.ir(0, 1))
		place_poi(Vector2(30, 0), "dungeon_s", [0], G.rng.f(), G.rng.ir(0, 1))
		place_poi(Vector2(50, 0), "dungeon_c", [6], G.rng.f())

		place_poi(Vector2(0, 10), "dungeon_s", [2], G.rng.f(), G.rng.ir(0, 1)*2)
		place_poi(Vector2(10, 10), "dungeon_f", [0,2,4,6], G.rng.f(), G.rng.ir(0, 3))
		place_poi(Vector2(30, 10), "dungeon_f", [0,2,4,6], G.rng.f(), G.rng.ir(0, 3))
		place_poi(Vector2(50, 10), "dungeon_s", [6], G.rng.f(), G.rng.ir(0, 1)*2)

		place_poi(Vector2(0, 30), "dungeon_c", [2], G.rng.f())
		place_poi(Vector2(10, 30), "dungeon_s", [4], G.rng.f(), G.rng.ir(0, 1))
		place_poi(Vector2(30, 30), "dungeon_s", [4], G.rng.f(), G.rng.ir(0, 1))
		place_poi(Vector2(50, 30), "dungeon_c", [4], G.rng.f())
	else:
		place_poi(Vector2(0, 0), "dungeon_c", [0], G.rng.f())
		place_poi(Vector2(10, 0), "dungeon_s", [0], G.rng.f(), G.rng.ir(0, 1))
		place_poi(Vector2(30, 0), "dungeon_c", [6], G.rng.f())

		place_poi(Vector2(0, 10), "dungeon_s", [2], G.rng.f(), G.rng.ir(0, 1)*2)
		place_poi(Vector2(10, 10), "dungeon_f", [0,2,4,6], G.rng.f(), G.rng.ir(0, 3))
		place_poi(Vector2(30, 10), "dungeon_s", [6], G.rng.f(), G.rng.ir(0, 1)*2)

		place_poi(Vector2(0, 30), "dungeon_s", [2], G.rng.f(), G.rng.ir(0, 1)*2)
		place_poi(Vector2(10, 30), "dungeon_f", [0,2,4,6], G.rng.f(), G.rng.ir(0, 3))
		place_poi(Vector2(30, 30), "dungeon_s", [6], G.rng.f(), G.rng.ir(0, 1)*2)

		place_poi(Vector2(0, 50), "dungeon_c", [2], G.rng.f())
		place_poi(Vector2(10, 50), "dungeon_s", [4], G.rng.f(), G.rng.ir(0, 1))
		place_poi(Vector2(30, 50), "dungeon_c", [4], G.rng.f())
	paint_palette(biome)

func paint_palette(biome):
	spawn_points = []
	var palette = make_palette(biome)
	var area_data = G.data.level_data.get(biome).biome
	var area_data2 = G.data.level_data.get(biome).get("biome2")
	if area_data2 == null:
		area_data2 = G.data.level_data.base.get("biome2")
	var r_obj = []
	for y in range(height):
		for x in range(width):
			var terrain = terrains[y][x]
			var obj = objects[y][x]
			if terrain == " ":
				var perlin = get_perlin_at(x, y)
				var assigned = assign_area(area_data, perlin)
				terrain_biomes[y][x] = perlin
				terrain = assigned[1]
				if obj == null and assigned.size() > 2:
					obj = assigned[2]
			elif terrain == "*":
				var perlin = get_perlin_at(x, y)
				var assigned = assign_area(area_data2, perlin)
				terrain_biomes[y][x] = perlin
				terrain = assigned[1]
				if obj == null and assigned.size() > 2:
					obj = assigned[2]
				spawn_points.append([x, y])
			var pal = palette.get(terrain)
			if pal != null:
				if pal[0].length() > 1:
					terrain = G.rng.r_arr(pal[0])
				else:
					terrain = pal[0]
				if pal.size() > 1:
					obj = pal[1]
			terrains[y][x] = terrain
			if obj != null:
				for item in G.data.get_combo(obj):
					r_obj.append({"name": item, "pos": [x, y]})
	objects = r_obj

func make_palette(biome):
	var r = {}
	var default_palette = G.data.level_data.base.palette
	for key in default_palette:
		r[key] = default_palette[key]
	var bpalette = G.data.level_data.get(biome).palette
	for key in bpalette:
		r[key] = bpalette[key]
	return r

func generate_items(tiles):
	for _i in range(20):
		var x = G.rng.ir(0, width-1)
		var y = G.rng.ir(0, height-1)
		var tile = tiles[y][x]
		var biome = terrain_biomes[y][x]
		if G.rng.r_percent(biome) and !tile.is_col(14):
			var combo = G.data.vars.habitat.get(tile.icon)
			if combo != null:
				for item in G.data.get_combo(combo):
					G.factory.make_any(item, tile)

func place_poi(pos, structure, dirs, sd, flip=0):
	if vaults.load_vault(structure, terrains, objects):
		var dir = G.rng.r_arr(dirs)
		if dir != null:
			vaults.rot = dir
		vaults.flip = flip
		var bounds = [pos.x,pos.y]
		vaults.make_vault(sd, bounds)

func make_base(sx, sy, val):
	var r = []
	for _y in range(sy):
		var row = []
		for _x in range(sx):
			row.append(val)
		r.append(row)
	return r

func get_perlin_at(x, y):
	G.rng.set_seed(G.vars.seed + 1234567)
	var w2 = width/2.0
	var h2 = height/2.0
	var w4 = width/3.0
	var h4 = height/3.0
	var w16 = width/4.0
	var h16 = height/4.0
	var value = G.rng.f()
	G.rng.set_seed(G.rng.f() * (int(x/w16)+int(y/h16)*width))
	value += G.rng.f()
	G.rng.set_seed(G.rng.f() * (int(x/w4)+int(y/h4)*width))
	value += G.rng.f()
	G.rng.set_seed(G.rng.f() * (int(x/w2)+int(y/h2)*width))
	value += G.rng.f()
	return value / 4.0

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
