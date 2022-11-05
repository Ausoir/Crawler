extends Control

var state = 1

func _ready():
	G.rng.set_seed()
	on_fadeout() #quick start

func _input(event):
	if !(event is InputEventMouseButton):
		G.get_tree().set_input_as_handled()

func start():
	if state < 2:
		state = 2
		$AnimationPlayer.play("FadeOut")

func on_fadeout():
	G.game.start_game()

func _on_meta_clicked(meta):
	if !G.vars.setting.showfps:
		G.ui.n_fps.hide()
	if meta == "start":
		start()
	elif meta == "editor":
		G.game.start_editor()
	elif meta == "exit":
		G.get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
