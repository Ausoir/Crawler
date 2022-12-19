extends Control

onready var tabs = $Tabs

func _ready():
	tabs.set_tab_icon(0, G.data.get_image("gui/icon_character"))
	tabs.set_tab_title(0, "")
	tabs.set_tab_icon(1, G.data.get_image("gui/icon_settings"))
	tabs.set_tab_title(1, "")

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

func _on_tab_change(_page):
	var tab_character = $Tabs/Character
	var tab_settings = $Tabs/Settings/Control
	if tab_character.visible:
		tab_character.unit = G.you.host
		tab_character.refresh_page()
	elif tab_settings.visible:
		tab_settings.refresh()
