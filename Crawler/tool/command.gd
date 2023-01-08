var tgt
var stop = false
var onstop = null
var prev
var prev_host
var tmp = {}

func replace_dats(arg):
	var last = arg.find("}")
	if last != -1:
		var r = ""
		var v = ""
		var on = false
		var once = last == len(arg) - 1 and arg[0] == "{"
		for i in arg:
			if i == "{":
				if on:
					on = false
					r += i
				else:
					on = true
			elif i == "}":
				var t
				if v.empty():
					r += i
					continue
				elif "~" in v:
					var split = v.split("~")
					t = G.rng.ir(int(split[0]), int(split[1]))
				elif "," in v:
					t = G.rng.r_arr(v.split(","))
				elif v == "t":
					t = tgt
				elif v[0] == ":":
					t = int(v.substr(1)) + G.vars.time
				elif v[0] == "^":
					t = G.vars.get(v.substr(1))
				elif v[0] == "%":
					t = str(prev_host.get("expire", 0) - G.vars.time)
				elif v[0] == "/":
					t = prev_host.get(v,"")
					t = t[0].to_upper() + t.substr(1)
				else:
					t = prev_host.get(v,"")
				if once:
					return t
				r += str(t)
				v = ""
				on = false
			elif on:
				v += i
			else:
				r += i
		return r
	return arg

func get_arbitrary(arg, s):
	var unit
	if arg[1] == "t":
		unit = tgt
	elif arg[1] == "h":
		unit = prev_host
	elif arg[1] == "$":
		return arg.substr(1)
	elif arg[1] == "p":
		unit = G.you.host
	elif arg[1] == "R":
		unit = get_rand_pos(14)
	elif arg[1] == "L":
		unit = get_los(14)
	elif arg[1] == "0":
		unit = G.world.get_tile(0, 0)
	if unit == null:
		return null
	for _i in range(s - 2):
		if !is_instance_valid(unit):
			return null
		var idx = 2+_i
		if arg[idx] == "p":
			unit = unit.pos
		elif arg[idx] == "v":
			unit = unit.get_position()
		elif arg[idx] == "a":
			var adjs = unit.get_available_adjacents(14)
			var adj = G.rng.r_arr(adjs)
			if adj == null:
				unit = unit
			else:
				unit = adj
		elif arg[idx] == "c":
			unit = unit.pilot
		elif arg[idx] == "h":
			unit = unit.host
		elif arg[idx] == "i":
			if !unit.items.empty():
				unit = unit.items[unit.items.size()-1]
		elif arg[idx] == "d":
			unit = unit.dat
		elif arg[idx] == ">":
			unit = unit.serialize()
	return unit

func replace_vars(_args):
	var r = []
	for arg in _args:
		if arg is Array:
			arg = replace_vars(arg)
		elif arg is String:
			var s = len(arg)
			if s >= 2:
				if arg[0] == "$":
					r.append(get_arbitrary(arg, s))
					continue
				elif arg[0] == "@":
					r.append(tmp.get(arg.substr(1)))
					continue
				else:
					arg = replace_dats(arg)
		r.append(arg)
	return r

func run_operation(command, dict, args):
	var what = args[1]
	var val
	if args.size() > 2:
		val = args[2]
	if command.length() == 1:
		return dict.get(what)
	elif command[1] == "=":
		dict[what] = val
	else:
		if command[1] == "+":
			if !(what in dict):
				dict[what] = val
			else:
				dict[what] += val
		elif command[1] == "^":
			if !(what in dict):
				dict[what] = [val]
			else:
				dict[what].append(val)
		elif command[1] == "v":
			if what in dict:
				dict[what].erase(val)
		elif command[1] == "d":
			if what in dict:
				dict.erase(what)
		elif command[1] == "z":
			var v1 = dict.get(what)
			var v2 = dict.get(val)
			dict[what] = v2
			dict[val] = v1
		elif command[1] == "x":
			if what in dict:
				dict[what] *= val
		elif command[1] == "c":
			if dict[what] == null:
				return val
			return dict[what].size()
	return tgt

