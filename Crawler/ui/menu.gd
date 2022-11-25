extends Control

const Script_ItemSlot = preload("res://ui/itemslot.gd")
const Script_AbilitySlot = preload("res://ui/abilityslot.gd")
const Script_CraftSlot = preload("res://ui/craftslot.gd")
const TextSlot = preload("res://ui/TextSlot.tscn")

onready var tabs = $Tabs
onready var tab_equipment = $Tabs/INV/HSplit/Equipment
onready var tab_inventory = $Tabs/INV/HSplit/Inventory
onready var tab_cha_stats = $Tabs/CHA/HSplit/Stats
onready var tab_cha_abilities = $Tabs/CHA/HSplit/Abilities
onready var tab_settings = $Tabs/OPT/Control
onready var n_drag = $Drag
onready var container = $Container
onready var container_grid = $Container/Container

var drag_item


func _on_mouse_move():
	if drag_item != null:
		n_drag.rect_position = G.ui.mouse_pos

func _background_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if drag_item != null and drag_item.type == "item":
				drag_item.item.remove()
				drag_item.item.untake(G.you.host.pos)
				set_drag_item(null)
				search_inventory(G.you.host.pos)
			else:
				G.ui.clear()

func display(_arg):
	show()
	if _arg != -1:
		tabs.set_current_tab(_arg)
	_on_tab_change(tabs.current_tab)

func clear():
	hide()
	container.hide()
	if drag_item != null and drag_item.type == "item":
		drag_item.item.untake(G.you.host.pos)
	set_drag_item(null)

func _on_tab_change(page):
	if page == 0:
		update_equipment()
		update_inventory()
	elif page == 1:
		update_status()
		update_abilities()
	elif page == 2:
		tab_settings.refresh()

func set_drag_item(item):
	if item == null:
		if drag_item:
			n_drag.hide()
			drag_item = null
	else:
		drag_item = item
		n_drag.set_text(item.drag)
		n_drag.show()
		_on_mouse_move()

func update_equipables(equipables):
	for child in tab_equipment.get_children():
		if child is RichTextLabel:
			child.queue_free()
			tab_equipment.remove_child(child)
	for slot in equipables:
		var newslot = TextSlot.instance()
		newslot.set_script(Script_ItemSlot)
		var allow_type = equipables[slot]
		newslot.make_mode(slot, allow_type)
		tab_equipment.add_child(newslot)

func update_equipment():
	var n_eq = []
	var n_eq_label
	for child in tab_equipment.get_children():
		if child is RichTextLabel:
			child.unassign(false)
			n_eq.append(child)
		else:
			n_eq_label = child
	var unit = G.you.host
	if unit.dat.get("body") == "man":
		for child in n_eq:
			for eq in unit.equipments:
				if child.part in eq.get("parts", []):
					child.assign(eq)
			if child.part == "weapon":
				if unit.weapon != null:
					child.assign(unit.weapon)
		var tw = unit.get_total_weight()
		var sta = unit.dat.get("stamina", 1) * .5
		n_eq_label.set_text("Weight ["+ str(tw) +"/"+str(sta)+"kg]")

func update_inventory():
	var n_inv_label
	for child in tab_inventory.get_children():
		if child is RichTextLabel:
			child.queue_free()
			tab_inventory.remove_child(child)
		else:
			n_inv_label = child
	var unit = G.you.host
	if unit.dat.get("body") == "man":
		var index = 0
		var pockets = unit.pockets
		for inv_item in unit.inventory:
			var newslot = TextSlot.instance()
			newslot.set_script(Script_ItemSlot)
			newslot.part = "inv"
			newslot.index = index
			index += 1
			if inv_item != null:
				newslot.assign(inv_item)
			if pockets > 0:
				pockets -= 1
				newslot.modulate = Color.aqua
				var stylebox = newslot.get_stylebox("normal").duplicate()
				stylebox.bg_color = Color(.4, .1, .3, .1)
				newslot.add_stylebox_override("normal", stylebox)
			tab_inventory.add_child(newslot)
		n_inv_label.set_text("Money: "+G.L.str_money(G.vars.money))

func search_inventory(tile):
	G.ui.display(0)
	container.show()
	container.set_tab_title(0, tile.item_name.capitalize())
	for child in container_grid.get_children():
		container_grid.remove_child(child)
		child.queue_free()
	for item in tile.items:
		if item.item_type == "item":
			var newslot = TextSlot.instance()
			newslot.set_script(Script_ItemSlot)
			newslot.assign(item.dat)
			newslot.tile = tile
			if item.dat.get("part") == null:
				newslot.allow_type = newslot.SLOT_DISABLED
				newslot.modulate = Color(.5,.5,.5,.5)
			container_grid.add_child(newslot)

func update_abilities():
	for child in tab_cha_abilities.get_children():
		if child is RichTextLabel:
			child.queue_free()
			tab_cha_abilities.remove_child(child)
		else:
			child.set_text("Abilities:")
	var unit_abs = G.you.host.abilities
	var item_abs = []
	if G.you.host.dat.get("body") == "man":
		item_abs = G.you.host.get_item_abilities()
	for i in range(unit_abs.size()):
		var active = unit_abs[i]
		var newslot = TextSlot.instance()
		newslot.set_script(Script_AbilitySlot)
		if active.name in item_abs:
			item_abs.erase(active.name)
			newslot.assign(active, -1)
			newslot.set_type(newslot.TYPE_ITEM)
		elif "trigger" in active:
			newslot.assign(active, i)
			newslot.set_type(newslot.TYPE_ABILITY)
		else:
			newslot.assign(active, i)
		tab_cha_abilities.add_child(newslot)

func update_status():
	tab_cha_stats.get_node("Label").set_text(str(int(G.you.host.get_health()*100))+"% Health")
	var textbox = tab_cha_stats.get_node("Text")
	var txt = textbox.get_stats_text(G.you.host.dat)
	textbox.set_bbcode(txt)

func _on_label_input(event, meta):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if meta == "equipment":
				G.ui.describe("text","Weight","You can carry weight up to your Stamina points.")
		else:
			G.ui.description.hide()
