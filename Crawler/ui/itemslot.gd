extends RichTextLabel

export var part = "none"
var host
var enabled = true
var tile

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
		if !event.is_pressed():
			G.ui.description.hide()
			if G.ui.last_touch_time < .25 and enabled:
				if G.ui.menu.drag_item != null and G.ui.menu.drag_item.type == "item":
					place_to(G.ui.menu.drag_item)
					G.ui.menu.display(-1)
				else:
					if take_from():
						G.ui.menu.display(-1)
		elif host != null:
			describe_item()

func describe_item():
	if typeof(host) == 17:
		G.ui.describe("item", host.get_display_name(), host)

func assign(p):
	var r
	if host != null:
		r = host
	host = p
	var txt = host.get_display_name()
	if host.get_health() <= 0:
		set_bbcode("[color=#922]" + txt + "[/color]")
	else:
		set_bbcode(txt)
	return r

func unassign(remove=false):
	if host != null:
		var r
		G.you.add_topic(host.get("topic"))
		if tile:
			host.host.take()
			r = {"drag":host.get_display_name(), "type":"item", "item":host}
		elif remove:
			r = {"drag":host.get_display_name(), "type":"item", "item":host}
			host.remove()
		host = null
		set_bbcode("")
		return r

func take_from():
	if host != null:
		var r = unassign(true)
		if r:
			G.ui.menu.set_drag_item(r)
			return true

func place_to(pitem):
	var swap = false
	if host != null:
		G.ui.menu.set_drag_item(null)
		take_from()
		swap = true
	if tile != null:
		pitem.item.untake(tile)
		assign(pitem.item)
	elif pitem.item.dat.get("part") != null:
		if part == "none":
			assign(pitem.item)
		elif part == "inv":
			if !G.you.host.store(pitem.item):
				G.ui.menu.set_drag_item(pitem.item)
				return false
		else:
			if !G.you.host.equip(pitem.item):
				G.ui.menu.set_drag_item(pitem.item)
				return false
	else:
		pitem.item.untake(G.you.host.pos)
	if !swap:
		G.ui.menu.set_drag_item(null)
	return true

