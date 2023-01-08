extends "res://entity/item.gd"

const Pilot = preload("res://entity/pilot.gd")
const Buffs = preload("res://entity/buffs.gd")
const Action = preload("res://entity/action.gd")

onready var n_animation = $Animation
onready var n_sprite = $Sprite

var delay = 0
var direction

var col_mask
var abilities = []
var pilot
var action = Action.new(self)
var buffs = Buffs.new(self)
var next_action
var last_hitter

func get_default_team():
	return -1

func on_attack(_dmg):
	if "vampire" in tags:
		heal(int(_dmg * G.rng.f()))

func possess(ctlr = null):
	if ctlr == null:
		ctlr = Pilot.new()
		ctlr.host = self
		ctlr.set_ai(dat.get("ai", []))
	else:
		ctlr.unassign()
		ctlr.host = self
	if pilot != null:
		pilot.remove()
		pilot = null
	pilot = ctlr
	ctlr.on_assign()

func get_damage(_ptype, p):
	return int(p * (1 + dat.get("might", 0)*.2))

func on_kill(killed):
	if "bloodlust" in tags:
		hit("true", -1, self)
	pilot.on_kill(killed)

func negate_damage(type, dmg, _hitter):
	if pilot != null:
		pilot.on_hit(_hitter)
	if _hitter != null:
		var used = action.roll_ability("onhit", _hitter.pos, 3)
		var abblock = 0
		if used != null:
			abblock = used.get("block", 0)
			dmg -= abblock
			if dmg <= 0:
				G.display_damage(used.get("block quote"), pos, Color.darkgray)
				return dmg
		if dmg > 0:
			var thorn = dat.get("thorns", 0)
			if thorn > 0 and _hitter.pos.distance_to(pos) <= 1:
				_hitter.on_damage(thorn, self)
	return .negate_damage(type, dmg, _hitter)

func on_damage(dmg, _hitter):
	buffs.disrupt_hit = true
	if !("numb" in tags) and !buffs.has("pain"):
		G.fx.do(G.data.ability_data.get("pain"), self)
	.on_damage(dmg, _hitter)
	if _hitter != null:
		last_hitter = _hitter

func on_health_change():
	var health_percent = dat.get_health()
	if health_percent <= 0:
		add_dirty(-1)
	elif health_percent <= .5:
		if !buffs.has("injury"):
			G.fx.do(G.data.ability_data.get("injury"), self)
			if "adrenaline" in tags:
				G.fx.do(G.data.ability_data.get("adrenaline"), self)

func add_dirty(p):
	if !(p in dirty):
		dirty.append(p)

func on_turn():
	for dirt in dirty:
		if dirt == -1:
			die()
			return
		on_change(dirt)
	dirty.clear()
	pilot.on_turn()
	action.on_turn()

func set_texture_from_path(path):
	if path != null:
		G.data.set_sprite_texture(n_sprite, path, 0)
		if n_sprite.texture != null:
			var img_size = n_sprite.texture.get_size()
			if img_size.y > G.H:
				n_sprite.offset.y = -int((img_size.y - G.H) / 2)

func on_change(p):
	.on_change(p)
	if p == 2:
		action.move_delay = -dat.get("speed", 0)
		dat.a("durability", (dat.get("health", 1) + 1) * 3)
		for i in dat.get("*traits", []):
			add_trait(i)
		dat.a("*traits", [])
		abilities.clear()
		var enhance = get_enhancers()
		for ability in dat.get("abilities", []):
			var data = G.data.ability_data.get(ability)
			if data != null:
				if !(data in abilities) or data.get("trigger", 0) == 0:
					var enh = enhance.get(ability)
					if enh != null:
						data = data.duplicate()
						for key in enh:
							data[key] = enh[key]
					abilities.append(data)
		if pilot == null:
			possess()
		else:
			var ai = dat.get("ai")
			if ai != null:
				pilot.set_ai(ai)
	if pilot != null:
		pilot.on_change(p)

func on_col_change():
	col = dat.geti("col", 14)
	col_mask = dat.geti("mask", 12)
	if pos != null:
		pos.update_tile()

func face(dir):
	direction = dir
	var horizontal = 0
	if dir == G.LEFT:
		horizontal = 1
	elif dir == G.RIGHT:
		horizontal = -1
	if horizontal != 0:
		if (horizontal > 0) != (scale.x > 0):
			scale.x *= -1

func face_toward(p):
	if p != null:
		var diffx = (p.x-pos.x)
		if diffx > 0:
			face(G.RIGHT)
		elif diffx < 0:
			face(G.LEFT)

func die():
	G.factory.make_corpse(self, pos, dat.get("corpse"))
	pilot.on_die()
	.die()

func remove():
	if pilot != null:
		pilot.remove()
	G.census.remove(self)
	$Shadow.queue_free()
	for child in get_children():
		child.queue_free()
	.remove()
	buffs.remove()

func relocate(p, force=false):
	.relocate(p, force)
	if pos.visible:
		update_z()

func serialize(remove=false):
	var r = .serialize(remove)
	r["buffs"] = buffs.serialize()
	r["cds"] = action.cooldowns
	return r

func unserialize(data):
	.unserialize(data)
	if dat.get("mat") == null:
		dat.m["mat"] = "flesh"
	if dat.get("shadow", true) == false:
		$Shadow.hide()
	var buff_data = dat.get("buffs")
	if buff_data != null:
		buffs.unserialize(buff_data)
	var cds = dat.get("cds")
	if cds != null:
		action.cooldowns = cds

func add_trait(p):
	if !(p in tags):
		tags.append(p)
		var tdat = G.data.trait_data.get(p)
		if tdat != null:
			var cmd = tdat.get("cmd")
			if cmd != null:
				G.cmds(cmd, self, tdat)

func get_enhancers():
	return dat.get("enhance", {})

func get_available_items():
	var r = []
	for item in pos.items:
		r.append(item.dat)
	return r

func get_available_items_by_name(p):
	var r = []
	var items = get_available_items()
	for item in items:
		if item.get("name") == p:
			r.append(item)
	return r

func get_available_tags(tag, val):
	var r = []
	var items = get_available_items()
	for item in items:
		if item.get(tag) == val:
			r.append(item)
	return r

func require_tags(tag, val, amount):
	var items = get_available_tags(tag, val)
	if amount > 0:
		for item in items:
			var r = item.get("uses", 0)
			var leftover = r - amount
			amount -= r
			item.m["uses"] = max(0, leftover)
			if amount <= 0:
				return true
	elif !items.empty():
		return true
	return false
