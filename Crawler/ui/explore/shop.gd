extends Control

const MenuIcon = preload("res://ui/MenuIcon.tscn")

var inventory

func create(title):
	$List/Header.set_bbcode("[center][color=#8AA]" + title + "[/color][/center]")
	inventory = []
	G.rng.set_seed(G.vars.seed)
	for _i in range(G.rng.ir(4, 12)):
		inventory.append(G.rng.r_arr(G.data.shop_items))
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
		newslot.set_description(itemname, item.get("desc", ""))
		newslot.add_button("gui/icon_buy", funcref(self, "buy"), [newslot, item, itemname])
		hbox.add_child(newslot)
		var label = Label.new()
		label.set_text(" " + itemname.capitalize() + " - " + str(item.get("value")) + "g")
		hbox.add_child(label)
		section.add_child(hbox)

func buy(newslot, item, itemname):
	var bought = G.factory.unserialize_property(G.data.item_data, itemname, item)
	G.you.host.auto_equip(bought, true)
	newslot.unassign(true)
	get_parent().get_parent().notify("Item Bought", bought.get("img", "blank"))
