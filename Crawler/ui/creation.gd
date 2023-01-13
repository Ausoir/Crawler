extends Control

onready var panel = $"Dialog/TabContainer/Character"
onready var unit = $"Dialog/Options/unit"
var load_data

func _ready():
	G.ui.disable(true)
	rect_position = G.camera.position - G.ui.screen_size/2
	G.vars.seed = G.rng.i()
	randomize_unit()
	update()
	G.tip.check("start")

func start():
	for i in load_data:
		if i == "equip":
			var equips = []
			for ii in load_data[i] + G.vars.load_data["*equip"]:
				if ii != null:
					equips.append(G.data.item_data.get(ii))
			G.vars.load_data["*equip"] = equips
		elif i == "items":
			var inventory = []
			for ii in load_data[i] + G.vars.load_data["*items"]:
				if ii != null:
					inventory.append(G.data.item_data.get(ii))
			G.vars.load_data["*items"] = inventory
		elif i == "traits":
			G.vars.load_data["*traits"] += load_data[i]
		elif i == "abilities":
			G.vars.load_data["abilities"] += load_data[i]
		else:
			G.vars.load_data[i] = load_data[i]
	queue_free()
	G.ui.disable(false)
	G.game.load_world()

func update():
	panel.unit = unit
	panel.refresh_page()

func randomize_unit():
	load_data = {"items":[], "equips":[]}
	load_data.seed = G.rng.i()
	var specie = G.rng.r_arr(G.data.vars.loadouts)
	load_data["name"] = specie
	var specie_data = G.data.unit_data.get(specie)
	for stat in G.data.vars.stats:
		load_data[stat] = specie_data.get(stat, 0)
	load_data["abilities"] = specie_data.get("abilities", [])
	load_data["traits"] = specie_data.get("*traits", [])
	var json = G.data.unit_data.get(specie)
	unit.dat = G.factory.Properties.new(json)
	unit.set_texture_from_path(json.img)
	unit.on_change(2)
	unit.show()

func _on_meta_clicked(_meta):
	G.ui.description.hide()
	if _meta == "start":
		start()
	elif _meta == "reroll":
		randomize_unit()
		update()
