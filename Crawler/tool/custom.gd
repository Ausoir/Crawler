#Hardcoded events

func run(p, _params):
	if p == "die":
		G.vars["dead"] = true
		G.cmds([["menu","dialog","death"]])
		var host = _params[0]
		var player_unit = G.cmds([["make", "ghost", host.pos]])
		player_unit.set_seed(host.dat.get("seed",-1))
		player_unit.possess(G.you)
	elif p == "blink":
		var host = _params[0]
		var rng = int(_params[1])
		var col = int(_params[2])
		var tile = host.pos.get_rand_offset(rng, rng)
		return host.pos.get_beam_to(tile, col, rng)[1]
	elif p == "movez":
		var pos = G.you.host.pos
		G.vars.hunger -= 10
		G.world.bubble.travel(pos.get_x(), pos.get_y(), pos.chunk.global_coord.x-1, pos.chunk.global_coord.y-1, true, _params[0])
		pos = G.you.host.pos
		if _params[0] > 0:
			pos.set_terrain('<')
		else:
			pos.set_terrain('>')
		G.ui.fadein()
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
	elif p == "repair" or p == "craft":
		if !G.you.check_brightness(true):
			return
		var item = _params[0]
		var skillname = _params[1]
		var skill = G.data.vars.skills.get(skillname)
		var item_mat = item.get("mat")
		var size = item.get("size", 1)
		var onfail = "Craft failed!"
		if p == "repair":
			size *= .2
			onfail = "Repair failed!"
		var tools = G.you.host.get_available_tags("tool", skill.get("tool"))
		var best
		for tl in tools:
			if best == null or tl.get("quality", 0) > best.get("quality", 0):
				best = tl
		var ingred = G.you.host.get_available_mat(item_mat, size)
		if ingred != null:
			var recipe_items
			if p == "craft":
				var recipe = item.get("recipe", [null,null])
				if recipe[0] != null:
					skillname = recipe[0]
				if recipe[1] != null:
					recipe_items = G.you.host.get_available_items_by_name(recipe[1])
					if recipe_items.empty():
						G.msg(["You need "+recipe[1]+"!"])
						return false
			var time = int(size / best.get("quality", 0))*G.Mat.get_weight_of(item)*2
			if !G.you.sleep(time, false):
				return false
			var ammo = best.get("spend")
			if ammo==null or !G.cmds([["req","element",ammo[0],ammo[1]],["=stop"]]):
				if recipe_items != null:
					recipe_items.pop_front().remove()
				G.you.sleep(time)
				var chance = G.you.skills.skills.get(skillname)
				if chance == null or G.rng.r_percent(chance):
					ingred.remove()
					if p == "repair":
						item.a("damage", 0)
						G.msg(["Repaired ["+item.get("name")+"]!"])
					else:
						item.a("quality", G.rng.f()*.5 + chance)
						item.untake(G.you.host.pos)
						G.msg(["Crafted ["+item.get("name")+"]!"])
				else:
					G.you.skills.gain_xp(skillname, size)
					G.msg([onfail])
			else:
				G.msg([best.get("name").capitalize()+" needs "+str(ammo[1])+" "+ammo[0]+"!"])
		else:
			G.msg(["You need ["+item_mat.capitalize()+"] of size "+str(size)+" or bigger."])
	elif p == "mutate":
		if G.rng.b():
			G.msg(["Nothing happens..."])
		else:
			var traits = G.you.host.traits
			if traits.empty():
				G.you.host.add_trait(G.rng.r_arr(G.data.vars.traits.keys()), true)
			else:
				var type = G.data.vars.traits[traits[0]].type
				var cands = []
				for tname in G.data.vars.traits:
					var trait = G.data.vars.traits[tname]
					if trait.type == type or G.rng.f() < .3:
						cands.append(tname)
				G.you.host.add_trait(G.rng.r_arr(cands), true)
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
	elif p == "first_aid":
		if G.you.host.buffs.has("injury"):
			var tools = G.you.host.get_available_tags("tool", _params[0].get("tool"))
			var best
			for tl in tools:
				if best == null or tl.get("quality", 0) > best.get("quality", 0):
					best = tl
			if G.you.check_brightness(true) and G.you.sleep(1):
				G.you.host.buffs.end("injury")
				if G.rng.r_percent(G.you.skills.skills.get("first aid")):
					var dmg = int(G.you.host.dat.get("damage", 0) / 4)
					G.you.host.dat.a("damage", dmg*(4-best.get("quality", 0)))
					G.make_particle("Heal", G.you.host.pos)
					G.sfx.play("Heal", G.you.host.pos)
	elif p == "lockpick":
		var tools = G.you.host.get_available_tags("tool", _params[0].get("tool"))
		var best
		for tl in tools:
			if best == null or tl.get("quality", 0) > best.get("quality", 0):
				best = tl
		if G.you.check_brightness(true) and G.you.sleep(1, false) and best.use(1, "Tool is out of uses!"):
			G.you.sleep(1)
			var chance = G.you.skills.skills.get("lockpicking")
			if chance == null:
				G.msg(["You don't know how to lockpick!"])
			elif G.rng.r_percent(chance + best.get("quality", 0)*.2):
				for tile in G.you.host.pos.get_area(1):
					for item in tile.items:
						if item.item_type == "item":
							item.dat.run("onunlock")
			else:
				G.you.skills.gain_xp("lockpicking", 1)
				G.msg(["Lockpicking failed!"])
	elif p == "noise":
		for foe in G.census.teams[2]:
			var dist = max(0, _params[0].difference_to(foe.pos))
			if dist <= _params[1]:
				foe.pilot.hear(_params[0])
	elif p == "butcher":
		var tools = G.you.host.get_available_tags("tool", _params[0].get("tool"))
		var best
		for tl in tools:
			if best == null or tl.get("quality", 0) > best.get("quality", 0):
				best = tl
		var found_corpse = false
		for item in G.you.host.pos.items:
			if item.item_type == "corpse":
				found_corpse = true
				if G.you.sleep(1, false) and best.use(1, "Tool is out of uses!"):
					var chance = G.you.skills.skills.get("butchering")
					if chance == null:
						chance = 0
					if G.rng.r_percent(chance + best.get("quality", 0)*.9):
						G.you.sleep(1)
						if item.dat.run("onbutcher") == null:
							G.msg(["There's nothing useful in this..."])
						item.remove()
						return
					else:
						item.remove()
						G.you.sleep(1)
						G.you.skills.gain_xp("butchering", 1)
						G.msg(["Butcher failed!"])
		if !found_corpse:
			G.msg(["No corpses to butcher!"])
	elif p == "reclaim":
		if _params[0] != null:
			var split = _params[0].split(",")
			G.cmds([["travel","$p",split],["find","seed",_params[1]],["control","$t"]])
