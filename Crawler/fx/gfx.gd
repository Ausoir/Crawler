extends Tween

var graphic
var lifetime = .3

func _init():
	G.world.others.add_child(self)

func shoot(img_name, from, to):
	graphic = G.data.get_sprite(img_name)
	add_child(graphic)
	graphic.rotate(atan2(to.y-from.y, to.x-from.x))
	interpolate_property(graphic, "position",
		from, to, lifetime,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	start()

func rotate(img_name, from, to):
	graphic = G.data.get_sprite(img_name)
	add_child(graphic)
	interpolate_property(graphic, "rotation",
		from, to, lifetime,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	start()

func _on_tween_done():
	if graphic != null:
		graphic.queue_free()
	G.world.others.remove_child(self)
	queue_free()
