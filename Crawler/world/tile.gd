const SHADE_MAP = [-1, 1, 2, 1, 3, 6, 3, 6, 4, 9, 14, 9, 3, 6, 3, 6, 5,
				   8, 10, 8, 7, 11, 7, 11, 5, 8, 10, 8, 7, 11, 7, 11, 11]
var item_name
var item_type = "tile"
var visible = false
var x
var y
var dat
var icon = '?'
var items = []
var img
var height = 0
var light = 0
var col: int
var slow = 1
var sight_frame = -1
var screen_y = 0
var position

func _init(px, py):
	x = px
	y = py
	position = Vector2(x*G.W + G.HW, y*G.H + G.HH)

func to_vector():
	return Vector2(x, y)

func to_array():
	return [x, y]

func to_string():
	return str(x) + "," + str(y)

func set_visible(p):
	if visible != p:
		if p:
			for item in items:
				item.show()
		else:
			for item in items:
				item.hide()
		visible = p
		return true
	return false

func set_terrain(val):
	var data = G.data.terrain_data.get(val)
	if data == null:
		data = G.data.terrain_data.get(" ")
		print("Could not find terrain data " + val)
	dat = data
	item_name = data.name
	img = data.img
	slow = data.get("slow", 0)
	height = data.get("height", 0)
	light = 0
	dat.col = int(dat.get("col", 0))
	col = dat.col
	icon = val
	var aut = G.data.get_autotile(dat.get("autotile", 0))
	var path = data.img + " (" + str(aut) + ")"
	var tid = G.world.tileset.find_tile_by_name(path)
	G.world.tilemap.set_cell(x, y, tid)

func add_item(item):
	if item.get_parent() == null:
		G.world.items.add_child(item)
	items.append(item)
	item.pos = self
	update_tile()
	if visible:
		item.show()
	else:
		item.hide()
	if items.size() >= 2:
		for i in range(items.size()-1):
			items[i].dat.run("onstep")

func remove_item(item):
	var idx = items.find(item)
	if idx != -1:
		items.remove(idx)
		var parent = item.get_parent()
		if parent != null:
			parent.remove_child(item)
		update_tile()
		if items.size() >= 1:
			for i in range(items.size()):
				items[i].dat.run("onunstep")

func update_tile():
	col = dat.col
	slow = dat.get("slow", 0)
	for item in items:
		slow += item.dat.get("slow", 0)
		col = col | item.col

func is_col(bit):
	return col & bit > 0

func is_col_adv(cols, dmg):
	if items.empty() or dmg <= 0:
		return is_col(cols)
	var tcol = dat.col
	for item in items:
		tcol = item.col | tcol
	return tcol & cols > 0

func get_adjacent(dir, val=1):
	if dir == -1:
		return self
	var t = G.DIRS[dir]
	return get_neighbor(t.x, t.y, val)

func get_neighbor(px, py, val=1):
	var rx = x + px*val
	var ry = y + py*val
	if G.world.is_inbound(rx, ry):
		return G.world.get_tile(rx, ry)
	return self

func get_cardinals(p):
	var r = []
	var xmin = max(0, x-p)
	var xmax = min(G.world.size.x-1, x+p)
	var ymin = max(0, y-p)
	var ymax = min(G.world.size.y-1, y+p)
	for iy in range(ymin, ymax+1):
		if iy != y:
			r.append(G.world.get_tile(x, iy))
	for ix in range(xmin, xmax+1):
		if ix != x:
			r.append(G.world.get_tile(ix, y))
	return r

func get_area(p):
	var r = []
	var xmin = max(0, x-p)
	var xmax = min(G.world.size-1, x+p)
	var ymin = max(0, y-p)
	var ymax = min(G.world.size-1, y+p)
	for iy in range(ymin, ymax+1):
		for ix in range(xmin, xmax+1):
			r.append(G.world.get_tile(ix, iy))
	return r

func distance_to(tile):
	var v = to_vector()
	var tv = tile.to_vector()
	return max(abs(v.x - tv.x), abs(v.y - tv.y))

func difference_to(tile):
	var v = to_vector()
	var tv = tile.to_vector()
	return abs(v.x - tv.x) + abs(v.y - tv.y)

func get_available_adjacents(cols):
	var r = []
	for i in range(8):
		var adj = get_adjacent(i)
		if !adj.is_col(cols):
			r.append(adj)
	return r

func get_rand_offset(_x, _y):
	var rx = G.rng.ir(-_x, _x)
	var ry = G.rng.ir(-_y, _y)
	return G.world.get_tile(x + rx, y + ry)

func get_beam_to(dest, col_mask, distance=-1):
	var diffx = dest.x - x
	var diffy = dest.y - y
	var step = max(abs(diffx), abs(diffy))
	var current = self
	var prev = self
	while current != dest and distance != 0:
		distance -= 1
		var tx = round(current.x + (diffx/step))
		var ty = round(current.y + (diffy/step))
		if G.world.is_inbound(tx, ty):
			current = G.world.get_tile(tx, ty)
			if current.is_col(col_mask):
				break
		else:
			break
		prev = current
	return [prev, current]

func get_routes(cols, strength=0):
	var r = []
	for i in range(0, 8, 2):
		var tile = get_adjacent(i)
		if tile != self:
			if !tile.is_col(cols):
				r.append([G.DIRS[i], tile.slow])
			elif !tile.is_col_adv(cols, strength):
				r.append([G.DIRS[i], 4])
	return r

func direction_to(to):
	var tx = to.x - x
	var ty = to.y - y
	return G.diff_to_dir(tx, ty)

func set_light(p):
	light = max(p, light)

func apply_shade():
	var dirs = 0
	for i in range(6, 11):
		var offset = G.DIRS[i % 8]
		var xx = x+offset[0]
		var yy = y+offset[1]
		if G.world.is_inbound(xx, yy):
			var adj = G.world.get_tile(xx, yy)
			if adj.height > height:
				dirs += 1 << (i-6)
	G.world.shademap.set_cell(x, y, SHADE_MAP[dirs])

func get_items_by_type(p):
	var r = []
	for i in items:
		if i.item_type == p:
			r.append(i)
	return r
