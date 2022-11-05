extends Node

const Turn = preload("res://tool/turn.gd")
const Tile = preload("res://world/tile.gd")
var tileset = preload("res://assets/tileset.tres")
var turn = Turn.new()
var size = Vector2(60, 60)
var terrain
var sound
var tiles
var spawn_points = []
var queue_props
var queue_units

onready var tilemap = $Tilemap
onready var shademap = $Shademap
onready var items = $Items
onready var players = $Players
onready var others = $Others
onready var canvas = $Canvas
var map_name: String
var team = [[], [], []]
var onloads = []

func _ready():
	set_process(false)

func create(_type):
	map_name = _type
	var map_save_name = "user://" + _type + ".map"
	create_map(size.x, size.y)
	var generator
	if map_name == "start":
		generator = load("res://world/generator.gd").new()
		generator.generate(size)
	unserialize(generator.terrains, generator.objects)
	for y in range(size.y):
		for x in range(size.x):
			shademap.set_cell(x, y, 2)
			var tile = tiles[y][x]
			tile.set_terrain(generator.terrains[y][x])
			tile.set_visible(false)
	tilemap.update_bitmask_region(Vector2(), size)
	$Borders.position = Vector2(size.x * G.HW, size.y * G.HH)
	$Borders/Left.position = Vector2(size.x * -G.HW - G.W, 0)
	$Borders/Right.position = Vector2(size.x * G.HW + G.W, 0)
	$Borders/Top.position = Vector2(0, size.y * -G.HH - G.H)
	$Borders/Bottom.position = Vector2(0, size.y * G.HH + G.H)

func set_dark(tile):
	if tile.set_visible(false):
		shademap.set_cell(tile.x, tile.y, 1)

func set_light(tile):
	if !tile.visible:
		tile.set_visible(true)
		shademap.set_cell(tile.x, tile.y, -1)

func create_map(sx, sy):
	size = Vector2(sx, sy)
	var r = []
	for y in range(sy):
		var row = []
		for x in range(sx):
			row.append(Tile.new(self, x, y))
		r.append(row)
	tiles = r

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

func serialize(remove=false):
	var terrain_data = ""
	var item_data = []
	for tile in tiles:
		terrain_data += tile.icon
		for i in range(tile.items.size()-1, -1, -1):
			var item = tile.items[i]
			if item.save_to_map:
				var d = item.serialize(remove)
				if d != null:
					item_data.append(d)
			if remove:
				item.remove()
	return [[], terrain_data, item_data]

func unserialize(line_terrains, line_objects):
	for y in range(size.y):
		for x in range(size.x):
			var tile = tiles[y][x]
			tile.set_terrain(line_terrains[y][x])
			tile.visible = false
			if tile.autotile_dir != -1:
				var dirs = 0
				if x > 0 and line_terrains[y][x-1] == tile.icon:
					dirs += 8
				if x < size.x-1 and line_terrains[y][x+1] == tile.icon:
					dirs += 2
				if y > 0 and line_terrains[y-1][x] == tile.icon:
					dirs += 1
				if y < size.y-1 and line_terrains[y+1][x] == tile.icon:
					dirs += 4
				tile.autotile_dir = dirs
				tile.autotile_position = G.AUTOTILE_COORD[dirs]
	queue_props = line_objects
#	set_process(true)

func _process(_d):
	for _i in range(8):
		var loaded = queue_props[0].pop_front()
		if loaded != null:
			var pos = tiles[loaded[0]][loaded[1]]
			G.factory.make_any(loaded[2].name, pos, loaded[2])
		else:
			if queue_units > 0:
				queue_units -= 1
				var tile = G.rng.r_arr(tiles)
				if !tile.is_col(6) and tile.items.empty():
					var combo = G.data.vars.habitat.get(tile.icon)
					if combo != null:
						for item in G.data.get_combo(combo):
							G.factory.make_any(item, tile)
			else:
				set_process(false)
			return
