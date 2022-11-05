extends Node

const Loading = preload("res://ui/Loading.tscn")
var player_name = "Player"
var loading_page

func load_world(new=false):
	loading_page = Loading.instance()
	G.ui.add_child(loading_page)
	G.time.set_process(true)
	G.get_tree().get_current_scene().queue_free()
	yield(G.get_tree().create_timer(0.1), "timeout")

	G.get_tree().set_pause(true)
	G.time.reset()
	var root = G.get_tree().get_root()
	for i in root.get_children():
		if i != self and i != G and i.get_tree() != G.get_tree() and i != G.world:
			i.queue_free()
			root.remove_child(i)
	loading_page.get_node("Label").set_text("World initialization...")
	var newworld = load('res://world/World.tscn').instance()
	G.get_tree().get_root().add_child(newworld)
	if new:
		newworld.create("start")
	else:
		newworld.create("start")
	G.world = newworld
	G.world.add_child(G.sfx)
	G.world.players.add_child(G.you)
	loading_page.get_node("Label").set_text("Loading player data...")
	G.you.unserialize(G.vars.get("load_data"))
	G.vars.erase("load_data")
	loading_page.get_node("Label").set_text("Finishing up...")
	G.ui.remove_child(loading_page)
	G.get_tree().set_pause(false)
	G.cmds(G.data.vars.get("onstart"), G.you.host)
	if new:
		G.cmds(G.data.vars.get("onnew"), G.you.host)

func end_game():
	G.ui.clear()
	G.get_tree().set_pause(true)
	save_game(true)
	G.get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)

func abandon_game():
	G.vars["dead"] = true
	G.get_tree().set_pause(true)
	save_game(true)
	restart()

func restart():
	clean_up()
	G.get_tree().set_pause(false)
	G.get_tree().change_scene_to(load("res://Start.tscn"))

func clean_up():
	G.get_tree().set_pause(true)
	var root = G.get_tree().get_root()
	for i in root.get_children():
		if i != self and i != G:
			i.queue_free()
			root.remove_child(i)
	for i in G.get_children():
		i.queue_free()
		G.remove_child(i)
	G._ready()
	G.get_tree().set_pause(false)

func start_game():
	if !load_game():
		G.data.delete_maps()
		G.get_tree().change_scene_to(load("res://ui/Creation.tscn"))
	else:
		load_world()

func save_game(end=false):
	var tile = G.you.host.pos
	tile.remove_item(G.you.host)
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	if end:
		G.camera.set_process(false)
		G.camera.target = null
	else:
		G.you.host.relocate(tile, true)
	if G.you.host != null:
		var lines = G.you.serialize(end)
		for line in lines:
			save_game.store_line(line)
	save_game.close()

func load_game():
	var r = true
	var save_game = File.new()
	var line
	save_game.open("user://savegame.save", File.READ)
	line = save_game.get_line()
	if line.empty():
		save_game.close()
		save_game = File.new()
		save_game.open("res://assets/template.save", File.READ)
		line = save_game.get_line()
		r = false
	G.vars = parse_json(line)
	G.vars.load_data = parse_json(save_game.get_line())
	save_game.close()
	return r

func start_editor():
	clean_up()
	G.get_tree().change_scene_to(load("res://editor/Editor.tscn"))

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().quit() # default behavior
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		save_game(false)