func run(p, host):
	prev_host = host
	var args = replace_vars(p)
	var command = args[0]
	var reverse = false
	if command[0] == "!":
		command = command.substr(1)
		reverse = true
	if command[0] == "=":
		if command == "=":
			return args[1]
		elif command[1] == "h":
			host = args[1]
		elif command[1] == "*":
			return args[1] * args[2]
		elif command[1] == "+":
			var typea = typeof(args[1])
			var typeb = typeof(args[2])
			if typea != typeb:
				if typea in [2, 3] and typeb in [2, 3]:
					return float(args[1]) + float(args[2])
			return args[1] + args[2]
		elif command[1] == "-":
			return args[1] - args[2]
		elif command[1] == "g":
			return G.data.get_group(args[1])
		elif command == "=seed":
			for i in G.census.get_all():
				if i.dat.get("seed", 0) == args[1]:
					return i
			return null
		elif command == "=stop":
			return stop
	elif command[0] == "?":
		if command[1] == "=":
			var typea = typeof(args[1])
			var typeb = typeof(args[2])
			if typea != typeb:
				stop = true
				if typea in [2, 3] and typeb in [2, 3]:
					stop = float(args[1]) != float(args[2])
			else:
				stop = args[1] != args[2]
		elif command[1] == ">":
			stop = int(args[1]) <= int(args[2])
		elif command[1] == ".":
			stop = int(args[1]) < int(args[2])
		elif command[1] == "v":
			stop = !(args[1] in args[2])
	elif command[0] == "^":
		return run_operation(command, G.vars, args)
	elif command[0] == "&":
		return run_operation(command, tmp, args)
	elif command == "make":
		if args.size() > 3:
			if !args[2].is_col(int(args[3])):
				tgt = G.factory.make_any(args[1], args[2])
		elif args.size() > 2:
			tgt = G.factory.make_any(args[1], args[2])
		else:
			tgt = G.factory.unserialize_property(G.data.item_data, args[1], null)
	elif command == "run":
		return G.cmds(args[1], host, tgt)
	elif command == "onstop":
		onstop = args[1]
		return tgt
	elif command == "repeat":
		for _i in range(args[1]):
			G.cmd(prev, host)
	elif command == "menu":
		if args[1] == "msg":
			G.msg([replace_vars([args[2]])[0]])
		elif args[1] == "pickup":
			var item = host.pos.get_pickup()
			if item != null:
				host.auto_equip(item.dat, true)
				item.remove()
		elif args[1] == "menu":
			G.ui.display(args[2])
		elif args[1] == "confirm":
			G.ui.popup_confirm(args[2], args[3])
		elif args[1] == "color":
			G.ui.colorize(args[2])
		elif args[1] == "travel":
			G.add_event(0, funcref(G.game, "travel"), [args[2]])
		elif args[1] == "prepare":
			G.ui.add_child_below_node(G.ui.get_node("Animation"), load("res://ui/explore/Preparation.tscn").instance())
		elif args[1] == "fade":
			G.ui.fadein()
		elif args[1] == "restock":
			G.vars.shop = []
			for _i in range(G.rng.ir(4, 12)):
				G.vars.shop.append(G.rng.ir(0, G.data.shop_items.size()-1))
		elif args[1] == "seed":
			G.vars.seed = args[2]
			G.rng.set_seed(args[2])
		elif args[1] == "retarget":
			var t = G.you.closest_enemy
			if is_instance_valid(t):
				G.you.closest_enemy = null
				G.census.remove(t)
				G.you.perceive()
				G.census.adjust_team(t)
			return G.you.closest_enemy
		else:
			G.ui.clear()
	elif command == "gfx":
		if args[1] == "label":
			if args.size() > 5:
				G.display_damage(args[2], args[3], args[4], args[5], args[6], args[7])
			else:
				G.display_damage(args[2], args[3], args[4])
		elif args[1] == "$":
			if args[2] > 0:
				G.display_damage("+$"+str(args[2]), args[3], "#3D3", 1, 100, 50)
			elif args[2] < 0:
				G.display_damage("-$"+str(-args[2]), args[3], "#D33", 1, 100, 50)
		elif args[1] == "particle":
			G.make_particle(args[2], args[3])
	elif command == "sfx":
		G.sfx.play(args[1], args[2])
	elif command == "money":
		if G.vars.money + args[1] < 0:
			stop = true
			if get_arg(args, 2) == true:
				G.msg(["Not enough money!"])
		else:
			G.you.make_money(args[1])
	elif command == "fn":
		if !(args[1] is String):
			args[1].call_funcv(args[2])
		elif args[1] == "game":
			funcref(G.game, args[2]).call_func()
	elif command == "custom":
		G.script(args[1], args.slice(2, args.size()))
	elif command == "customt":
		return G.script(args[1], args.slice(2, args.size()))
	elif command == "sleep":
		if args.size() > 2:
			stop = !G.you.check_brightness(args[2])
		if !stop:
			stop = !G.you.sleep(args[1], true)
	elif command == "point":
		G.you.on_point = [args[1], args[2]]
		G.you.aim_ability(-2)
	elif command == "cast":
		G.fx.do(G.data.ability_data.get(args[1]), args[2], args[3])
	elif command == "projectile":
		G.factory.make_projectile(host, host.pos, tgt, args[1])
	elif command == "timed":
		if args.size() > 4:
			G.add_event(args[1], args[2], [args[3], args[4]])
	elif command == "valid":
		stop = !is_instance_valid(args[1])
	else:
		var subject = args[1]
		var subject_type = typeof(subject)
		if subject_type == 18:
			if command[0] == "*":
				return run_operation(command, subject, args)
		elif subject_type == 17 and is_instance_valid(subject):
			if subject.item_type == "tile":
				run_tile(command, args, host, subject)
			else:
				if command[0] == "*":
					if command == "*":
						return subject.get(args[2], args[3])
					elif command[1] == "=":
						subject.a(args[2], args[3])
					elif command[1] == "+":
						subject.add(args[2], args[3])
					elif command[1] == "*":
						subject.mult(args[2], args[3])
					elif command[1] == "-":
						return subject.d(args[2])
					elif command[1] == "z":
						subject.swap(args[2], args[3])
					elif command[1] == "@":
						return args[3] in subject.get(args[2])
					elif command[1] == "^":
						var t = subject.get(args[2])
						if t != null:
							var list = subject.get(args[2])
							subject.a(args[2], list + [args[3]])
						else:
							subject.a(args[2], [args[3]])
						subject.dirty(2)
					elif command[1] == "v":
						var t = subject.get(args[2])
						if t != null:
							var list = subject.get(args[2]).duplicate()
							list.erase(args[3])
							subject.a(args[2], list)
							subject.dirty(2)
					elif command == "*run":
						subject.run(args[2])
					elif command == "*dmg":
						var hp = subject.add("damage", args[2])
						subject.a("damage", max(0, hp))
						if subject.host != null:
							subject.host.on_health_change()
							G.healthbars.show_healthbar(subject.host, subject)
					elif command == "*use":
						if args.size() > 2:
							stop = !subject.use(int(args[2]))
						else:
							stop = !subject.use()
				elif command == "remove":
					subject.remove()
				elif command == "relocate":
					subject.relocate(args[2])
				elif command == "texture":
					subject.set_texture_from_path(args[2])
				elif subject.item_type == "unit":
					run_unit(command, args, subject)
				elif command == "textify":
					subject.textify(args[2])
	if reverse:
		stop = !stop
	if stop:
		if onstop != null:
			G.msg([onstop])
	onstop = null
	return tgt

