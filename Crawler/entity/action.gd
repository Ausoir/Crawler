var host
var cooldowns = {}
var on_finish = null
var current_action = null
var current_action_fn = "idle"
var last_action = null
var next_action = null
var delay = 0
var move_delay = 2
var idle_frame = 0

func _init(p):
	host = p

func on_turn():
	if delay > 0:
		delay -= 1
	elif delay == 0:
		if next_action != null:
			set_action(next_action)
			next_action = null
	for i in cooldowns:
		if G.vars.time >= cooldowns[i]:
			cooldowns.erase(i)

func set_action(params):
	idle_frame = 0
	if delay != 0:
		on_finish = null
	current_action = params.pop_front()
	current_action_fn = funcref(self, current_action)
	if on_finish:
		var fn = on_finish  # prevent recursion
		on_finish = null
		if funcref(self, fn).call_func():
			return true
	current_action_fn.call_funcv(params)
	last_action = current_action

func swap(dir):
	var targetpos = host.pos.get_adjacent(dir)
	for item in targetpos.items:
		if item.item_type == "unit":
			item.relocate(host.pos)
			host.relocate(targetpos)
			delay = 4
			host.n_animation.play("climb")

func slide(dir):
	var targetpos = host.pos.get_adjacent(dir)
	if move_delay < 80:
		var ms = move_delay
		var d = 0
		for item in targetpos.items:
			if is_instance_valid(item):
				if item.item_type == "unit" and item.action.delay == 0 and item.team == host.team:
					item.relocate(host.pos)
					d += 4
		host.face(dir)
		if !targetpos.is_col(host.col_mask):
			if host.col_mask & 4 > 0:
				ms += int(targetpos.slow)
				d += max(1, 2 + ms)
				G.Mat.make_step_sound_of(targetpos.dat, targetpos)
			else:
				d += max(1, 2 + ms)
			host.n_animation.play("walk", -1, 8 / d)
			host.relocate(targetpos)
			delay = d
			host.n_animation.seek(0)
			host.position_speed = 2 + 4 / d
			if !host.visible:
				if "earsight" in host.tags:
					host.set_visible(true)
				else:
					G.make_particle("Sound", host.pos, null, true)

func roll_ability(type, tile=null, mode=0):
	host.face_toward(tile)
	for ability in host.abilities:
		if ability.get("trigger", 0) == 0 and ability.target == type:
			if G.fx.do(ability, host, tile, mode):
				return ability
			return null

func ability(idx, at):
	if idx < 0:
		return G.fx.do(G.data.ability_data.get("pickup"), host, at)
	elif idx < host.abilities.size():
		host.face_toward(at)
		return G.fx.do(host.abilities[idx], host, at)

func wait():
	delay = 8
	host.n_animation.play("wait")

func interact(tile):
	if host == G.you.host:
		return G.you.interact(tile)
	return false

func use(item):
	if host == G.you.host:
		G.you.use(item)
		return true

func command(cmds, h, tgt):
	G.cmds(cmds, h, tgt)
