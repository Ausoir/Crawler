extends Node2D

const QUADRANT_FLIP = [[1, 0, 1, 0],[0, 1, 1, 0],[1, 0, 0, 1],[0, 1, 0, 1]]
const QUADRANT_ALL = [1, 1, 1, 1]
const OCTANT_FLIP = [[1, 0, 0, 1], [0, 1, 1, 0], [0, -1, 1, 0], [-1, 0, 0, 1], [-1, 0, 0, -1], [0, -1, -1, 0], [0, 1, -1, 0], [1, 0, 0, -1]]
const BLANK = preload("res://assets/images/blank.png")
const SHADES = [Color(0, 0, 0, .6), Color(0, 0, 0, .45), Color(0, 0, 0, .3), Color.transparent]
const MAX_SIGHT = 15

var processing_frame: int = -1
var sight_range = [-1,-1,-1,-1]
var max_sight_x = -1
var sight_range_y = [-1,-1,-1,-1]
var max_sight_y = -1
var max_hearing = -1
var sight_ratio = .85
var sight_frame = 0
var sight_bits = 1
var screen_tiles = []
var target = {"pos": Vector2()}

func start_process():
	if processing_frame != -2:
		for _i in range(3-processing_frame):
			_process(0)
	processing_frame = -1

func _process(_delta):
	if is_instance_valid(target):
		if G.vars.setting.smoothcam:
			var diff = target.global_position - position
			position += diff * _delta * 2
		else:
			position = target.global_position
	if processing_frame == -1:
		target.pos.sight_frame = sight_frame
		for i in range(8):
			cast_sight(target.pos, 1, 1.0, 0.0, OCTANT_FLIP[i], 0)
		processing_frame += 1
	elif processing_frame == 4:
		var diffx = abs(target.prev_pos.x - target.pos.x)
		var diffy = abs(target.prev_pos.y - target.pos.y)
		if diffx > 1 or diffy > 1:
			process_vision(target.pos, QUADRANT_ALL)
		sight_frame += 1
		processing_frame = -2
	elif processing_frame >= 0:
		process_vision(target.prev_pos, QUADRANT_FLIP[processing_frame])
		processing_frame += 1

func darken():
	for y in range(-max_sight_y, max_sight_y+1):
		for x in range(-max_sight_x, max_sight_x+1):
			var xx = target.pos.x+x
			var yy = target.pos.y+y
			var tile = G.world.get_tile(xx, yy)
			if tile:
				G.world.set_dark(tile)

func process_vision(center, quad):
	for y in range(-max_sight_y * quad[0], max_sight_y * quad[1] + 1):
		for x in range(-max_sight_x * quad[2], max_sight_x * quad[3] + 1):
			var xx = center.x+x
			var yy = center.y+y
			var tile = G.world.get_tile(xx, yy)
			if tile:
				if tile.sight_frame == sight_frame:
					G.world.set_light(tile)
				elif tile.sight_frame == sight_frame - 1:
					G.world.set_dark(tile)

func get_visible_distance(light, dist, nvis=false):
	var r = 0
	if light == 1:
		if nvis:
			r = min(MAX_SIGHT, dist)
		else:
			r = int(dist*.5)
	elif light == 2:
		r = int(dist)
	elif light == 3:
		if nvis:
			r = int(dist*.5)
		else:
			r = min(MAX_SIGHT, dist*2)
	else:
		if nvis:
			r = min(MAX_SIGHT, dist*2)
		else:
			r = max(2, r)
	return r

func set_sight(p, p_col=1, nvis=false):
	var is_different = p_col != sight_bits
	var new_max_sight_x = -1
	var new_max_sight_y = -1
	max_hearing = int(p * .6)
	for i in range(4):
		var new_sight_range
		if p_col & 16 > 0:
			new_sight_range = p
		else:
			new_sight_range = get_visible_distance(i, p, nvis)
		if new_sight_range != sight_range[i]:
			is_different = true
			sight_range[i] = new_sight_range
			sight_range_y[i] = round(sight_range[i] * sight_ratio)
			new_max_sight_x = max(new_max_sight_x, sight_range[i])
			new_max_sight_y = max(new_max_sight_y, sight_range_y[i])
	if is_different:
		if new_max_sight_x != -1:
			max_sight_x = new_max_sight_x
			max_sight_y = new_max_sight_y
		darken()
		sight_bits = p_col
		return true

func cast_sight(camera, row, start, end, flips, depth):
	if start < end:
		return
	var new_start
	for cell in range(row, max_sight_x + 1):
		var dx = -cell - 1
		var dy = -cell
		var blocked = false
		while dx <= 0:
			dx += 1
			var start_slope = (dx - 0.5) / (dy + 0.5)
			var end_slope = (dx + 0.5) / (dy - 0.5)
			if start < end_slope:
				continue
			elif end > start_slope:
				break
			else:
				var tile_x = dx * flips[0] + dy * flips[1]
				var tile_y = dx * flips[2] + dy * flips[3]
				if abs(tile_y) < max_sight_y:
					var map_x = camera.x + tile_x
					var map_y = camera.y + tile_y
					var tile = G.world.get_tile(map_x, map_y)
					if tile:
						tile.sight_frame = sight_frame
						if blocked:
							if tile.is_col(sight_bits):
								new_start = end_slope
							else:
								blocked = false
								start = new_start
						else:
							if tile.is_col(sight_bits) and cell < max_sight_x:
								blocked = true
								cast_sight(camera, cell + 1, start, start_slope, flips, depth + 1)
								new_start = end_slope
		if blocked:
			break

func is_pos_in_range(ppos):
	if target != null:
		return abs(ppos.x-target.pos.x) <= max_sight_x and abs(ppos.y-target.pos.y) <= max_sight_y
