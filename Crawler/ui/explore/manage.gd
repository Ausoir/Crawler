extends Control

const MenuIcon = preload("res://ui/MenuIcon.tscn")

var unit

func create():
	$List/Header.set_bbcode("[center][color=#8AA]Evolve[/color][/center]")
	G.rng.set_seed()
	var candidates = G.script("branches", [unit, true])
	update_inventory(candidates)

func update_inventory(cands):
	var section = $List/Scroll/Inventory
	for child in section.get_children():
		child.queue_free()
		section.remove_child(child)
	if cands.empty():
		var label = Label.new()
		label.set_text("You have no runes to evolve with...")
		section.add_child(label)
	else:
		for items in cands:
			var item = items[0]
			var missing = items[1]
			var hbox = HBoxContainer.new()
			var newslot = MenuIcon.instance()
			var itemname = item.get("name")
			var runes = []
			var runenames = []
			for i in G.you.host.inventory:
				var ev = i.get("evolve", [])
				if ev != null:
					for mis in missing:
						if mis in ev:
							var runename = i.get("name")
							if !(runename in runes):
								runenames.append(runename)
								runes.append(i)
			var desc = "Requires [" + "], [".join(runenames) + "]"
			newslot.set_part("inv", null)
			newslot.assign(item)
			newslot.set_description(itemname, G.desc.display_item(G.data.unit_data.get(itemname)) + "\n" + desc)
			newslot.add_button("gui/icon_ok", funcref(self, "evolve"), [itemname, runes])
			hbox.add_child(newslot)
			var label = Label.new()
			label.set_text(" " + itemname.capitalize())
			hbox.add_child(label)
			section.add_child(hbox)

func evolve(evolve_to, runes):
	var old_unit = G.you.host
	var player_unit = G.cmds([["make", evolve_to, G.you.host.pos]])
	player_unit.inventory = old_unit.inventory
	for i in runes:
		player_unit.auto_equip(i, false)
	player_unit.equipments = old_unit.equipments
	var rating = roll_rating()
	set_rating(player_unit, rating)
	player_unit.possess(G.you)
	old_unit.remove()
	get_parent().get_parent().notify("Evolution Complete!", player_unit.dat.get("img", "blank"), rating)

func roll_rating():
	var r = 0
	var rnd = G.rng.ir(0, 1000)
	if rnd == 0:
		r = 3
	elif rnd <= 27:
		r = 2
	elif rnd <= 270:
		r = 1
	return r

func set_rating(u, rating):
	var stats = ["health", "might", "wits"]
	if rating == 1:
		u.dat.a("rating", "rare")
		u.dat.add(G.rng.r_arr(stats), 3)
	elif rating == 2:
		u.dat.a("rating", "great")
		u.dat.add(G.rng.r_arr(stats), 3)
		u.dat.add(G.rng.r_arr(stats), 3)
	elif rating == 3:
		u.dat.a("rating", "legendary")
		u.dat.add(G.rng.r_arr(stats), 3)
		u.dat.add(G.rng.r_arr(stats), 3)
		u.dat.add(G.rng.r_arr(stats), 3)
