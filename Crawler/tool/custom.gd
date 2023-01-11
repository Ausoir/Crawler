#Hardcoded events

func run(p, _params):
	if p == "die":
		G.vars["dead"] = true
		var host = _params[0]
		var player_unit = G.cmds([["make", "spectator", host.pos]])
		player_unit.possess(G.you)
		G.cmds([["menu", "confirm", "Game Over", "You have died...\n\nReturning to menu.", funcref(G.custom, "run")]])
	elif p == "reload":
		G.game.load_game()
		G.you.unserialize(G.vars.get("load_data"))
		G.cmds([["menu", "travel", "base"]])
	elif p == "branches":
		var candidates = []
		var unit = _params[0]
		var req_runes = _params[1]
		var unitname = unit.dat.get("name")
		var cl = unit.dat.get("class", [])
		var evolvable = []
		var rune = []
		for i in unit.inventory:
			var ev = i.get("evolve")
			if ev != null:
				evolvable.append(ev)
				rune.append(i.get("name"))
		for candname in G.data.unit_data:
			var cand = G.data.unit_data[candname]
			var candcl = cand.get("class", [])
			if !candcl.empty():
				var similarity = 0
				var missing = []
				for i in candcl:
					if i in cl:
						similarity += 1
					else:
						missing.append(i)
				similarity = max(candcl.size(), cl.size()) - similarity
				if candname != unitname and similarity <= 1:
					if candcl.size() == cl.size():
						missing.append("change")
					elif missing.empty():
						missing = ["pure"]
					var req_met = true
					if req_runes:
						for i in missing:
							if !(i in evolvable):
								req_met = false
					if req_met:
						candidates.append([cand, missing])
		return candidates
	elif p == "show branch":
		var unit = _params[0]
		var candidates = G.script("branches", [unit, false])
		var content = ""
		var showing = []
		for _i in range(min(candidates.size(), 4)):
			var index = G.rng.ir(0, candidates.size()-1)
			if !(index in showing):
				showing.append(index)
		for i in showing:
			var branch = candidates[i]
			content += "+".join(branch[1]) + " > " + branch[0].get("name", "") + "\n"
		G.cmds([["menu", "confirm", "Path of <" + unit.dat.get("name") + ">", content, null]])
	elif p == "blink":
		var host = _params[0]
		var rng = int(_params[1])
		var col = int(_params[2])
		var tile = host.pos.get_rand_offset(rng, rng)
		return host.pos.get_beam_to(tile, col, rng)[1]
	elif p == "return":
		if "hostpos" in G.vars:
			var newunit = G.cmds([["travel","$p","{^hostpos}"],["=seed","{^hostseed}"]])
			G.vars.erase("hostpos")
			if newunit != null:
				G.cmds([["control",newunit],["remove",_params[0]]])
				return
		run("die", [G.you.host])
	elif p == "recall":
		var adjs = _params[0].get_available_adjacents(12)
		var adj = G.rng.r_arr(adjs)
		if adj != null:
			var cdat = G.vars.get("party", [])
			var dat = cdat.pop_front()
			if dat != null:
				G.factory.make_unit(dat.name, adj, dat)
				var tadj = G.rng.r_arr(adj.get_available_adjacents(12))
				if tadj != null:
					adj = tadj
	elif p == "respawn":
		var pos = _params[0].pos
		if G.you.host.pos == pos:
			_params[0].remove()
			var old_unit = G.you.host
			var player_unit = G.cmds([["make", "player", pos]])
			player_unit.possess(G.you)
			old_unit.die()
	elif p == "mutate":
		if G.rng.b():
			G.msg(["Nothing happens..."])
		else:
			var traits = G.you.host.tags
			if traits.empty():
				G.you.host.add_trait(G.rng.r_arr(G.data.trait_data.keys()))
			else:
				var type = G.data.trait_data[traits[0]].type
				var cands = []
				for tname in G.data.trait_data:
					var trait = G.data.trait_data[tname]
					if trait.type == type or G.rng.f() < .3:
						cands.append(tname)
				G.you.host.add_trait(G.rng.r_arr(cands))
	elif p == "animate":
		var item = _params[0].items.pop_front()
		if item != null:
			G.factory.make_unit_from_data(item.dat, _params[0])
	elif p == "grow":
		var chunk = _params[0].chunk
		for _times in range(_params[2]):
			var tile = G.rng.r_arr(chunk.tiles)
			var combo = _params[1].get(tile.icon)
			if combo != null:
				for item in G.data.get_combo(combo):
					G.factory.make_any(item, tile)
	elif p == "can_follow":
		var count = 0
		for i in G.census.get_ally(G.you.host):
			if i.pilot.default.get_class() == "follow":
				count += 1
		if count >= G.you.host.dat.get("charisma", 1):
			return false
		return true
	elif p == "noise":
		for foe in G.census.teams[2]:
			var dist = max(0, _params[0].difference_to(foe.pos))
			if dist <= _params[1]:
				foe.pilot.hear(_params[0])
	elif p == "reclaim":
		if _params[0] != null:
			var split = _params[0].split(",")
			G.cmds([["travel","$p",split],["find","seed",_params[1]],["control","$t"]])