func run_tile(command, args, host, subject):
	if command == "col":
		stop = subject.is_col(int(args[2]))
	elif command == "dist":
		tgt = subject.distance_to(args[2])
	elif command == "terrain":
		subject.set_terrain(args[2])
	elif command == "attack":
		var hitter = args[2]
		var dmg_type = args[3]
		var dmg = args[4]
		if hitter != null:
			dmg = hitter.get_damage(dmg_type, args[4])
		var total_dmg = 0
		for item in subject.items:
			if hitter != null and item.team == hitter.team:
				continue
			if item != null and is_instance_valid(item):
				total_dmg += item.hit(dmg_type, dmg, hitter)
			if args.size() > 5:
				G.cmds(args[5], host, item)
		if total_dmg > 0 and hitter != null:
			hitter.on_attack(total_dmg)
	elif command == "push":
		var dir_offset = 4
		if args.size() > 4:
			dir_offset = int(args[4])
		var dir = (subject.direction_to(args[2]) + dir_offset) % 8
		var tpos = subject.get_adjacent(dir, args[3])
		var lpos = subject.get_beam_to(tpos, 14)[0]
		if lpos != subject:
			for item in subject.items:
				item.relocate(lpos)
	elif command == "aoe":
		var area = subject.get_area(args[2])
		for i in area:
			for item in i.items:
				if item != host:
					G.cmds(args[3], host, item)
	elif command == "noise":
		G.you.make_noise(args[2])

