extends Control

onready var tabs = $Tabs

func _ready():
	G.ui.disable(true)
	tabs.set_tab_icon(0, G.data.get_image("gui/icon_explore"))
	tabs.set_tab_title(0, "")
	tabs.set_tab_icon(1, G.data.get_image("gui/icon_character"))
	tabs.set_tab_title(1, "")
	tabs.set_tab_icon(2, G.data.get_image("gui/icon_manage"))
	tabs.set_tab_title(2, "")
	tabs.set_tab_icon(3, G.data.get_image("gui/icon_shop"))
	tabs.set_tab_title(3, "")
	tabs.set_tab_icon(4, G.data.get_image("gui/icon_settings"))
	tabs.set_tab_title(4, "")
	$Tabs/Explore.set_script(load("res://ui/explore/explore.gd"))
	$Tabs/Manage.set_script(load("res://ui/explore/manage.gd"))
	$Tabs/Shop.set_script(load("res://ui/explore/shop.gd"))
	$Tabs/Explore.create(3)
	$Tabs/Character.unit = G.you.host
	$Tabs/Character.refresh_page()
	$Tabs/Shop.create("Item Shop")
	$Tabs/Manage.unit = G.you.host
	$Tabs/Manage.create()
	$Tabs/Settings/Control.refresh()
	G.game.save_game(false)

func _background_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			G.ui.clear()

func exit():
	G.ui.disable(false)
	G.ui.remove_child(self)
	queue_free()
