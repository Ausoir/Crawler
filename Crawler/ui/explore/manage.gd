extends Control

const MenuIcon = preload("res://ui/MenuIcon.tscn")

var unit

func create():
	$List/Header.set_bbcode("[center][color=#8AA]Manage Character[/color][/center]")
	G.rng.set_seed(G.vars.seed)
	var levels = G.data.level_data.keys().duplicate()
	levels.shuffle()
	update_inventory()

func update_inventory():
	var section = $List/Scroll/Inventory
	for child in section.get_children():
		child.queue_free()
		section.remove_child(child)
	for item in unit.inventory:
		var hbox = HBoxContainer.new()
		var newslot = MenuIcon.instance()
		var itemname = item.get("name")
		newslot.set_part("inv", null)
		newslot.assign(item, "/Enter the " + itemname + "/" + item.get("desc", ""))
		newslot.add_button("gui/icon_enter", funcref(self, "enter"), [])
		hbox.add_child(newslot)
		var label = Label.new()
		label.set_text(" " + itemname.capitalize())
		hbox.add_child(label)
		section.add_child(hbox)

func enter():
	print("waa")
