extends Control

onready var title = $Control/Title
onready var content = $Control/Content
var callback

func reposition():
	rect_size.x = 0 #reset size after long descriptions etc
	rect_size.y = 0
	rect_position.x = G.ui.screen_size.x/2 - rect_size.x/2
	rect_position.y = G.ui.screen_size.y/2 - rect_size.y/2

func array_to_string(arr):
	var r = ""
	var prefix = ""
	for i in arr:
		r += prefix + i.capitalize()
		prefix = ", "
	return r

func display(header, cb):
	var context
	var abname = header.substr(1)
	if header[0] == "&":
		context = display_trait(G.data.trait_data.get(abname))
	elif header[0] == "$":
		context = display_item(G.data.item_data.get(abname))
	elif header[0] == "%":
		context = display_ability(G.data.ability_data.get(abname))
	elif header[0] == "/":
		var arr = header.split("/")
		abname = arr[1]
		context = arr[2]
	else:
		abname = header
		context = G.data.vars.desc.get(abname)
	if cb != null:
		callback = cb
		context += "\n[right][url=cb][img=32]" + cb[0] + "[/img][/url][/right]"
	on_display(abname, context)

func on_display(header, desc):
	title.set_text(header.capitalize())
	content.set_bbcode(desc)
	show()
	reposition()

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
	for s in dat.keys():
		if s[0] == "+":
			desc += "[color=#2C2]"+G.L.str_signed_int(dat.get(s))+" to "+s.substr(1).capitalize()+"[/color]\n"
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
	desc += get_line("#56A", "", ability.get("cooldown", 0), " Second cooldown", 0)
	desc += get_line("#84A", "", ability.get("duration", 1), " Second duration", 1)
	desc += get_line("#CC3", "", ability.get("block"), " Damage block")
	desc += get_line("red", "", ability.get("desc_dmg"), " damage")
	desc += get_line("#F92", "", ability.get("noise"), " Tile noise")
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

func _on_meta_clicked(meta):
	if meta == "cb":
		callback[1].call_funcv(callback[2])
