extends Node

const Healthbar = preload("res://ui/Health.tscn")

var dict = {}

func show_healthbar(dat, host):
	var vit = G.Mat.get_durability_of(dat)
	var n_healthbar = dict.get(host)
	if n_healthbar == null:
		n_healthbar = Healthbar.instance()
		G.world.others.add_child(n_healthbar)
		dict[host] = n_healthbar
	n_healthbar.host = host
	n_healthbar.set_mhp(vit)
	n_healthbar.set_hp(max(0, vit - dat.get("damage", 0)))
	set_process(true)

func on_remove(host):
	var n_healthbar = dict.get(host)
	if n_healthbar != null:
		n_healthbar.on_remove()

func _process(delta):
	for key in dict.keys():
		var val = dict[key]
		if val.on_process(delta):
			dict.erase(key)
			if dict.empty():
				set_process(false)
