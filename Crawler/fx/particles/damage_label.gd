extends Label

var lifetime = 100
var vel
var vel_angle
var scale_mod
var speed_mod = 800
var position = rect_position

func _ready():
	vel = Vector2(G.rng.ir(-48, 48), G.rng.ir(-48, 0))
	vel_angle = G.rng.fr(-1, 1)

func set_damage(dmg, color, _scale, _speed):
	set_text(str(dmg))
	set_pivot_offset(rect_size / 2)
	add_color_override("font_color", color)
	scale_mod = _scale
	speed_mod = _speed

func _physics_process(delta):
	position.x += delta * vel.x
	position.y += delta * vel.y
	rect_position = position
	vel.x *= .99
	vel.y += delta * speed_mod
	set_rotation_degrees(rect_rotation + vel_angle)
	lifetime -= delta * speed_mod
	if lifetime < 0:
		G.world.others.remove_child(self)
		queue_free()
	else:
		var process = min(1, lifetime * .03)
		modulate.a = process
		var scale = process * scale_mod
		rect_scale.x = scale
		rect_scale.y = scale
