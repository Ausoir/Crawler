extends Node

const Task = preload("res://entity/task.gd")
var host
var default = null
var move = null
var attack = null
var route = null
var task = null
var priority = 5
var frame = 0
var lifetime = 500
var alert = 0
var noise = 0
var perceive_idx = 0
var is_humanoid = false
var destructiveness = 0
var has_night_vision = false
var closest_enemy

func set_ai(args):
	if args.empty():
		default = Task.Wander.new()
	elif default == null or default.get_class() != args[0]:
		default = str_to_task(args[0]).new()
	if args.size() < 2:
		if move == null:
			move = Task.Pathing.new()
	elif move == null or move.get_class() != args[1]:
		move = str_to_task(args[1]).new()
	if args.size() < 3:
		if attack == null:
			attack = Task.Attack.new()
	elif attack == null or attack.get_class() != args[2]:
		attack = str_to_task(args[2]).new()
	default.pilot = self
	move.pilot = self
	attack.pilot = self
	set_task(default)

func str_to_task(p):
	if p == "guard":
		return Task.Guard
	elif p == "wander":
		return Task.Wander
	elif p == "follow":
		return Task.Follow
	elif p == "path":
		return Task.Pathing
	elif p == "attack":
		return Task.Attack
	elif p == "idle":
		return Task.Idle

func on_turn():
	if host.action.delay == 0:
		if host.team == 1:
			perceive()
			engage(closest_enemy)
		if task.on_turn():
			task.perform()

func perceive():
	var per = host.dat.get("perception", 4)
	var nocturnal = "nocturnal" in host.tags
	var closest
	var closest_dist = per*2
	var sth = host.dat.get("stealth", 0)
	var foe_list = G.census.get_foe(host)
	var foe_list_size = foe_list.size()
	for _i in range(min(28, foe_list_size)):
		if perceive_idx >= foe_list_size:
			perceive_idx = 0
		var foe = foe_list[perceive_idx]
		perceive_idx += 1
		if is_instance_valid(foe):
			var dist = max(0, host.pos.distance_to(foe.pos))
			if dist <= G.C:
				_i += 4
				if host.pos.get_beam_to(foe.pos, 1)[1] == foe.pos:
					var foeper = foe.dat.get("perception", 4)
					if dist <= max(1, G.camera.get_visible_distance(host.pos.light, foeper, "nocturnal" in foe.tags) - sth):
						foe.pilot.engage(host)
					if dist <= closest_dist and dist <= G.camera.get_visible_distance(foe.pos.light, per, nocturnal):
						closest_dist = dist
						closest = foe
				elif dist <= noise - sth:
					foe.pilot.hear(host.pos)
	noise = 0
	if !is_instance_valid(closest_enemy) or closest_dist < host.pos.distance_to(closest_enemy.pos):
		closest_enemy = closest

func make_noise(p):
	noise = max(p, noise)

func set_task(p):
	p.on_set()
	task = p

func on_hit(hitter):
	if is_instance_valid(hitter) and hitter != host:
		if task.target != hitter and hitter.team == host.team*-1:
			set_task(attack)
			task.target = hitter

func on_die():
	if host.last_hitter == G.you.host:
		G.you.on_kill(host)

func hear(at):
	if priority > 3:
		if !("deaf" in host.tags):
			if at.distance_to(host.pos) >= 1:
				var seentile = host.pos.get_beam_to(at, 1)[1]
				if seentile == at:
					for i in at.items:
						if host.team == i.team * -1:
							engage(i)
							return
				else:
					move.target = at
					set_task(move)

func engage(p):
	if p != null and priority > 1:
		set_task(attack)
		task.target = p
		shout()
		host.dat.run("onspot")

func shout():
	if !("deaf" in host.tags):
		G.make_particle("Shout", host.pos)
		make_noise(13)

func remove():
	queue_free()

func on_change(p):
	if p == 2:
		destructiveness = host.dat.get("strength", 1)

func on_assign():
	pass

func unassign():
	if host != null:
		host.pilot = null
		host.possess()
		host = null

func perform_ability(enemy):
	var dist = host.pos.distance_to(enemy.pos)
	for i in range(host.abilities.size()):
		var ability = host.abilities[i]
		if ability.get("trigger", 0) == 0:
			var rng = ability.get("range", 1)
			if dist <= rng:
				var cd = host.action.cooldowns.get(ability.get("name",""), -1)
				if cd == -1:
					if host.pos.get_beam_to(enemy.pos, int(ability.get("col", 4)))[1] == enemy.pos:
						host.action.next_action = ["ability", i, enemy.pos]
						return true
