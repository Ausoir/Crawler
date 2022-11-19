const Item = preload("res://entity/item.gd")
const Unit = preload("res://entity/Unit.tscn")
const Script_Unit = preload("res://entity/unit.gd")
const Script_UnitAdv = preload("res://entity/unitadv.gd")
const Properties = preload("res://entity/properties.gd")
const Script_Projectile = preload("res://entity/projectile.gd")

func unserialize_property(json, name, mdata=null):
	var data = json.get(name)
	if data != null:
		var properties = Properties.new(data)
		if mdata != null:
			properties.combine(mdata)
		return properties

func make_any(name, pos=null, mdata=null):
	if name[0] == "#":
		return make_group(name, pos)
	var r = make_item(name, pos, mdata)
	if r == null:
		r = make_unit(name, pos, mdata)
	return r

func make_unit(name, pos, mdata=null):
	var json = G.data.unit_data.get(name)
	if json != null:
		var r = Unit.instance()
		r.set_script(Script_UnitAdv)
		r.item_type = "unit"
		r.col = -1
		r.dat = Properties.new(json, r)
		if pos != null:
			r.relocate(pos, true)
		G.world.turn.add(r)
		r.dirty = [1]
		r.unserialize(mdata)
		return r

func make_item(name, pos, mdata=null):
	var json = G.data.item_data.get(name)
	if json != null:
		var r = Sprite.new()
		r.set_script(Item)
		r.dat = Properties.new(json, r)
		if pos != null:
			r.relocate(pos, true)
		r.unserialize(mdata)
		G.world.turn.add(r)
		r.dirty = [1]
		return r

func make_group(arg, pos):
	var groups = G.data.get_group(arg)
	if !groups.empty():
		var made
		var adjs
		var adj = pos
		for group in groups:
			for _i in range(group[1]):
				if adj != null:
					made = make_any(group[0], adj)
					if made != null and made.col & 4 > 0:
						adjs = adj.get_available_adjacents(12, true)
						adj = G.rng.r_arr(adjs)
		return made

func make_projectile(host, from, dest, item_data):
	if from.visible or dest.visible:
		var r = Sprite.new()
		r.set_script(Script_Projectile)
		var img = G.data.get_image(item_data.get("img"))
		r.init(host, img, from, dest)
		r.variance_from = item_data.get("from_rng", r.variance_from)
		r.variance_to = item_data.get("to_rng", r.variance_to)
		r.onattack = item_data.get("onattack")
		r.onmiss = item_data.get("onmiss")
		var onshoot = item_data.get("onshoot")
		if onshoot != null:
			G.cmds(onshoot, host, dest)
		return r

func make_corpse(host, pos, mdata=null):
	var r = G.data.get_particle("Corpse")
	r.make(host)
	var item_data = G.data.item_data.get("corpse")
	if item_data != null:
		r.dat = Properties.new(item_data, r)
	if pos != null:
		r.relocate(pos, true)
	r.unserialize(mdata)
	return r
