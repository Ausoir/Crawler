extends Control

onready var title = $Control/Title
onready var content = $Control/Content
var lifetime = 0

func _process(_delta):
	if !G.ui.on:
		lifetime -= _delta
		if lifetime <= 0:
			hide()
			set_process(false)

func hide():
	rect_size.y = 32
	.hide()

func on_display(header, desc):
	set_process(true)
	lifetime = 3
	title.set_text(header.capitalize())
	content.set_bbcode(desc)
	show()
	rect_global_position.y = 0
	G.add_event(0, funcref(self, "reposition"))

func reposition():
	rect_global_position.x = G.ui.screen_size.x - rect_size.x - 4

func array_to_string(arr):
	var r = ""
	var prefix = ""
	for i in arr:
		r += prefix + i.capitalize()
		prefix = ", "
	return r

func display(type, header, subject):
	var context
	if type == "text":
		context = subject
	elif type == "item":
		context = display_item(subject)
	elif type == "ability":
		context = display_ability(subject)
	elif type == "tile":
		context = display_tile(subject)
	elif type == "trait":
		context = display_trait(subject)
	on_display(header, context)

func display_tile(tile):
	var desc = ""
	if tile.light > 0:
		desc += get_light_description(tile.light)
	if tile.col & 2 > 0:
		desc += "[color=#888]Blocks projectiles[/color]\n"
	if tile.col & 4 > 0:
		desc += "[color=#888]Obstructs movement[/color]\n"
	if tile.slow > 0:
		desc += "[color=#882]Slows movement by " + str(tile.slow) + "[/color]\n"
	var tiledesc = tile.dat.get("desc")
	if tiledesc != null:
		desc += tiledesc + "\n"
	desc += "\n"
	for item in tile.items:
		desc += "Contains: "+item.item_name.capitalize()+"\n"
		desc += display_item(item) + "\n"
	return desc

func display_item(item):
	var dat = item.get("dat")
	if dat == null:
		dat = item
	var desc = ""
	var money = dat.get("value")
	if money != null:
		desc += get_line("#FB0", "", G.L.str_money(money), "")
	desc += get_line("#99A", "Material: ", dat.get("mat", "other").capitalize(), "", "other")
	var tl = dat.get("tool")
	if tl != null:
		desc += get_line("#99A", "", tl.capitalize(), " Level "+str(dat.get("quality",1)))
	desc += get_line("#8A4", "Quality: ", G.L.str_percentage(dat.get("quality", 1)), "", "100%")
	if typeof(item) != 18:
		desc += get_line("#C22", "Integrity: ", G.L.str_percentage(dat.get_health()), "")
	desc += get_line("#999", "Weight: ", G.Mat.get_weight_of(dat), "kg", -1)
	var parts = dat.get("parts")
	if parts != null:
		desc += "[color=#44B]Parts - "+ G.L.str_array(parts) +"[/color]\n"
		desc += get_line("#AAA", "Coverage: ", G.L.str_percentage(dat.get("size", 0)), "")
		desc += get_line("#CFF", "Pockets: ", dat.get("pockets", 0), " items", 0)
		desc += get_line("#86A", "Storage: ", dat.get("space", 0), " items", 0)
		desc += get_line("#8A4", "Hardness: ", G.Mat.get_armor_of(item), "")
		desc += get_line("#8A4", "Resistance: ", G.Mat.get_resistance_of(item), "", 0)
	desc += get_line("#C84", "Bash Damage: ", dat.get("bash", 0), "", 0)
	desc += get_line("#C48", "Cut Damage: ", dat.get("cut", 0), "", 0)
	var abilities = dat.get("abilities", [])
	if !abilities.empty():
		var skill_types = [[],[],[]]
		for skill in abilities:
			var data = G.data.ability_data.get(skill)
			if data != null:
				var trigger = data.get("trigger", 0)
				skill_types[trigger].append(skill)
		if !skill_types[0].empty():
			desc += "[color=#56A]Techniques: "+ array_to_string(skill_types[0]) +"[/color]\n"
		if !skill_types[1].empty():
			desc += "[color=#84A]Abilities: "+ array_to_string(skill_types[1]) +"[/color]\n"
		if !skill_types[2].empty():
			desc += "[color=#996]Actives: "+ array_to_string(skill_types[2]) +"[/color]\n"
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i].name
		var astat = dat.get("+"+s)
		if astat != null:
			desc += "[color=#2C2]"+G.L.str_signed_int(astat)+" to "+s.capitalize()+"[/color]\n"
	var uses = dat.get("uses")
	if uses != null:
		if uses <= 0:
			desc += "[color=#1AA]Out of charges[/color]\n"
		else:
			desc += "[color=#1B9]Amount: " + str(uses) + "[/color]\n"
	var descs = dat.get("descs")
	if descs != null:
		for i in descs:
			var val = dat.get(i)
			if val != null:
				if descs[i] == null: #Custom
					if i == "expire":
						if G.vars.time > val:
							desc += "[color=#C84]This item has expired.[/color]\n"
						else:
							desc += "[color=#8A4]This item expires in: "+G.L.str_expire(val)+"[/color]\n"
				elif descs[i].size() > 2 and val != null:
					desc += get_line("#FFF", descs[i][0], val * descs[i][2], descs[i][1])
				else:
					desc += get_line("#FFF", descs[i][0], val, descs[i][1])
	desc += get_line(null, "", dat.get("desc"))
	return desc

func display_ability(ability):
	var desc = ""
	var ch = ability.get("chance")
	if ch != null:
		var dex = 0
		if G.you.host != null:
			dex = G.you.host.dat.get("dexterity", 0)
		desc += "[color=#FB3]"+ G.L.str_percentage(ch+dex*.01)+" Chance[/color]\n"
	var cd = ability.get("cooldown")
	if cd != null:
		var itl = 0
		if G.you.host != null:
			itl = cd * (G.you.host.dat.get("intelligence", 0) * .01)
		desc += get_line("#56A", "", cd-itl, " Cooldown")
	desc += get_line("#1B9", "", ability.get("delay", 0), " Turns")
	desc += get_line("#84A", "", ability.get("duration", -1), " Duration", -1)
	desc += get_line("#CC3", "", ability.get("block"), " Block")
	desc += get_line("red", "", ability.get("desc_dmg"))
	desc += get_line("#F92", "Noise: ", ability.get("noise"))
	desc += get_line("#888", "", ability.get("desc2"))
	desc += get_line(null, "", ability.get("desc"))
	return desc

func display_trait(trait):
	var desc = ""
	desc += get_line("#44B", "Part: ", trait.get("part"), "")
	desc += get_line(null, "", trait.get("desc"))
	return desc

func get_line(color, prefix, text, suffix="", check=null):
	var r = ""
	if text != check:
		if color != null:
			r += "[color="+color+"]"+prefix+str(text)+suffix+"[/color]\n"
		else:
			r += prefix+str(text)+suffix+"\n"
	return r

func get_light_description(light):
	if light == 0:
		return "[color=#114]Dark[/color]\n"
	elif light == 1:
		return "[color=#412]Dimly Lit[/color]\n"
	elif light == 2:
		return "[color=#824]Shaded[/color]\n"
	elif light >= 3:
		return "[color=#C64]Bright[/color]\n"
