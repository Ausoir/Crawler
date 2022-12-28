extends "res://entity/pilot.gd"

onready var n_cursor = $Cursor
onready var n_movement = $Movement

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
		if G.camera.set_sight(host.dat.geti("perception", 4)+1, host.dat.geti("sight", 1), "nocturnal" in host.tags):
			G.camera.start_process()
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

func on_die():
	G.cmds([["custom","return",null]])

func make_money(p):
	G.vars.money = G.vars.money+p
	if p >= 0:
		G.display_damage("+"+G.L.str_money(p), host.pos, Color.gold, 1, 250)
	else:
		G.display_damage("-"+G.L.str_money(p), host.pos, Color.indigo, 1, 250)

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
		make_noise(1)
		G.ui.update_hud()
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
			if item.dat.get("part") != null:
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
	host.save_to_map = true
	var player_data = host.serialize(end)
	if !end:
		G.you.host.save_to_map = false
	return [to_json(G.vars), to_json(player_data)]

func unserialize(_data):
	var player_pos
	if "pos" in _data:
		player_pos = G.world.get_tile(_data.pos[0], _data.pos[1])
	else:
		player_pos = G.world.get_spawn_point()
	var player_unit = G.factory.make_unit(_data.name, player_pos, _data)
	player_unit.possess(self)
	set_ai(["idle"])
	make_money(0)

func check_brightness(p):
	if p == null:
		return true
	var brightness = host.pos.light
	if "nocturnal" in host.tags:
		brightness += 1
	if brightness < 3:
		if p:
			G.msg(["Too dark!"])
			return false
	elif !p:
		G.msg(["Too bright!"])
		return false
	return true
