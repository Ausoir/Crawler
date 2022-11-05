extends "res://entity/pilot.gd"

const MAX_HUNGER = 1440.0

onready var n_cursor = $Cursor
onready var n_movement = $Movement

var skills = preload("res://view/skills.gd").new()
var aiming = -1
var view_dirty = 0
var unhandled_input = false
var on_point
var touch_position = Vector2()
var drag_position = Vector2()
var last_touch_time = 0
var last_drag_dist = 0
var touch_events = {}

func on_change(p):
	.on_change(p)
	if p == 2:
		if G.camera.set_sight(host.dat.geti("perception", 1)+1, host.dat.geti("sight", 1), "nocturnal" in host.traits):
			G.camera.start_process()
		if host.dat.get("body") != null:
			G.ui.menu.update_equipables(host.bodyparts)
			G.ui.menu.update_equipment()
			G.ui.menu.update_inventory()
		else:
			G.ui.menu.update_equipables({})
		for i in host.abilities:
			G.you.add_topic(i.name)
		G.ui.update_hud()

func on_assign():
	.on_assign()
	host.save_to_map = false
	G.camera.target = host
	G.camera.set_process(true)
	on_change(2)

func on_kill(_victim):
	var money = G.rng.ir(0, _victim.dat.get("value", 0))
	if money > 0:
		make_money(money)
	add_topic(_victim.dat.get("topic"))

func on_die():
	G.cmds([["custom","return",null]])

func on_hit(hitter):
	if is_instance_valid(hitter) and hitter != host:
		if task.target != hitter and hitter.team == host.team*-1:
			skills.gain_xp("dodging", 0.01)

func make_money(p):
	G.vars.money = G.vars.money+p
	if p >= 0:
		G.display_damage("+"+G.L.str_money(p), host.pos, Color.gold, 1, 250)
	else:
		G.display_damage("-"+G.L.str_money(p), host.pos, Color.indigo, 1, 250)

func add_topic(p):
	if p != null and !(p in G.vars.topic):
		G.vars.topic.append(p)

func get_mouse():
	var screen_mouse = G.ui.mouse_pos
	screen_mouse -= G.ui.screen_size / 2
	return Vector2(screen_mouse.x*G.camera.zoom.x + G.camera.position.x,
				screen_mouse.y*G.camera.zoom.y + G.camera.position.y)

func zoom(new_zoom):
	new_zoom = clamp(G.camera.zoom.x * new_zoom, .5, 2)
	G.camera.zoom = Vector2.ONE * new_zoom

func _on_input(event: InputEvent):
	if event is InputEventScreenDrag:
		if unhandled_input:
			touch_events[event.index] = event
			if touch_events.size() == 2:
				var drag_distance = touch_events[0].position.distance_to(touch_events[1].position)
				if abs(drag_distance - last_drag_dist) > 10:
					var new_zoom = .95
					if drag_distance < last_drag_dist:
						new_zoom = 1.05
					zoom(new_zoom)
					last_drag_dist = drag_distance
			elif aiming != -1:
				var mpos = G.vec_to_pos(get_mouse())
				n_cursor.position = G.pos_to_vec(mpos.x, mpos.y)
				n_cursor.show()
			else:
				drag_position = event.position - touch_position
	elif event is InputEventMouseButton:
		G.ui.description.hide()
		if Input.is_action_just_released("use"):
			touch_events.clear()
			n_movement.hide()
			drag_position = Vector2.ZERO
			if unhandled_input:
				var mtile = G.vec_to_pos(get_mouse())
				var tile = G.world.get_tile_clamped(mtile.x, mtile.y)
				if aiming != -1:
					if aiming == -2 and on_point != null:
						tile = host.pos.get_beam_to(tile, int(on_point[2]), on_point[3])[on_point[4]]
						host.action.next_action = ["command", on_point[0], on_point[1], tile]
						on_point = null
					else:
						host.action.next_action = ["ability", aiming, tile]
					stop_aim()
				elif G.ui.last_touch_time < .15 and (tile.visible or "antennae" in host.traits):
					G.ui.describe("tile", tile.item_name.capitalize(), tile)
				else:
					host.action.next_action = null
			unhandled_input = false
		elif Input.is_action_just_pressed("use"):
			unhandled_input = true
			if aiming == -1:
				touch_position = event.position
				if last_touch_time < .3 and host.action.delay == 0:
					if !interact(host.pos):
						if host.pos.icon == '>':
							G.custom.run("movez", [1])
						elif host.pos.icon == '<':
							G.custom.run("movez", [-1])
						else:
							G.cmds([["menu", "menu", -1]], host)
				else:
					n_movement.show()
					n_movement.position = event.position
				last_touch_time = 0
			else:
				var mpos = G.vec_to_pos(event.position)
				n_cursor.position = G.pos_to_vec(mpos.x, mpos.y)
				n_cursor.show()
		elif Input.is_action_just_pressed("zoom in"):
			zoom(.9)
		elif Input.is_action_just_pressed("zoom out"):
			zoom(1.1)