func run_unit(command, args, subject):
	if command == "delay":
		subject.action.delay = int(args[2])
	elif command == "action":
		subject.n_animation.stop(true)
		if subject.action.delay > 0:
			subject.n_animation.play(args[2], -1, 1/(subject.action.delay*.2))
		else:
			subject.n_animation.play(args[2])
	elif command == "cooldown":
		subject.action.cooldowns[args[2]] = G.vars.time + args[3]
	elif command == "-buff":
		subject.buffs.end(args[2])
	elif command == "req":
		stop = !subject.require_tags(args[2], args[3], args[4])
		if stop and subject == G.you.host:
			if args[2] == "element":
				G.msg(["Out of "+args[3]+"!"])
			elif args[2] == "tool":
				G.msg(["Requires "+args[3]+" tool!"])
			elif args[2] == "name":
				G.msg(["Requires ["+args[3].capitalize()+"]!"])
	elif command == "control":
		G.you.host.save_to_map = true
		subject.possess(G.you)
	elif command == "morph":
		var newunit = G.cmds([["make", args[2], subject.pos]])
		newunit.possess(subject.pilot)
		subject.remove()
		tgt = newunit
		return
	elif command == "move":
		if args.size() > 3:
			subject.relocate(args[2], args[3])
		else:
			subject.relocate(args[2])
	elif command == "toward":
		subject.relocate(subject.pos.get_adjacent(subject.pos.direction_to(args[2])))
	elif command == "take":
		for i in subject.inventory + subject.equipments + [subject.weapon]:
			if i != null and i.get("name") == args[2]:
				tgt = subject.auto_equip(i, false)
				return
	elif command == "give":
		if subject.dat.get("body") == "man":
			var item = args[2]
			if item != null:
				subject.auto_equip(item)
	elif command == "possess":
		subject.possess(get_arg(args, 2))

func get_arg(args, idx, default=null):
	if args.size() > idx:
		return args[idx]
	return default

func get_los(p):
	var tile
	while tile == null or tile.is_col(p):
		var x = G.rng.ir(0, G.camera.sight_range)
		var y = G.rng.ir(0, G.camera.sight_range_y)
		if G.rng.b():
			x = G.camera.sight_range + 1
		else:
			y = G.camera.sight_range_y + 1
		if G.rng.b():
			x *= -1
			y *= -1
		tile = G.world.get_tile(G.you.host.pos.get_x() + x, G.you.host.pos.get_y() + y)
	return tile

func get_rand_pos(p):
	var tile
	while tile == null or tile.is_col(p):
		tile = G.world.get_tile(G.rng.ir(0, G.world.size-1), G.rng.ir(0, G.world.size-1))
	return tile
