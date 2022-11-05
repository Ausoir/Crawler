extends Sprite

const SPEED = 520
var dest
var vel: Vector2
var host
var lifetime = .5
var closest_range = 800000
var variance_from = 8
var variance_to = G.HW

var onattack
var onshoot
var onmiss

func init(phost, img, from, to):
	host = phost
	set_texture(img)
	G.world.others.add_child(self)
	position = from.get_position() + G.rng.vfr(variance_from)
	dest = to
	var dest_vec = to.get_position() + G.rng.vfr(variance_to)
	var rot = atan2(dest_vec.y-position.y, dest_vec.x-position.x)
	rotate(rot)
	vel.x = cos(rot) * SPEED
	vel.y = sin(rot) * SPEED

func _physics_process(_delta):
	position += vel * _delta
	var dist = position.distance_squared_to(dest.get_position())
	var tile = G.vec_to_tile(position)
	if tile != host.pos and tile.is_col(2):
		on_collide(tile)
		return
	elif dist > closest_range:
		on_collide(dest)
		return
	closest_range = dist
	if lifetime < 0:
		if onmiss != null:
			G.cmds(onmiss, host, G.vec_to_tile(position))
		remove()
	else:
		lifetime -= _delta

func on_collide(tile):
	if onattack != null:
		G.cmds(onattack, host, tile)
	remove()

func remove():
	G.world.others.remove_child(self)
	queue_free()
