extends Control

onready var panel_stats = $"Dialog/Character/HSplit/StatPanel"
onready var panel_traits = $"Dialog/Skills/HSplit/Traits"
onready var panel_skills = $"Dialog/Skills/HSplit/Rightside/Skills"
var load_data

func _ready():
	rect_position = G.camera.position - G.ui.screen_size/2
	randomize_unit()
	G.vars.hunger = G.vars.time + G.you.MAX_HUNGER
	G.vars.seed = G.rng.i()
	var unit = $"Dialog/Character/HSplit/Rightside/Options/unit"
	var json = G.data.unit_data.get("human")
	unit.set_script(G.factory.Script_Humanoid)
	unit.dat = G.factory.Properties.new(json, unit)
	unit.show()
	update()
	panel_stats.connect("meta_clicked", self, "_on_meta_clicked")
	panel_traits.connect("meta_clicked", self, "_on_meta_clicked")
	panel_skills.connect("meta_clicked", self, "_on_meta_clicked")

func start():
	for i in load_data:
		if i == "equip":
			var equips = []
			for ii in load_data[i]:
				if ii != null:
					equips.append(G.data.item_data.get(ii))
			G.vars.load_data["equip"] = equips
		elif i == "inventory":
			var inventory = []
			for ii in load_data[i]:
				if ii != null:
					inventory.append(G.data.item_data.get(ii))
			G.vars.load_data["inventory"] = inventory
		elif i == "weapon" and load_data.weapon != null:
			G.vars.load_data["weapon"] = G.data.item_data.get(load_data[i])
		else:
			G.vars.load_data[i] = load_data[i]
	G.game.load_world(true)

func update():
	var txt = "[i]Human[/i]\n"
	txt += panel_stats.get_stats_text(G.factory.Properties.new(load_data))
	panel_stats.set_bbcode(txt)
	var txt2 = G.L.str_money(G.vars.money)+"\n"
	var txt3 = ""
	if load_data.weapon != null:
		txt2 += "[url="+load_data.weapon+"][color=#A94]"+load_data.weapon.capitalize()+"[/color][/url]\n"
	for i in load_data.equip:
		if i != null:
			txt2 += "[url=_"+i+"][color=#A94]"+i.capitalize()+"[/color][/url]\n"
	for i in load_data.inventory:
		if i != null:
			txt2 += "[url=_"+i+"][color=#864]"+i.capitalize()+"[/color][/url]\n"
	$"Dialog/Character/HSplit/Rightside/Text2".set_bbcode(txt2)
	if load_data.abilities.size() > 0:
		txt3 += "[url=#"+load_data.abilities[0]+"][color=#2A9]"+load_data.abilities[0].capitalize()+"[/color][/url]\n"
		if load_data.abilities.size() > 1:
			txt3 += "[url=#"+load_data.abilities[1]+"][color=#56A]"+load_data.abilities[1].capitalize()+"[/color][/url]"
	$"Dialog/Character/HSplit/Rightside/Text3".set_bbcode(txt3)
	panel_skills.set_bbcode(panel_skills.get_skills_text(G.vars.skills))
	panel_traits.set_bbcode(panel_traits.get_traits_text(G.vars.traits))
	var unit = $"Dialog/Character/HSplit/Rightside/Options/unit"
	for i in range(unit.overlay_sprites.size()):
		unit.remove_overlay(i)
	unit.dat.a("gender", "m")
	unit.set_seed(load_data.seed)
	var count = 1
	for i in G.vars.traits:
		var tdat = G.data.vars.traits.get(i)
		if tdat != null:
			var img = tdat.get("img")
			if img != null:
				var dict = {"img": "overlay/mutation/"+img, "gender": tdat.get("gender", false)}
				unit.create_overlay(count, dict, 1)
				count += 1

func _on_meta_clicked(_meta):
	G.ui.description.hide()
	if _meta == "start":
		start()
	elif _meta == "reroll":
		randomize_unit()
		update()
	else:
		on_describe(_meta)

func _on_meta_hover_started(meta):
	on_describe(meta)

func on_describe(meta):
	var abname = meta.substr(1)
	if meta[0] == "#":
		G.ui.describe("ability", abname.capitalize(), G.data.ability_data.get(abname))
	elif meta[0] == "$":
		G.ui.describe("text", abname.capitalize(), G.data.vars.skills.get(abname).desc)
	elif meta[0] == "&":
		G.ui.describe("trait", abname.capitalize(), G.data.vars.traits.get(abname))
	else:
		G.ui.describe("item", abname.capitalize(), G.data.item_data.get(abname))

func _on_meta_hover_ended(_meta):
	G.ui.description.hide()

func randomize_unit():
	load_data = {"abilities": [], "inventory": [], "equip": [], "pos":[0,0], "team":1}
	G.vars.traits = []
	G.vars.skills = {}
	G.vars.money = G.rng.r_arr([0, 25, 125, 500, 2000])
	load_data.seed = G.rng.i()
	var specie_data = G.data.unit_data.get("human")
	var count = 0
	var distribution = G.rng.r_pie(G.data.vars.stats.size()+3)
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i]
		var maxvariance = s.variance * (distribution[count] - 1)
		load_data[s.name] = round(specie_data.get(s.name, 0) + maxvariance)
		count += 1
	var abilities = []
	for _i in range(int((distribution[count-2]-1)/.5)):
		abilities.append(G.rng.r_arr(G.data.vars.loadouts.abilities))
	for ab in specie_data.get("abilities",[]) + abilities:
		if ab != null:
			load_data["abilities"].append(ab)
	for _i in range(int((distribution[count-1]-0.5)/.25)):
		G.vars.skills[G.rng.r_arr(G.data.vars.skills.keys())] = 0
	if distribution[count] > 2:
		G.vars.traits.append(G.rng.r_arr(G.data.vars.traits.keys()))
	elif distribution[count] > 1:
		for _i in range(int((distribution[count]-.9)/.4)):
			var roll = G.rng.r_arr(G.data.vars.loadouts.traits)
			if !(roll in G.vars.traits):
				G.vars.traits.append(roll)
	load_data.equip.append(G.rng.r_arr(G.data.vars.loadouts.shoes))
	if G.rng.b():
		load_data.equip.append(G.rng.r_arr(G.data.vars.loadouts.suit))
		load_data.weapon = G.rng.r_arr(G.data.vars.loadouts.good_weapon)
	else:
		load_data.equip.append(G.rng.r_arr(G.data.vars.loadouts.torso))
		load_data.equip.append(G.rng.r_arr(G.data.vars.loadouts.legs))
		load_data.equip.append(G.rng.r_arr(G.data.vars.loadouts.equipment))
		load_data["inventory"] = [G.rng.r_arr(G.data.vars.loadouts.accessory)]
		load_data.weapon = G.rng.r_arr(G.data.vars.loadouts.bad_weapon)
	if load_data.weapon is Array:
		load_data.inventory.append(load_data.weapon[1])
		load_data.weapon = load_data.weapon[0]
