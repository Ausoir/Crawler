extends Control

const MenuIcon = preload("res://ui/MenuIcon.tscn")

var unit

func refresh_page():
	var uname = unit.dat.get("name", "???").capitalize()
	$VBox/Label_Cha.set_bbcode("[center][color=#B79]" + uname + "[/color][/center]")
	update_stats()
	update_traits()
	update_abilities()
	update_inventory()

func update_stats():
	var tab_character = $VBox/HBox_Cha
	tab_character.get_node("Health/Label").set_text(str(unit.dat.get("health", 1)))
	tab_character.get_node("Health").desc = ["health", G.data.vars.desc.get("health", "")]
	tab_character.get_node("Might/Label").set_text(str(unit.dat.get("might", 1)))
	tab_character.get_node("Might").desc = ["might", G.data.vars.desc.get("might", "")]
	tab_character.get_node("Wits/Label").set_text(str(unit.dat.get("wits", 1)))
	tab_character.get_node("Wits").desc = ["wits", G.data.vars.desc.get("wits", "")]

func update_traits():
	var tab_traits = $VBox/Container_Tt/HBox
	for child in tab_traits.get_children():
		child.queue_free()
		tab_traits.remove_child(child)
	var traits = unit.tags + unit.dat.get("*traits", [])
	for i in range(traits.size()):
		var active = G.data.trait_data.get(traits[i])
		if active != null:
			var newslot = MenuIcon.instance()
			newslot.assign(active)
			newslot.set_description(active.name, G.desc.display_trait(active.name))
			tab_traits.add_child(newslot)
	if tab_traits.get_child_count() == 0:
		$VBox/Label_Tt.hide()
	else:
		$VBox/Label_Tt.show()

func update_abilities():
	var tab_abilities = $VBox/Container_Sk/HBox
	for child in tab_abilities.get_children():
		child.queue_free()
		tab_abilities.remove_child(child)
	var unit_abs = unit.abilities
	var item_abs = unit.get_item_abilities()
	for i in range(unit_abs.size()):
		var active = unit_abs[i]
		var activename = active.name
		var newslot = MenuIcon.instance()
		newslot.assign(active)
		newslot.set_description(activename, G.desc.display_ability(activename))
		if activename in item_abs:
			item_abs.erase(activename)
			newslot.set_part("iab", null)
		elif "trigger" in active:
			newslot.set_part("sab", null)
		else:
			newslot.set_part("ab", null)
		tab_abilities.add_child(newslot)
	if tab_abilities.get_child_count() == 0:
		$VBox/Label_Sk.hide()
	else:
		$VBox/Label_Sk.show()

func update_inventory():
	var tab_equipment = $VBox/Container_Eq/HBox
	var tab_inventory = $VBox/Container_Inv/HBox
	for child in tab_equipment.get_children():
		child.queue_free()
		tab_equipment.remove_child(child)
	for child in tab_inventory.get_children():
		child.queue_free()
		tab_inventory.remove_child(child)
	for i in unit.equipments:
		var eq = unit.equipments[i]
		var newslot = MenuIcon.instance()
		newslot.set_part(i, "eq_"+i)
		if eq != null:
			var itemname = eq.get("name")
			newslot.assign(eq)
			newslot.set_description(itemname, G.desc.display_item(G.data.item_data.get(itemname)))
			newslot.add_button("gui/icon_trash", funcref(self, "drop"))
		tab_equipment.add_child(newslot)
	for i in range(unit.dat.get("carries", 6)):
		var newslot = MenuIcon.instance()
		newslot.set_part("inv", null)
		if i < unit.inventory.size():
			var itemname = unit.inventory[i].get("name")
			newslot.assign(unit.inventory[i])
			newslot.set_description(itemname, G.desc.display_item(G.data.item_data.get(itemname)))
			newslot.add_button("gui/icon_trash", funcref(self, "drop"))
		tab_inventory.add_child(newslot)
	if tab_equipment.get_child_count() == 0:
		$VBox/Label_Eq.hide()
	else:
		$VBox/Label_Eq.show()

func drop(menuicon):
	menuicon.host.untake(G.you.host.pos)
	menuicon.unassign(true)
