extends Control

const MenuIcon = preload("res://ui/MenuIcon.tscn")

var unit

func create():
	$List/Header.set_bbcode("[center][color=#8AA]Evolve[/color][/center]")
	G.rng.set_seed(G.vars.seed)
	var unitname = unit.dat.get("name")
	var candidates = []
	var cl = G.you.host.dat.get("class")
	var evolvable = []
	var rune = []
	for i in G.you.host.inventory:
		var ev = i.get("evolve")
		if ev != null:
			evolvable.append(ev)
			rune.append(i.get("name"))
	for candname in G.data.unit_data:
		var cand = G.data.unit_data[candname]
		var candcl = cand.get("class", [])
		if !candcl.empty():
			var common = similarity(candcl, cl)
			if candname != unitname and common[0] <= 1:
				if candcl.size() == cl.size():
					common[1].append("change")
				elif common[1].empty():
					common[1] = ["pure"]
				var req_met = true
				for i in common[1]:
					if !(i in evolvable):
						req_met = false
				if req_met:
					candidates.append([cand, common[1]])
	update_inventory(candidates)

func similarity(c1, c2):
	var r = 0
	var missing = []
	for i in c1:
		if i in c2:
			r += 1
		else:
			missing.append(i)
	r = max(c1.size(), c2.size()) - r
	return [r, missing]

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
	player_unit.possess(G.you)
	old_unit.remove()
	get_parent().get_parent().notify("Evolution Complete!", player_unit.dat.get("img", "blank"))
