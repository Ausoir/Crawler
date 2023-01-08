extends Control

onready var tabs = $Tabs
onready var tint = $Tint

func _ready():
	G.ui.disable(true)
	tint.set_size(G.ui.screen_size)
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

func notify(label, sprite):
	tabs.hide()
	tint.show()
	tint.get_node("AnimationPlayer").play("effect1")
	tint.get_node("Label").set_text(label)
	tint.get_node("Sprite").set_texture(G.data.get_image(sprite))

func _background_input(event):
	if event is InputEventMouseButton:
		if tint.visible and event.is_pressed():
			exit()
			G.cmds([["menu", "prepare"]])

func exit():
	G.ui.disable(false)
	G.ui.remove_child(self)
	queue_free()
