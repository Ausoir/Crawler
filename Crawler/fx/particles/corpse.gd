extends "res://entity/item.gd"

var texture
var lifetime = 256

func make(host):
	texture = host.n_sprite.texture
	for i in range(1, 8):
		var node = get_node("Part" + str(i))
		G.data.set_polygon_texture(node, texture, true)
	$AnimationPlayer.play("Die" + str(G.rng.ir(1, 3)))
	item_type = "corpse"
	item_name = "corpse"
	save_to_map = false
	G.world.turn.add(self)

func hit(_type, _dmg, _hitter):
	return 0

func on_turn():
	lifetime -= 1
	if lifetime <= 0:
		.remove()
