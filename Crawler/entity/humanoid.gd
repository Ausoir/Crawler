extends "res://entity/unit.gd"

var overlay_sprites = [null,null]
var equipments = []
var weapon
var inventory = [null]
var pockets = 0
var bodyparts

func _init():
	bodyparts = G.data.get_json_data("bodytypes").man
	for _i in range(bodyparts.keys().size()):
		overlay_sprites.append(null)

func set_seed(sd=-1):
	sd = .set_seed(sd)
	if dat.get("img") == null:
		var skins = G.data.vars.looks.skin
		var hairs = G.data.vars.looks.hair
		var lookseed = sd % (skins.size() * hairs.size())
		var sprite_name = skins[lookseed % skins.size()]
		var hair_name = hairs[int(lookseed / skins.size())]
		if sd % 2 == 0:
			sprite_name += "_m"
		else:
			sprite_name += "_f"
			dat.a("gender", "f")
		n_sprite.texture = G.data.get_image("units/human/"+sprite_name)
		create_overlay(0, {"img": "units/human/"+hair_name+"_m", "gender": true}, 1)

func die():
	if weapon != null:
		weapon.untake(pos)
	.die()

func remove():
	for i in overlay_sprites:
		if i != null:
			i.queue_free()
	.remove()

func get_damage(ptype, p):
	var r = .get_damage(ptype, p)
	if weapon != null and weapon.get_health() > 0:
		if ptype == "bash":
			r += round(G.rng.f() * weapon.get("bash", 0))
		elif ptype == "cut":
			r += round(G.rng.f() * weapon.get("cut", 0))
	return r

func on_attack(dmg):
	if weapon != null:
		weapon.run("onattack")
		weapon.add("damage", max(0, dmg-G.Mat.get_armor_of(weapon)))
		if weapon.get_health() <= 0:
			unwield()
	.on_attack(dmg)

func negate_damage(_type, _dmg, _hitter):
	var dmg = .negate_damage(_type, _dmg, _hitter)
	if dmg > 0:
		var count = 0
		for part in bodyparts:
			if G.rng.b():
				for equipment in equipments:
					if part in equipment.get("parts", []):
						var cov = equipment.get("size", 0)
						if G.rng.r_percent(cov):
							if equipment.get_health() > 0:
								if _type == "bash":
									dmg -= int(G.Mat.get_armor_of(equipment) / 2)
								elif _type == "burn":
									dmg -= G.Mat.get_resistance_of(equipment)
								elif _type == "cut":
									dmg -= G.Mat.get_armor_of(equipment)
								if dmg <= 0:
									G.make_particle("Glance", pos)
								else:
									equipment.add("damage", dmg)
							else:
								unequip(equipment)
							break
				if count > 2:
					break
				count += 1
	return dmg

func remove_overlay(idx):
	var sprite = overlay_sprites[idx]
	if sprite != null:
		sprite.queue_free()
		n_sprites.remove_child(sprite)
		overlay_sprites[idx] = null

func create_overlay(idx, itemdat, z):
	remove_overlay(idx)
	var texture = itemdat.get("img")
	if itemdat.get("gender", false) and dat.get("gender", "m") == "f":
		texture = texture.substr(0, texture.length()-1) + "f"
	var newsprite = n_sprite.duplicate()
	newsprite.set_texture(G.data.get_image(texture))
	overlay_sprites[idx] = newsprite
	n_sprites.add_child(overlay_sprites[idx])
	newsprite.z_index = z

func has_parts(parts):
	var r = false
	for i in equipments:
		for part in parts:
			r = r or part in i.get("parts", [])
	return r

func can_equip(itemdat):
	var item_parts = itemdat.get("parts", [])
	if itemdat != null and !has_parts(item_parts):
		for part in item_parts:
			var part_size = bodyparts.get(part, 0)
			if itemdat.get("size", 1) > part_size:
				return false
		return true
	return false

func auto_equip(item, equip=true):
	if equip:
		if !equip(item):
			if !wield(item):
				store(item)
	else:
		if weapon == item:
			return unwield()
		else:
			var r = unequip(item)
			if r == null:
				return unstore(item)
			return r

func wield(itemdat):
	if itemdat == null:
		unwield()
	elif weapon == null and bodyparts.get("weapon", 0) >= itemdat.get("size", -1):
		weapon = itemdat
		weapon.host = self
		accomodate_stats(itemdat)
		create_overlay(1, itemdat, 4)
		G.sfx.play("equip_metal", pos)
		return true
	return false

func unwield():
	if weapon != null:
		unaccomodate_stats(weapon)
		remove_overlay(1)
		weapon.host = null
		var r = weapon
		weapon = null
		return r

