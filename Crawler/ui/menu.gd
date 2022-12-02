extends Control

const Script_ItemSlot = preload("res://ui/itemslot.gd")
const Script_AbilitySlot = preload("res://ui/abilityslot.gd")
const Script_CraftSlot = preload("res://ui/craftslot.gd")
const TextSlot = preload("res://ui/TextSlot.tscn")
const MenuIcon = preload("res://ui/MenuIcon.tscn")

onready var tabs = $Tabs
onready var tab_character = $Tabs/CHA/VBox/HBox_Cha
onready var tab_equipment = $Tabs/CHA/VBox/HBox_Eq
onready var tab_inventory = $Tabs/CHA/VBox/HBox_Inv
onready var tab_abilities = $Tabs/CHA/VBox/HBox_Sk
onready var tab_settings = $Tabs/OPT/Control

var drag_item

func _background_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			G.ui.clear()

func display(_arg):
	rect_position.x = G.ui.screen_size.x/2 - tabs.rect_size.x/2
	show()
	if _arg != -1:
		tabs.set_current_tab(_arg)
	_on_tab_change(tabs.current_tab)

func clear():
	hide()

func _on_tab_change(page):
	if page == 0:
		update_character()
		update_abilities()
		update_inventory()
	elif page == 2:
		tab_settings.refresh()

func update_character():
	var unit = G.you.host
	tab_character.get_node("Str/Label").set_text(str(unit.dat.get("strength", 1)))
	tab_character.get_node("Dex/Label").set_text(str(unit.dat.get("dexterity", 1)))
	tab_character.get_node("Int/Label").set_text(str(unit.dat.get("intelligence", 1)))

func update_abilities():
	for child in tab_abilities.get_children():
		child.queue_free()
		tab_abilities.remove_child(child)
	var unit_abs = G.you.host.abilities
	var item_abs = G.you.host.get_item_abilities()
	for i in range(unit_abs.size()):
		var active = unit_abs[i]
		var newslot = MenuIcon.instance()
		newslot.assign(active)
		if active.name in item_abs:
			item_abs.erase(active.name)
			newslot.set_part("iab", null)
		elif "trigger" in active:
			newslot.set_part("sab", null)
		else:
			newslot.set_part("ab", null)
		tab_abilities.add_child(newslot)

func update_inventory():
	var unit = G.you.host
	for child in tab_equipment.get_children():
		child.queue_free()
		tab_equipment.remove_child(child)
	for child in tab_inventory.get_children():
		child.queue_free()
		tab_inventory.remove_child(child)
	for eq in unit.dat.get("equips", []):
		var newslot = MenuIcon.instance()
		newslot.set_part(eq, "eq_"+eq)
		var inv_item = unit.equipments.get(eq)
		if inv_item != null:
			newslot.assign(inv_item)
		tab_equipment.add_child(newslot)
	for i in range(6):
		var newslot = MenuIcon.instance()
		newslot.set_part("inv", null)
		if i < unit.inventory.size():
			newslot.assign(unit.inventory[i])
		tab_inventory.add_child(newslot)

func _on_label_input(event, meta):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if meta == "equipment":
				G.ui.describe("text","Weight","You can carry weight up to your Stamina points.")
		else:
			G.ui.description.hide()
