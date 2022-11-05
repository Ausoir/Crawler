extends Particles2D

export var canvas: bool = false
export var duration: float = 1.0
var follow

func add():
	if canvas:
		G.world.canvas.add_child(self)
	else:
		G.world.others.add_child(self)
	set_emitting(true)

func _process(delta):
	duration -= delta
	if duration < 0:
		if canvas:
			get_parent().remove_child(self)
		else:
			get_parent().remove_child(self)
		queue_free()

func run_details(args):
	for i in args:
		if i == "direction":
			process_material.direction = args[i]
		elif i == "spread":
			process_material.spread = args[i]
		elif i == "follow":
			position = args[i].position

func change_text(p):
	$Label/Control/Label.text = str(p)
