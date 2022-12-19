extends "res://entity/unit.gd"

var inventory = []
var equipments = {}

func get_damage(ptype, p):
	var r = .get_damage(ptype, p)
	for eq in get_equipments():
		r += round(G.rng.f() * eq.get("+"+ptype, 0))
	return r

func negate_damage(_type, _dmg, _hitter):
	var dmg = .negate_damage(_type, _dmg, _hitter)
	if dmg > 0:
		for eq in get_equipments():
			if _type == "bash":
				dmg -= eq.get("rbash")
			elif _type == "burn":
				dmg -= eq.get("rburn")
			elif _type == "cut":
				dmg -= eq.get("rcut")
			if dmg <= 0:
				G.make_particle("Glance", pos)
				break
	return dmg

func get_equipments():
	var r = []
	for k in equipments:
		var eq = equipments[k]
		if eq != null:
			r.append(eq)
	return r

func can_equip(_itemdat):
	var part = _itemdat.get("part", "")
	return part in equipments and equipments[part] == null

func equip(itemdat):
	if can_equip(itemdat):
		itemdat.host = self
		equipments[itemdat.get("part")] = itemdat
		accomodate_stats(itemdat)
		G.sfx.play("equip_metal", pos)
		return true
	return false

func unequip(item):
	var part = item.get("part", "")
	var eq = equipments.get(part)
	if eq != null:
		unaccomodate_stats(eq)
		item.host = null
		equipments[part] = null
		return eq

func store(item):
	if item != null:
		add_dirty(0)
		inventory.append(item)
		item.host = self
		return true
	return false

func unstore(item):
	item.host = null
	add_dirty(0)
	inventory.erase(item)

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
	for s in G.data.vars.stats:
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
	for s in G.data.vars.stats:
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
	for eq in get_equipments():
		var enh = eq.get("enhance")
		if enh != null:
			for abil in enh:
				r[abil] = enh[abil]
	return r

func update_light():
	var prev_light = light
	light = dat.get("light", 0)
	for i in get_equipments() + inventory:
		light += i.get("light", 0)
	if light != prev_light and pos.visible:
		G.you.view_dirty = 3

func get_item_abilities():
	var sks = []
	for i in get_equipments() + inventory:
		sks += i.get("abilities", [])
	return sks

func get_usable_items():
	var r = []
	for i in get_equipments():
		var onuse = i.get("onuse")
		if onuse != null:
			r.append([i, "item"])
	return r

func serialize(remove=false):
	var save_eq = []
	var save_eqm = []
	for i in get_equipments():
		save_eq.append(i)
		save_eqm.append(i.m)
		unaccomodate_stats(i, true)
	var data = .serialize(remove)
	if data != null:
		var save_inv = []
		for i in inventory:
			save_inv.append(i.m)
		data["*equips"] = save_eqm
		data["*items"] = save_inv
	if !remove:
		for i in save_eq:
			accomodate_stats(i, true)
	return data

func unserialize(data):
	.unserialize(data)
	var equips = dat.get("equips", ["amulet", "ring"])
	for equip in equips:
		equipments[equip] = null
	for eq in dat.get("*equips", []):
		equip(G.factory.unserialize_property(G.data.item_data, eq.name, eq))
	for i in dat.get("*items", []):
		if i != null:
			store(G.factory.unserialize_property(G.data.item_data, i.name, i))

func get_available_items():
	var r = []
	for i in inventory:
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
