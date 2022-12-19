extends Control

onready var panel = $"Dialog/TabContainer/Character"
onready var unit = $"Dialog/Options/unit"
var load_data

func _ready():
	rect_position = G.camera.position - G.ui.screen_size/2
	G.vars.seed = G.rng.i()
	randomize_unit()
	update()

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
	queue_free()
	G.game.load_world()

func update():
	panel.unit = unit
	panel.refresh_page()

func randomize_unit():
	load_data = {}
	load_data.seed = G.rng.i()
	var specie = G.rng.r_arr(G.data.vars.loadouts)
	load_data["name"] = specie
	var specie_data = G.data.unit_data.get(specie)
	for stat in G.data.vars.stats:
		load_data[stat] = specie_data.get(stat, 0)
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