func equip(itemdat):
	if itemdat != null and can_equip(itemdat):
		var item_parts = itemdat.get("parts", [])
		itemdat.host = self
		equipments.append(itemdat)
		accomodate_stats(itemdat)
		var z = 1
		if "outer" in item_parts:
			z = 3
		elif "arms" in item_parts:
			z = 2
		elif "head" in item_parts:
			z = 2
		elif "back" in item_parts:
			z = 3
		if !item_parts.empty():
			var idx = bodyparts.keys().find(item_parts[0])
			create_overlay(idx+1, itemdat, z)
		G.sfx.play("equip_metal", pos)
		return true
	return false

func unequip(item):
	for eq in equipments:
		if item == eq:
			var item_parts = eq.get("parts", [])
			if !item_parts.empty():
				var idx = bodyparts.keys().find(item_parts[0])
				remove_overlay(idx+1)
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

func get_total_weight():
	var r = 0
	for i in [weapon] + equipments + inventory:
		if i != null:
			r += G.Mat.get_weight_of(i)
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

func update_weight():
	var tw = get_total_weight()
	var sta = dat.get("stamina", 0) * .5
	if tw >= sta:
		action.move_delay = int(tw / max(1, sta)) - dat.get("agility", 0)

func update_light():
	var prev_light = light
	light = dat.get("light", 0)
	for i in [weapon] + equipments + inventory:
		if i != null:
			light += i.get("light", 0)
	if light != prev_light and pos.visible:
		G.you.view_dirty = 3

func get_item_abilities():
	var sks = []
	for i in [weapon] + equipments + inventory:
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
	for i in itms + [weapon] + equipments:
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
	if weapon != null:
		unaccomodate_stats(weapon, true)
	var data = .serialize(remove)
	if data != null:
		var save_inv = []
		for i in inventory:
			if i != null:
				save_inv.append(i.m)
		if weapon != null:
			data["weapon"] = weapon.m
		else:
			data["weapon"] = null
		data["equip"] = save_eqm
		data["inventory"] = save_inv
	if !remove:
		for i in save_eq:
			accomodate_stats(i, true)
		if weapon != null:
			accomodate_stats(weapon, true)
	return data

func unserialize(data):
	.unserialize(data)
	var bodytype_list = G.data.get_json_data("bodytypes")
	bodyparts = bodytype_list.get(dat.get("body", "other")).duplicate()
	var wield = dat.get("weapon")
	if wield != null:
		wield(G.factory.unserialize_property(G.data.item_data, wield.name, wield))
	for eq in dat.get("equip", []):
		equip(G.factory.unserialize_property(G.data.item_data, eq.name, eq))
	for i in dat.get("inventory", []):
		if i != null:
			store(G.factory.unserialize_property(G.data.item_data, i.name, i))

func add_trait(p, first=false):
	var tdat = .add_trait(p, first)
	if tdat != null:
		var sprite = tdat.get("img")
		if sprite != null:
			overlay_sprites.append(null)
			var dict = {"img": "overlay/mutation/"+sprite, "gender": tdat.get("gender", false)}
			create_overlay(overlay_sprites.size()-1, dict, tdat.z)
		var parts = tdat.get("parts", [])
		for part in parts:
			bodyparts[part] -= tdat.size
			var unequips = []
			for eq in equipments:
				if part in eq.get("parts", []):
					unequips.append(eq)
			for i in unequips:
				auto_equip(i, false)

func remove_trait(p):
	var idx = traits.find(p)
	remove_overlay(9+idx)
	traits.remove(idx)

func can_carry(item):
	return item.get("size", 9) <= dat.get("size", 1)

func get_available_items():
	var r = []
	for i in [weapon] + inventory:
		if i != null:
			r.append(i)
	return r + .get_available_items()

func on_change(p):
	.on_change(p)
	if p > 9:
		if p == 10:
			refresh_item(weapon, 1)
		elif p < 100:
			if p - 11 < equipments.size():
				var eq = equipments[p-11]
				var item_parts = eq.get("parts", [])
				if !item_parts.empty():
					var idx = bodyparts.keys().find(item_parts[0])
					refresh_item(eq, idx + 1) #Account for weapon
				else:
					refresh_item(eq)
		else:
			refresh_item(inventory[p-100])
		update_weight()
		update_light()
	elif p == 2:
		update_weight()
		update_light()

func refresh_item(eq, idx=-1):
	if eq != null:
		if idx != -1:
			var sprite = eq.get("img")
			if sprite != null:
				overlay_sprites[idx].set_texture(G.data.get_image(sprite))
			else:
				remove_overlay(idx)
		unaccomodate_stats(eq, true)
		accomodate_stats(eq, true)
		eq.on_change(2)
