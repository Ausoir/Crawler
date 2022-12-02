extends Control

export var part = "none"
var host

func _ready():
	connect("gui_input", self, "_on_gui_input")
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")

func _on_mouse_entered():
	describe_item()

func _on_mouse_exited():
	G.ui.description.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if host != null:
			if !event.is_pressed():
				G.ui.description.hide()
				if G.ui.last_touch_time < .25:
					on_click()
					G.ui.menu.display(-1)
			else:
				describe_item()

func describe_item():
	if typeof(host) == 17:
		G.ui.describe("item", host.get_display_name(), host)

func set_part(p, img):
	part = p
	if img != null:
		$Mg.set_texture(G.data.get_image("gui/"+img))

func assign(p):
	var r
	if host != null:
		r = host
	host = p
	$Fg.set_texture(G.data.get_image(host.get("img")))
	return r

func unassign(remove=false):
	if host != null:
		if remove:
			host.remove()
		host = null
		$Fg.set_texture(G.data.get_image("gui/slot_full"))

func on_click():
	host.untake(G.you.host.pos)
	unassign(true)
