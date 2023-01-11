extends Node2D

const Note = preload("res://entity/Note.tscn")
var item_type = "item"
var item_name
var default_col = 0
var position_speed = 4
var col: int = 0
var zlayer = 0
var team = -999
var dat
var tags = []
var pos
var prev_pos
var light = 0
var dirty = []
var save_to_map = true
var flash_state = [0, 0, 0, 0]

func _ready():
	hide()
	set_process(false)

func get_default_team():
	return 0

func update_z():
	set_z_index(pos.screen_y * 10 + zlayer)

func add_dirty(p):
	G.world.turn.add(self)
	if !(p in dirty):
		dirty.append(p)

func remove():
	if light > 0:
		G.you.view_dirty = light
		G.world.turn.light_sources.erase(self)
	G.healthbars.on_remove(self)
	G.census.remove(self)
	G.world.turn.remove(self)
	dat.on_remove()
	if pos != null: #not an equipment
		pos.remove_item(self)
		if pos.visible:
			if col & 1 == 0 and pos.is_col(1):
				G.you.view_dirty = 1
			elif col & 1 > 0 and !pos.is_col(1):
				G.you.view_dirty = max(1, pos.light - G.time.ambient_light)
	queue_free()

func die():
	G.Mat.on_die(self)
	dat.run("ondie")
	remove()

func take():
	var r = dat
	remove()
	return r

func negate_damage(_type, _dmg, _hitter):
	var r
	if _type == "burn":
		if "armored" in tags:
			_dmg *= 1.5
		if "agile" in tags:
			_dmg *= .5
		r = _dmg - dat.get("resist", 0)
	elif _type == "cut":
		if "brute" in tags:
			_dmg *= 1.5
		if "armored" in tags:
			_dmg *= .5
		r = _dmg - dat.get("armor", 0)
	elif _type == "bash":
		if "agile" in tags:
			_dmg *= 1.5
		if "brute" in tags:
			_dmg *= .5
		r = _dmg
	else:
		r = _dmg
	return int(r)

func hit(_type, dmg, _hitter):
	if dat.get("mat", "other") == "other":
		return 0
	if dmg < 0:
		return heal(-dmg)
	dmg = negate_damage(_type, dmg, _hitter)
	if dmg > 0:
		on_damage(dmg, _hitter)
	return dmg

func on_damage(dmg, _hitter):
	G.Mat.make_hit_sound(self)
	dat.add("damage", dmg, 0)
	if pos.visible:
		G.Mat.make_hit_effect(self)
		G.healthbars.show_healthbar(dat, self)
		G.display_damage(round(dmg), pos, Color.red)
		flash(0, dmg * .2)
	on_health_change()

func heal(dmg):
	dat.add("damage", -dmg, 0)
	if pos != null:
		if pos.visible:
			G.healthbars.show_healthbar(dat, self)
			G.display_damage(round(dmg), pos, Color.green)
			G.make_particle("Heal", pos)
			flash(1, dmg * -.2)
	return dmg

func on_health_change():
	if dat.get_health() <= 0:
		add_dirty(-1)

func relocate(to, force=false):
	if force:
		if pos == null:
			pos = to
		position.x = to.position.x
		position.y = to.position.y
		set_process(true)
	elif pos != to:
		set_process(true)
	else:
		return
	pos.remove_item(self)
	prev_pos = pos
	to.add_item(self)
	if to.visible:
		if col & 1 == 0 and to.is_col(1):
			G.you.view_dirty = 1
		elif col & 1 > 0 and !to.is_col(1):
			G.you.view_dirty = 1

func textify(p):
	if has_node("Viewport"):
		$Viewport/Label.set_text(p)
	else:
		var note = Note.instance()
		add_child(note)
		var t = self
		t.set_texture(note.get_texture())
		$Viewport/Label.set_text(p)
		t.set_centered(true)

func on_turn():
	for dirt in dirty:
		if dirt == -1:
			die()
			return
		on_change(dirt)
	dirty.clear()
	G.world.turn.remove(self)

func on_change(p):
	if p == 2:
		var sd = dat.get("seed")
		if sd != null and sd == -1:
			dat.a("seed", randi())
		item_name = dat.get("name")
		var newteam = dat.get("team", get_default_team())
		if team != newteam:
			team = newteam
			G.census.adjust_team(self)
		tags = dat.get("tags", [])
		var img = dat.get("img")
		if img != null:
			set_texture_from_path(img)
		zlayer = dat.geti("zlayer", 0)
		if dat.get("size", 0) > 1:
			zlayer -= 1
		var nlight = dat.geti("light", 0)
		if nlight != light:
			light = nlight
			if pos.visible:
				G.you.view_dirty = abs(nlight-light)
		if nlight > G.time.ambient_light:
			G.world.turn.add_light(self)
		on_col_change()
	elif p == 1:
		on_change(2)
	dat.on_change(p)

func on_col_change():
	var ncol = dat.get("col", 0)
	if ncol != col:
		col = ncol
		pos.update_tile()
		if pos.visible:
			var t = pos.light - G.time.ambient_light
			G.you.view_dirty = max(G.you.view_dirty, t)

func _process(delta):
	var diff = pos.position - position
	position += diff * delta * position_speed
	if flash_state[0] > 0:
		var percent = flash_state[0] / flash_state[1]
		if flash_state[2] > 0:
			modulate.r = 1
			modulate.g = 1-flash_state[2]*percent
			modulate.b = modulate.g
		elif flash_state[3] > 0:
			modulate.r = 1-flash_state[3]*percent
			modulate.g = 1
			modulate.b = modulate.r
		flash_state[0] -= delta
		if flash_state[0] <= 0:
			modulate = Color.white
	elif diff.length_squared() < 8:
		set_process(false)

func flash(c, dur):
	dur = max(.1, dur)
	flash_state = [dur, dur, 0, 0]
	flash_state[2 + c] = 1
	set_process(true)

func serialize(_remove=false):
	dat.m["pos"] = [pos.x, pos.y]
	return dat.m.duplicate()

func unserialize(p):
	if p != null:
		dat.combine(p)

func on_sleep(_time):
	pass

func set_texture_from_path(path):
	if path != null:
		G.data.set_sprite_texture(self, path, dat.get("autotile", 0))
		if self.texture != null:
			if !self.region_enabled:
				var img_size = self.texture.get_size()
				if img_size.y > G.H:
					self.offset.y = -int((img_size.y - G.H) / 2)

func cast_light(mag, row, start, end, flips):
	if start < end:
		return
	var new_start
	for cell in range(row, mag + 1):
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
				var map_x = pos.get_x() + tile_x
				var map_y = pos.get_y() + tile_y
				if G.world.is_inbound(map_x, map_y):
					var tile = G.world.get_tile(map_x, map_y)
					if tile:
						tile.set_light(mag - max(abs(tile_x), abs(tile_y)))
						if blocked:
							if tile.is_col(1):
								new_start = end_slope
							else:
								blocked = false
								start = new_start
						else:
							if tile.is_col(1) and cell < mag:
								blocked = true
								cast_light(mag, cell + 1, start, start_slope, flips)
								new_start = end_slope
		if blocked:
			break
