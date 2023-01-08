const UNIT_POLYGON = [Vector2(0,0),Vector2(1,0),Vector2(2,0),Vector2(2,1),Vector2(2,2),Vector2(1,2),Vector2(0,2),Vector2(0,1)]
var file
var json_cache = {}
var images_cache = {}
var sounds_cache = {}
var particles_cache = {}
var vars
var terrain_data
var item_data
var shop_items = []
var unit_data
var ability_data
var trait_data
var group_data
var recipe_data
var level_data
var worldmap

func _init():
	file = File.new()
	vars = get_json_from_dir("res://assets/json/vars.json")
	terrain_data = get_json_from_dir("res://assets/json/terrains.json")
	item_data = {}
	for filename in vars["item files"]:
		var itemfile = get_json_from_dir("res://assets/json/"+filename+".json")
		set(filename, itemfile)
		attach_meta(itemfile)
		for key in itemfile:
			var item = itemfile[key]
			item_data[key] = item
			if item.get("value") != null:
				shop_items.append(item)
	unit_data = {}
	for filename in vars["unit files"]:
		var itemfile = get_json_from_dir("res://assets/json/"+filename+".json")
		set(filename, itemfile)
		attach_meta(itemfile)
		for key in itemfile:
			unit_data[key] = itemfile[key]
	ability_data = get_json_from_dir("res://assets/json/abilities.json")
	attach_meta(ability_data)
	trait_data = get_json_from_dir("res://assets/json/traits.json")
	attach_meta(trait_data)
	group_data = get_json_from_dir("res://assets/json/groups.json")
	recipe_data = get_json_from_dir("res://assets/json/recipes.json")
	level_data = get_json_from_dir("res://assets/json/levels.json")
	attach_meta(level_data)

func initialize_worldmap():
	var wm = get_json_from_dir("res://assets/json/world.json")
	worldmap = wm[int(G.vars.seed) % wm.size()]
	var flip = int(G.vars.seed) / wm.size() % 3
	if flip == 1:
		for row in worldmap:
			row.invert()
	elif flip == 2:
		worldmap.invert()

func load_cache():
	var cache = get_json_from_dir("res://assets/json/cache.json")
	for key in cache.json:
		json_cache[key] = get_json_from_dir(cache.json[key])
	for key in cache.images:
		images_cache[key] = load("res://assets/images/" + cache.images[key])
	for key in cache.sounds:
		sounds_cache[key] = load("res://assets/audio/" + cache.sounds[key])
		G.sfx.play(key, G.camera.target.pos)
	for fx in cache.effects:
		G.make_particle(fx, G.camera.target.pos)

func get_combo(dat):
	var r = []
	if !dat.empty():
		if G.rng.r_percent(dat[1]):
			r.append(dat[0])
			if dat.size() > 2 and dat[2] == "+":
				r += get_combo(dat[3])
		elif dat.size() > 2 and dat[2] == "/":
			r += get_combo(dat[3])
	return r

func get_category(p):
	var data = G.data.group_data.get(p)
	if data != null:
		for mobs in data:
			if G.rng.r_percent(data[mobs]):
				return mobs

func get_group(p):
	if p[0] == "#":
		var r = []
		var data = G.data.group_data.get(p)
		if data != null:
			for mobs in data:
				var mobs_data = data[mobs]
				if G.rng.r_percent(mobs_data[0]):
					r.append([mobs, G.rng.ir(mobs_data[2], mobs_data[3])])
					if mobs_data[1] == "/":
						return r
		return r
	return p

func get_image(p):
	var r = images_cache.get(p)
	if r != null:
		return r
	else:
		r = load("res://assets/images/" + p + ".png")
		if r == null:
			return get_image("single")
		images_cache[p] = r
		return r

func get_sprite(p):
	var r = Sprite.new()
	r.texture = get_image(p)
	return r

func set_sprite_texture(sprite, p, autotile):
	if autotile > 1:
		var aut = G.data.get_autotile(autotile)
		var path = p + " (" + str(aut) + ")"
		sprite.texture = get_image(path)
	else:
		sprite.texture = get_image(p)
		if autotile == 1:
			sprite.region_enabled = true
			sprite.region_rect.size = G.TILE_VECTOR

func get_autotile(autotile):
	if autotile > 1:
		var t = 0
		for i in range(1, autotile+1):
			t += i
		t = G.rng.ir(1, t)
		for i in range(1, autotile+1):
			t -= i
			if t <= 0:
				return i
	return 1

func set_polygon_texture(polygon, sprite, corpse=false):
	polygon.texture = sprite
	var sz = sprite.get_size()
	if sz.x != G.W or sz.y != G.H:
		polygon.offset.x = -int(sz.x/2)
		polygon.offset.y = -int(sz.y - G.HH)
		var scalex = sz.x / G.W
		var scaley = sz.y / G.H
		var pts = PoolVector2Array()
		if !corpse:
			for pt in UNIT_POLYGON:
				pt.x = int(pt.x * G.HW * scalex)
				pt.y = int(pt.y * G.HH * scaley)
				pts.append(pt)
		else:
			for pt in polygon.get_polygon():
				pt.x = int(pt.x * scalex)
				pt.y = int(pt.y * scaley)
				pts.append(pt)
		polygon.set_polygon(pts)
		polygon.set_uv(pts)

func get_sound(p):
	var r = sounds_cache.get(p)
	if r != null:
		return r
	else:
		r = load("res://assets/audio/" + p + ".wav")
		sounds_cache[p] = r
		return r

func get_particle(p):
	var r = particles_cache.get(p)
	if r != null:
		return r.instance()
	else:
		r = load("res://fx/particles/" + p + ".tscn")
		particles_cache[p] = r
		return r.instance()

func get_json_data(p, _cache=true):
	if _cache:
		var r = json_cache.get(p)
		if r != null:
			return r
		else:
			r = get_json_from_dir("res://assets/json/" + p + ".json")
			json_cache[p] = r
			return r
	else:
		return get_json_from_dir("res://assets/json/" + p + ".json")

func get_json_from_dir(dir):
	if file.open(dir, File.READ) == OK:
		var data_text = file.get_as_text()
		file.close()
		if data_text.empty():
			print("JSON file empty: " + dir)
		else:
			var data_parse = JSON.parse(data_text)
			if data_parse.error == OK:
				return data_parse.result
			else:
				print("Could not parse JSON file " + dir)
	else:
		file.close()
		print("Could not open JSON file " + dir)

func attach_meta(p):
	for i in p:
		p[i].name = i

func save(path, contents):
	var map_save_name = "user://" + path
	if G.data.file.open(map_save_name, File.WRITE) == OK:
		G.data.file.store_string(contents)
		G.data.file.close()
	else:
		push_error("Could not open file [" +path+ "] for saving.")
