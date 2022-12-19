extends Node

var player_name = "Player"

func travel(args):
	G.world.create(args)
	G.you.host.relocate(G.world.get_spawn_point())

func load_world():
	G.time.set_process(true)
	G.get_tree().set_pause(true)
	G.time.reset()
	G.get_tree().change_scene_to(load('res://world/World.tscn'))

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
	if G.you.host != null:
		var tile = G.you.host.pos
		tile.remove_item(G.you.host)
		G.world.save()
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
	var is_open = save_game.is_open()
	if is_open:
		line = save_game.get_line()
	if !is_open or line.empty():
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
