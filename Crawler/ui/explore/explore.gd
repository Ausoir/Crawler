extends Control

const MenuIcon = preload("res://ui/MenuIcon.tscn")

var inventory

func create():
	var current = G.vars.level
	$List/Header.set_bbcode("[center][color=#8AA]Level " + str(current) + "[/color][/center]")
	G.rng.set_seed(G.vars.seed)
	inventory = G.rng.r_arr(G.data.vars.levels[clamp(current, 1, G.data.vars.levels.size()) - 1])
	update_inventory()

func update_inventory():
	var section = $List/Scroll/Inventory
	for child in section.get_children():
		child.queue_free()
		section.remove_child(child)
	for itemname in inventory:
		var item = G.data.level_data.get(itemname)
		var hbox = HBoxContainer.new()
		var newslot = MenuIcon.instance()
		newslot.set_part("inv", null)
		newslot.assign(item)
		newslot.set_description("The " + itemname, item.get("desc", ""))
		newslot.add_button("gui/icon_enter", funcref(self, "enter"), [itemname])
		hbox.add_child(newslot)
		var label = Label.new()
		label.set_text("Enter the " + itemname.capitalize())
		hbox.add_child(label)
		section.add_child(hbox)

func enter(to):
	var prep = get_parent().get_parent()
	prep.exit()
	G.game.travel(to)