func _physics_process(_delta):
	last_touch_time += _delta
	if host.action.delay == 0:
		var keydir = -1
		if Input.is_action_pressed("move_up"):
			keydir = G.UP
		elif Input.is_action_pressed("move_down"):
			keydir = G.DOWN
		elif Input.is_action_pressed("move_right"):
			keydir = G.RIGHT
		elif Input.is_action_pressed("move_left"):
			keydir = G.LEFT
		if aiming == -1:
			if unhandled_input and Input.is_action_pressed("use"):
				var dir = G.diff_to_dir(drag_position.x, drag_position.y)
				if dir != -1 and max(abs(drag_position.x), abs(drag_position.y)) > 20:
					host.action.next_action = ["slide", dir]
				else:
					host.action.next_action = null
					if G.ui.last_touch_time > .25 and !G.ui.on:
						var mtile = G.vec_to_pos(get_mouse())
						var tile = G.world.get_tile_clamped(mtile.x, mtile.y)
						if tile.distance_to(host.pos) == 1:
							host.action.next_action = ["roll_ability", "onattack", tile]
							for i in tile.items:
								if i.team == host.team and i.item_type == "unit":
									host.action.next_action = null
									i.dat.run("ontalk")
									n_movement.hide()
									break
			elif keydir != -1:
				host.action.next_action = ["slide", keydir]
			elif host.action.next_action != null and host.action.next_action[0] == "slide":
				host.action.next_action = null

func on_turn():
	var prev_closest_enemy = closest_enemy
	perceive()
	if prev_closest_enemy != closest_enemy and G.vars.setting.autoaim and G.vars.setting.autofire:
		if is_instance_valid(closest_enemy):
			G.make_particle("Mark", closest_enemy.pos)
	if host.prev_pos != host.pos:
		view_dirty -= 1
		G.camera.start_process()
		G.world.turn.process_light()
		host.prev_pos = host.pos
		if G.ui.on:
			G.cmds([["menu", "pickup", -1]], host)
		make_noise(1)
	else:
		if host.action.delay == 0:
			if host.action.next_action == null:
				var cards = host.pos.get_cardinals(1)
				for tile in cards:
					for item in tile.items:
						if item.item_type == "unit" and item.team == host.team:
							item.action.delay = max(item.action.delay, 2)
				if closest_enemy != null:
					var autoed = false
					if G.vars.setting.autofire and closest_enemy != null:
						autoed = perform_ability(closest_enemy)
					if !autoed and G.vars.setting.autofight:
						if host.pos.difference_to(closest_enemy.pos) == 1:
							var dir = host.pos.direction_to(closest_enemy.pos)
							host.action.next_action = ["slide", dir]
	G.ui._update_cooldowns(host.action.cooldowns)

func interact(tile):
	if !G.ui.on:
		var corpses = []
		for item in tile.items:
			if host.can_carry(item.dat):
				G.ui.menu.search_inventory(tile)
				return true
			elif item.item_type == "corpse":
				corpses.append(item)
		for item in tile.items:
			if use(item):
				return true

func use(item):
	if item != host:
		var oninteract = item.dat.get("oninteract")
		if oninteract != null:
			G.cmds(oninteract, item.dat, host)
			return true

func aim_ability(idx):
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	aiming = idx

func stop_aim():
	n_cursor.hide()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	aiming = -1
	G.ui.update_hud()

func remove():
	pass

func serialize(end=false):
	G.vars.skills = skills.skills
	if G.vars.get("dead", false) == true:
		return []
	elif G.you.host != null:
		host.save_to_map = true
		var player_data = host.serialize(end)
		if !end:
			G.you.host.save_to_map = false
		return [to_json(G.vars), to_json(player_data)]

func unserialize(_data):
	var player_pos = G.world.get_tile(1, 1)
	var player_unit = G.factory.make_unit(_data.name, player_pos, _data)
	player_unit.possess(self)
	set_ai(["idle"])
	make_money(0)
	skills.unserialize(G.vars.skills)
	if "traits" in G.vars:
		for i in G.vars.traits:
			host.add_trait(i, true)
		G.vars.erase("traits")

func check_brightness(p):
	if p == null:
		return true
	var brightness = host.pos.light
	if "nocturnal" in host.traits:
		brightness += 1
	if brightness < 3:
		if p:
			G.msg(["Too dark!"])
			return false
	elif !p:
		G.msg(["Too bright!"])
		return false
	return true

func sleep(time, sleep=true):
	var possible = true
	if G.vars.time + time >= G.vars.hunger:
		possible = false
		G.msg(["Too hungry..."])
	for foe in G.census.get_foe(host):
		if foe.pos.distance_to(host.pos) <= G.C:
			if foe.item_type == "unit" and host.pos.get_beam_to(foe.pos, 8)[1] == foe.pos:
				possible = false
				G.msg(["Too dangerous!"])
				break
	if possible and sleep:
		G.vars.time += time * 60
		G.ui.fadein()
		host.action.delay = 16
		host.n_animation.play("wait")
	return possible

func on_sleep(_time):
	if "undead" in host.traits:
		G.vars.hunger = G.vars.time
	var hunger = G.vars.hunger
	if G.vars.time > hunger and !eat():
		if G.vars.time > hunger + MAX_HUNGER*3:
			G.fx.do(G.data.ability_data.get("starvation"), host)
		else:
			G.fx.do(G.data.ability_data.get("hunger"), host)
	G.game.save_game(false)

func eat():
	var food = host.get_available_tags("tool", "food")
	if !food.empty():
		food.run("oneat")
		return true
	if "carnivore" in host.traits:
		var corpse = host.get_available_tags("name", "corpse")
		corpse.run("oneat")
		return true

func perform_ability(enemy):
	.perform_ability(enemy)
	if host.next_action != null and host.next_action[0] == "ability":
		var idx = host.next_action[1]
		if idx < host.abilities.size():
			var ability = host.abilities[idx]
			if ability.get("trigger", 0) == 2 and ability.get("target") == "beam":
				skills.gain_xp("aiming", 1)
