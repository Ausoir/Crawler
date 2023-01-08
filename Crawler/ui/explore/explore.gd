extends Control

const MenuIcon = preload("res://ui/MenuIcon.tscn")

var inventory

func create(current):
	$List/Header.set_bbcode("[center][color=#8AA]Level " + str(current) + "[/color][/center]")
	inventory = []
	G.rng.set_seed(G.vars.seed)
	var levels = G.data.vars.levels.duplicate()
	levels.shuffle()
	for _i in range(G.rng.ir(2, 4)):
		var level = levels.pop_front()
		if level != null:
			inventory.append(G.data.level_data.get(level))
	update_inventory()

func update_inventory():
	var section = $List/Scroll/Inventory
	for child in section.get_children():
		child.queue_free()
		section.remove_child(child)
	for item in inventory:
		var hbox = HBoxContainer.new()
		var newslot = MenuIcon.instance()
		var itemname = item.get("name")
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
