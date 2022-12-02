extends Control

onready var panel_stats = $"Dialog/Character/HSplit/StatPanel"
onready var panel_skills = $"Dialog/Character/HSplit/Rightside/Skills"
var load_data

func _ready():
	rect_position = G.camera.position - G.ui.screen_size/2
	randomize_unit()
	G.vars.seed = G.rng.i()
	update()
	panel_stats.connect("meta_clicked", self, "_on_meta_clicked")

func start():
	for i in load_data:
		if i == "equip":
			var equips = []
			for ii in load_data[i]:
				if ii != null:
					equips.append(G.data.item_data.get(ii))
			G.vars.load_data["*equip"] = equips
		elif i == "inventory":
			var inventory = []
			for ii in load_data[i]:
				if ii != null:
					inventory.append(G.data.item_data.get(ii))
			G.vars.load_data["*inventory"] = inventory
		else:
			G.vars.load_data[i] = load_data[i]
	G.game.load_world(true)

func update():
	var txt = "[i]" + load_data.name.capitalize() + "[/i]\n"
	txt += panel_stats.get_stats_text(G.factory.Properties.new(load_data))
	panel_stats.set_bbcode(txt)
	var unit = $"Dialog/Character/HSplit/Rightside/Options/unit"
	var txt3 = ""
	for i in unit.dat.get("abilities", []):
		txt3 += "[url=#"+i+"][color=#2A9]"+i.capitalize()+"[/color][/url]\n"
	panel_skills.set_bbcode(txt3)

func randomize_unit():
	load_data = {}
	load_data.seed = G.rng.i()
	var specie = G.rng.r_arr(G.data.vars.loadouts)
	load_data["name"] = specie
	var specie_data = G.data.unit_data.get(specie)
	var distribution = G.rng.r_pie(G.data.vars.stats.size())
	var count = 0
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i]
		var maxvariance = s.variance * (distribution[count] - 1)
		load_data[s.name] = round(specie_data.get(s.name, 0) + maxvariance)
		count += 1
	var unit = $"Dialog/Character/HSplit/Rightside/Options/unit"
	var json = G.data.unit_data.get(specie)
	unit.dat = G.factory.Properties.new(json)
	unit.set_texture_from_path(json.img)
	unit.show()

func _on_meta_clicked(_meta):
	G.ui.description.hide()
	if _meta == "start":
		start()
	elif _meta == "reroll":
		randomize_unit()
		update()
	else:
		on_describe(_meta)

func on_describe(meta):
	var abname = meta.substr(1)
	if meta[0] == "#":
		G.ui.describe("ability", abname.capitalize(), G.data.ability_data.get(abname))
	elif meta[0] == "$":
		G.ui.describe("text", abname.capitalize(), G.data.vars.skills.get(abname).desc)

func _on_meta_hover_started(meta):
	on_describe(meta)

func _on_meta_hover_ended(_meta):
	G.ui.description.hide()
