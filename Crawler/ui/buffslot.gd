extends Panel

onready var label = $Label
var stylebox = get_stylebox("panel", "")
var buff
var buff_name
var buff_description

func assign(bname, p):
	buff = p
	buff_name = bname
	buff_description = buff.skill.get("desc")
	var img = buff.skill.get("img")
	if img != null:
		$Sprite.texture = G.data.get_image(img)

func _on_mouse_entered():
	G.ui.describe("text", buff_name, buff_description)

func _on_mouse_exited():
	G.ui.description.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			_on_mouse_entered()
		else:
			_on_mouse_exited()
