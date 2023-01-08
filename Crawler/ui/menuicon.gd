extends Control

export var part = "none"
var host
var desc
var button

func _ready():
	connect("gui_input", self, "_on_gui_input")

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if !event.is_pressed():
			describe_item()

func describe_item():
	if desc != null:
		G.ui.describe(desc[0], desc[1], button)

func set_part(p, img):
	part = p
	if img != null:
		$Mg.set_texture(G.data.get_image("gui/"+img))

func add_button(dir, fun, params=[]):
	button = ["res://assets/images/"+dir+".png", fun, params]

func set_description(header, content):
	desc = [header, content]

func assign(p):
	var r
	if host != null:
		r = host
	host = p
	$Fg.set_texture(G.data.get_image(host.get("img")))
	return r

func unassign(remove=false):
	if host != null:
		if remove and !(host is Dictionary):
			host.remove()
		host = null
		desc = null
		$Fg.set_texture(null)
