extends Control

var pos_v = 0
var timeout = 0

func add(msg):
	set_position(Vector2(64, G.ui.screen_size.y - 36))
	var label = Label.new()
	label.set_text(str(msg))
	for child in get_children():
		var pos = child.get_position()
		child.set_position(Vector2(pos.x, pos.y - 20))
		var color = child.get("custom_colors/font_color")
		if color == null:
			child.set("custom_colors/font_color", Color(1, 1, 1, 1))
		elif color.a > .2:
			child.set("custom_colors/font_color", Color(color.r, color.g, color.b, color.a-.2))
		else:
			child.queue_free()
	label.set_use_parent_material(true)
	add_child(label)
	timeout = 120

func _process(_delta):
	if timeout > 0:
		timeout -= 1
	else:
		for child in get_children():
			var color = child.get("custom_colors/font_color")
			if color == null:
				child.set("custom_colors/font_color", Color(1, 1, 1, 1))
			elif color.a > .2:
				child.set("custom_colors/font_color", Color(color.r, color.g, color.b, color.a-.01))
			else:
				child.queue_free()
