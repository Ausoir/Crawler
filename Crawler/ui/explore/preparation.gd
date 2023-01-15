extends Control

onready var tabs = $Tabs
onready var tint = $Tint
var ingame = true

func _ready():
	tabs.set_tab_icon(1, G.data.get_image("gui/icon_character"))
	tabs.set_tab_title(1, "")
	tabs.set_tab_icon(4, G.data.get_image("gui/icon_settings"))
	tabs.set_tab_title(4, "")
	$Tabs/Character.unit = G.you.host
	$Tabs/Character.refresh_page()
	$Tabs/Settings.refresh()
	if !ingame:
		G.ui.disable(true)
		tabs.set_tab_icon(0, G.data.get_image("gui/icon_explore"))
		tabs.set_tab_title(0, "")
		tabs.set_tab_icon(2, G.data.get_image("gui/icon_manage"))
		tabs.set_tab_title(2, "")
		tabs.set_tab_icon(3, G.data.get_image("gui/icon_shop"))
		tabs.set_tab_title(3, "$" + str(G.vars.money))
		$Tabs/Explore.set_script(load("res://ui/explore/explore.gd"))
		$Tabs/Manage.set_script(load("res://ui/explore/manage.gd"))
		$Tabs/Shop.set_script(load("res://ui/explore/shop.gd"))
		$Tabs/Explore.create()
		$Tabs/Shop.create("Item Shop")
		$Tabs/Manage.unit = G.you.host
		$Tabs/Manage.create()
	else:
		tabs.set_tab_hidden(0, true)
		tabs.set_tab_hidden(2, true)
		tabs.set_tab_hidden(3, true)
		tabs.set_current_tab(1)
	G.game.save_game(false)

func notify(label, sprite, rating=0):
	tabs.hide()
	tint.set_size(G.ui.screen_size)
	tint.show()
	if rating > 0:
		var particles = tint.get_node("Particles2D")
		if rating >= 2:
			particles.get_process_material().hue_variation_random = 1
		if rating == 3:
			particles.set_amount(16)
		particles.set_emitting(true)
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
	G.ui.clear()
	queue_free()

func input_key():
	if ingame:
		if Input.is_action_just_pressed("quick_1"):
			tabs.set_current_tab(1)
		elif Input.is_action_just_pressed("quick_2"):
			tabs.set_current_tab(4)
	else:
		if Input.is_action_just_pressed("quick_1"):
			tabs.set_current_tab(0)
		elif Input.is_action_just_pressed("quick_2"):
			tabs.set_current_tab(1)
		elif Input.is_action_just_pressed("quick_3"):
			tabs.set_current_tab(2)
		elif Input.is_action_just_pressed("quick_4"):
			tabs.set_current_tab(3)
		elif Input.is_action_just_pressed("quick_5"):
			tabs.set_current_tab(4)
