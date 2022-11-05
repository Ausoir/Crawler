extends "res://ui/itemslot.gd"

var cmd
var skill

func _ready():
	assign(null)

func get_part_text():
	return "[color=#874]" + part.capitalize() + "[/color]: "

func assign(p):
	var txt = ""
	host = p
	if part == "tool":
		txt = get_part_text()
		if host == null:
			txt += "-----"
	if host != null:
		txt += host.get_display_name()
	set_bbcode(txt)

func assign_result(p, pskill=null, pcmd=null):
	skill = pskill
	cmd = pcmd
	var chance = 1
	if skill != null:
		chance = G.you.skills.skills.get(skill, 0)
	var txt = "[color=#874](" + G.L.str_percentage(chance) + ")[/color] "
	if cmd != null:
		set_bbcode(txt + p)
	else:
		host = p
		set_bbcode(txt + host.get_display_name())

func unassign(remove=false):
	if host != null:
		var r
		if remove:
			r = {"drag":host.get_display_name(), "type":"item", "item":host}
			host.remove()
		assign(null)
		return r

func take_from():
	if part == "result":
		if G.you.check_brightness(true):
			var chance = G.you.skills.skills.get(skill, 0)
			if G.rng.r_percent(chance):
				if !.take_from():
					G.cmds(cmd, G.you.host)
			else:
				G.you.skills.gain_xp(skill, 1)
				G.msg(["Crafting failed!"])
			G.ui.menu.clear_craft(false)
	elif .take_from():
		G.ui.menu.clear_craft()
		G.ui.menu.update_craft()
		G.ui.menu.update_craftables()

func place_to(pitem):
	var swap = false
	if host != null:
		G.ui.menu.set_drag_item(null)
		take_from()
		swap = true
	if part != "result":
		assign(pitem.item)
		G.ui.menu.update_craftables()
	if !swap:
		G.ui.menu.set_drag_item(null)
	return true
