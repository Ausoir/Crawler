extends "res://entity/unit.gd"

var overlay_sprites = [null,null]
var equipments = []
var weapon
var inventory = [null]
var pockets = 0

func get_damage(ptype, p):
	var r = .get_damage(ptype, p)
	for eq in equipments:
		r += round(G.rng.f() * eq.get("+"+ptype, 0))
	return r

func negate_damage(_type, _dmg, _hitter):
	var dmg = .negate_damage(_type, _dmg, _hitter)
	if dmg > 0:
		for equipment in equipments:
			if _type == "bash":
				dmg -= equipment.get("rbash")
			elif _type == "burn":
				dmg -= equipment.get("rburn")
			elif _type == "cut":
				dmg -= equipment.get("rcut")
			if dmg <= 0:
				G.make_particle("Glance", pos)
				break
	return dmg

func get_part(part):
	for i in equipments:
		if i.get("part", "") == part:
			return i
	return null

func can_equip(itemdat):
	var item_part = itemdat.get("part")
	if itemdat != null and get_part(item_part) == null:
		var part_size = bodyparts.get(item_part, 0)
		if part_size > 0:
			return true
	return false

func equip(itemdat):
	if can_equip(itemdat):
		itemdat.host = self
		equipments.append(itemdat)
		accomodate_stats(itemdat)
		G.sfx.play("equip_metal", pos)
		return true
	return false

func unequip(item):
	for eq in equipments:
		if item == eq:
			unaccomodate_stats(eq)
			item.host = null
			equipments.erase(eq)
			return eq

func store(item, index=-1):
	if item != null:
		add_dirty(0)
		if index >= 0 and index < inventory.size():
			inventory[index] = item
			item.host = self
			return true
		else:
			for i in range(inventory.size()):
				if inventory[i] == null:
					inventory[i] = item
					item.host = self
					return true
	return false

func unstore(item):
	for i in range(inventory.size()):
		if inventory[i] == item:
			item.host = null
			inventory[i] = null
			add_dirty(0)
			return item
	return false

func auto_equip(item, equip=true):
	if equip:
		if !equip(item):
			store(item)
	else:
		var r = unequip(item)
		if r == null:
			return unstore(item)
		return r

func accomodate_stats(itemdat, temp=false):
	var sks = []
	var itemsks = itemdat.get("abilities", [])
	for i in range(itemsks.size()):
		sks.append(itemsks[i])
	sks += dat.get("abilities", [])
	dat.a("abilities", sks)
	pockets += itemdat.get("pockets", 0)
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i].name
		var stat = itemdat.get("+"+s)
		if stat != null:
			dat.add(s, stat)
	if !temp:
		for _i in range(itemdat.get("space", 0)):
			inventory.append(null)
		itemdat.run("onequip")
		add_dirty(2)

func unaccomodate_stats(itemdat, temp=false):
	var tabilities = dat.get("abilities", [])
	var iabilities = itemdat.get("abilities", [])
	for i in iabilities:
		tabilities.erase(i)
	dat.a("abilities", tabilities)
	pockets -= itemdat.get("pockets", 0)
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i].name
		var stat = itemdat.get("+"+s)
		if stat != null:
			dat.add(s, -stat)
	if !temp:
		var remove_spaces = itemdat.get("space", 0)
		var old_inventory = inventory
		inventory = inventory.slice(0, inventory.size()-remove_spaces-1)
		if remove_spaces > 0:
			for i in range(old_inventory.size()):
				if i >= old_inventory.size() - remove_spaces:
					if old_inventory[i] != null:
						if !store(old_inventory[i]):
							old_inventory[i].untake(pos)
		itemdat.run("onunequip")
		add_dirty(2)

func get_enhancers():
	var r = .get_enhancers()
	for i in [weapon] + equipments:
		if i != null:
			var enh = i.get("enhance")
			if enh != null:
				for abil in enh:
					r[abil] = enh[abil]
	return r

func update_light():
	var prev_light = light
	light = dat.get("light", 0)
	for i in equipments + inventory:
		if i != null:
			light += i.get("light", 0)
	if light != prev_light and pos.visible:
		G.you.view_dirty = 3

func get_item_abilities():
	var sks = []
	for i in equipments + inventory:
		if i != null and !i.expired():
			sks += i.get("abilities", [])
	return sks

func get_usable_items():
	var r = []
	var itms = []
	var pcks = pockets
	for i in inventory:
		if pcks > 0:
			itms.append(i)
			pcks -= 1
		else:
			break
	for i in itms + equipments:
		if i != null and !i.expired():
			var onuse = i.get("onuse")
			if onuse != null:
				r.append([i, "item"])
	return r

func serialize(remove=false):
	var save_eq = []
	var save_eqm = []
	for i in equipments:
		save_eq.append(i)
		save_eqm.append(i.m)
		unaccomodate_stats(i, true)
	var data = .serialize(remove)
	if data != null:
		var save_inv = []
		for i in inventory:
			if i != null:
				save_inv.append(i.m)
		data["equip"] = save_eqm
		data["inventory"] = save_inv
	if !remove:
		for i in save_eq:
			accomodate_stats(i, true)
	return data

func unserialize(data):
	.unserialize(data)
	var bodytype_list = G.data.get_json_data("bodytypes")
	bodyparts = bodytype_list.get(dat.get("body", "other")).duplicate()
	for eq in dat.get("equip", []):
		equip(G.factory.unserialize_property(G.data.item_data, eq.name, eq))
	for i in dat.get("inventory", []):
		if i != null:
			store(G.factory.unserialize_property(G.data.item_data, i.name, i))

func add_trait(p, first=false):
	var tdat = .add_trait(p, first)
	if tdat != null:
		var parts = tdat.get("parts", [])
		for part in parts:
			bodyparts[part] -= tdat.size
			var unequips = []
			for eq in equipments:
				if part in eq.get("parts", []):
					unequips.append(eq)
			for i in unequips:
				auto_equip(i, false)

func can_carry(item):
	return item.get("size", 9) <= dat.get("size", 1)

func get_available_items():
	var r = []
	for i in inventory:
		if i != null:
			r.append(i)
	return r + .get_available_items()

func on_change(p):
	.on_change(p)
	if p > 9:
		if p < 100:
			if p - 10 < equipments.size():
				refresh_item(equipments[p-10])
		else:
			refresh_item(inventory[p-100])
		update_light()
	elif p == 2:
		update_light()

func refresh_item(eq):
	if eq != null:
		unaccomodate_stats(eq, true)
		accomodate_stats(eq, true)
		eq.on_change(2)
