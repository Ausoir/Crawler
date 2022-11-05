extends RichTextLabel

const TYPE_SKILL = 0
const TYPE_ABILITY = 1
const TYPE_ITEM = 2

var index = -1
var host
var type = -1

func _ready():
	connect("gui_input", self, "_on_gui_input")
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")

func set_type(p):
	type = p
	if p == TYPE_ABILITY:
		modulate = Color.darkgreen
	elif p == TYPE_ITEM:
		modulate = Color.darkgoldenrod
	else:
		modulate = Color.white

func assign(p, idx):
	host = p
	index = idx
	set_bbcode(host.name.capitalize())
	set_type(0)

func unassign():
	if host != null:
		var r = {"drag":host.name.capitalize(),"type":"ability", "item":host.name, "index":index}
		queue_free()
		get_parent().remove_child(self)
		return r

func _on_mouse_entered():
	if host != null:
		G.ui.describe("ability", host.name, host)

func _on_mouse_exited():
	G.ui.description.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if !event.is_pressed():
			G.ui.description.hide()
			if type == TYPE_SKILL:
				if G.ui.menu.drag_item != null and G.ui.menu.drag_item.type == "ability":
					place_to(G.ui.menu.drag_item)
				else:
					take_from()
			elif type == TYPE_ITEM:
				G.ui.menu.set_drag_item(null)
		else:
			G.ui.describe("ability", host.name, host)

func take_from():
	if host != null:
		var r = unassign()
		if r:
			G.ui.menu.set_drag_item(r)

func place_to(item):
	swap_skills(item.index, index)
	G.ui.menu.set_drag_item(null)
	G.ui.menu.update_abilities()

func swap_skills(idx1, idx2):
	var skills = G.you.host.abilities
	if idx2 >= skills.size():
		var prim = skills[idx1]
		skills.remove(idx1)
		skills.append(prim)
	else:
		var prim = skills[idx1]
		skills[idx1] = skills[idx2]
		skills[idx2] = prim
	var abilities = []
	for i in skills:
		abilities.append(i.name)
	G.you.host.dat.a("abilities", abilities)
