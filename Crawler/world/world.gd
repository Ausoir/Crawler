extends Node

const Turn = preload("res://tool/turn.gd")
const Tile = preload("res://world/tile.gd")
var tileset = preload("res://assets/tileset.tres")
var generator
var turn = Turn.new()
var size
var sound
var tiles
var spawn_points = []
var queue_props

onready var tilemap = $Tilemap
onready var shademap = $Shademap
onready var shadowmap = $Shadowmap
onready var items = $Items
onready var players = $Players
onready var others = $Others
onready var canvas = $Canvas
var team = [[], [], []]
var onloads = []

func _ready():
	set_process(false)
	generator = load("res://world/generator.gd").new()
	var count = 0
	for key in G.data.terrain_data:
		var terrain = G.data.terrain_data[key]
		var aut = terrain.get("autotile", 1)
		for i in range(aut):
			tileset.create_tile(count)
			var path = terrain.img + " (" + str(i+1) + ")"
			tileset.tile_set_name(count, path)
			if aut == 1:
				tileset.tile_set_texture(count, G.data.get_image(terrain.img))
			else:
				tileset.tile_set_texture(count, G.data.get_image(path))
			count += 1

func create(_name):
	G.vars.map = _name
	if !unload(_name):
		if _name == "base":
			generator.generate_base()
		else:
			generator.generate_dungeon(_name)
		unserialize(generator.terrains, generator.objects)
	for y in range(-1, size.y+1):
		for x in range(-1, size.x+1):
			shadowmap.set_cell(x, y, 0)
			if x >= 0 and y >= 0 and x < size.x and y < size.y:
				var tile = tiles[y][x]
				tile.set_visible(false)
				tile.apply_shade()
	tilemap.update_bitmask_region(Vector2(), size)
	$Borders.position = Vector2(size.x * G.HW, size.y * G.HH)
	$Borders/Left.position = Vector2(size.x * -G.HW - G.W, 0)
	$Borders/Right.position = Vector2(size.x * G.HW + G.W, 0)
	$Borders/Top.position = Vector2(0, size.y * -G.HH - G.H)
	$Borders/Bottom.position = Vector2(0, size.y * G.HH + G.H)

func set_dark(tile):
	if tile.visible:
		tile.set_visible(false)
		shadowmap.set_cell(tile.x, tile.y, 1)

func set_light(tile):
	if !tile.visible:
		tile.set_visible(true)
		shadowmap.set_cell(tile.x, tile.y, -1)

func create_map(sx, sy):
	size = Vector2(sx, sy)
	tiles = []
	for y in range(sy):
		var row = []
		for x in range(sx):
			row.append(Tile.new(x, y))
		tiles.append(row)

func remove():
	for row in tiles:
		for cell in row:
			cell.queue_free()

func get_tile(x, y):
	if is_inbound(x, y):
		return tiles[y][x]

func get_tile_clamped(x, y):
	return tiles[clamp(y, 0, size.y-1)][clamp(x, 0, size.x-1)]

func from_vec(v):
	var x = int(v.x / G.W)
	var y = int(v.y / G.H)
	return tiles[y][x]

func set_terrain(x, y, val):
	tiles[y][x].set_terrain(val)

func add_item(x, y, val):
	tiles[y][x].items.append(val)

func is_inbound(x, y):
	return x >= 0 and x < size.x and y >= 0 and y < size.y

func fit_bound(x, y):
	return tiles[clamp(y, 0, size.y-1)][clamp(x, 0, size.x-1)]

func get_spawn_point():
	if !spawn_points.empty():
		return G.rng.r_arr(spawn_points)
	else:
		for _i in range(100):
			var x = G.rng.ir(0, size.x-1)
			var y = G.rng.ir(0, size.y-1)
			if tiles[y][x].col == 0:
				return tiles[y][x]
		push_error("No spawn point found!")

func serialize():
	var terrain_data = []
	var item_data = []
	for y in range(size.y):
		var terrain_row = ""
		for x in range(size.x):
			var tile = tiles[y][x]
			terrain_row += tile.icon
			for i in range(tile.items.size()-1, -1, -1):
				var item = tile.items[i]
				if item.save_to_map:
					var d = item.serialize()
					if d != null:
						item_data.append(d)
		terrain_data.append(terrain_row)
	return [[], terrain_data, item_data]

func unserialize(line_terrains, line_objects):
	if line_terrains[0] is Array:
		size = Vector2(line_terrains[0].size(), line_terrains.size())
	else:
		size = Vector2(line_terrains[0].length(), line_terrains.size())
	create_map(size.x, size.y)
	for y in range(size.y):
		for x in range(size.x):
			var tile = tiles[y][x]
			var terrain = line_terrains[y][x]
			tile.set_terrain(terrain)
	for obj in line_objects:
		var tile = tiles[obj.pos[1]][obj.pos[0]]
		if obj.name == "entrance":
			spawn_points.append(tile)
		G.factory.make_any(obj.name, tile)

func save():
	var r = serialize()
	G.data.save("current.map", JSON.print(r))

func unload(_name):
	var map_data = G.data.get_json_from_dir("user://current.map")
	if map_data != null:
		unserialize(map_data[1], map_data[2])
		return true

func _process(_d):
	for _i in range(8):
		if queue_props > 0:
			queue_props -= 1
			var tile = G.rng.r_arr(tiles)
			if !tile.is_col(6) and tile.items.empty():
				var combo = G.data.vars.habitat.get(tile.icon)
				if combo != null:
					for item in G.data.get_combo(combo):
						G.factory.make_any(item, tile)
		else:
			set_process(false)
		return
