var host
var tgt

func do(ability, phost=null, dest=null, mode=0):
	tgt = dest
	host = phost
	if !find_victim(ability):
		return false
	else:
		var reqs = ability.get("reqs")
		if reqs != null and G.cmds(reqs, host, tgt) == false:
			return false
		if mode == 0 or mode == 3:
			if is_instance_valid(host):
				var cooldown = ability.get("cooldown")
				if cooldown != null:
					if ability.name in host.action.cooldowns:
						return false
					var cd_reduc = 1 + (host.dat.get("wits", 1) * .1)
					host.action.cooldowns[ability.name] = int(G.vars.time + cooldown/cd_reduc)
				var noise = ability.get("noise")
				if noise != null:
					host.pilot.make_noise(noise)
				host.action.delay = ability.get("delay", host.action.delay)
			if mode == 3:
				G.cmds(ability.get("compensate", []), host, tgt)
			if "duration" in ability and host.item_type == "unit":
				if host.buffs.has(ability.name):
					G.cmds(ability.get("onstack", []), host, tgt)
					return true
				else:
					host.buffs.add(ability, ability.duration, tgt)
			if mode == 0:
				G.cmds(ability.get("onstart", []), host, tgt)
		elif mode == 1:
			G.cmds(ability.get("onturn", []), host, tgt)
		elif mode == 2:
			G.cmds(ability.get("onend", []), host, tgt)
		if tgt != null:
			if !is_instance_valid(tgt):
				G.cmds(ability.get("onkill", []), host, tgt)
		return true

func find_victim(skill):
	var target = skill.get("target")
	if target == "self":
		tgt = host
		if host != null and host.item_type == "tile":
			host = host.get_items_by_type("unit").pop_front()
		return host != null
	elif tgt != null:
		if target == "beam":
			var rng = skill.get("range", 1)
			tgt = host.pos.get_beam_to(tgt, int(skill.get("col", 0)), rng)[1]
			return true
		elif target == "beam2":
			var rng = skill.get("range", 1)
			tgt = host.pos.get_beam_to(tgt, int(skill.get("col", 0)), rng)[0]
			return tgt != host.pos
		elif target == "tile":
			var rng = skill.get("range", 1)
			return host.pos.distance_to(tgt) <= rng
		elif target == "rand":
			var rng = skill.get("range", 1)
			var tile = host.pos.get_rand_offset(rng, rng)
			tgt = host.pos.get_beam_to(tile, int(skill.get("col", 0)), rng)[0]
			return true
		elif tgt != null and is_instance_valid(tgt):
			return true
	return false

func get_tile(p):
	return G.world.from_vec(p)
