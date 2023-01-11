extends Node

const W = 32
const H = 32
const HW = 16
const HH = 16
const TILE_VECTOR = Vector2(32, 32)
const AUTOTILE_COORD = [Vector2(0,0),Vector2(0,3*H),Vector2(W,0),Vector2(W,3*H),Vector2(0,H),Vector2(0,2*H),Vector2(W,H),Vector2(W,2*H),Vector2(3*W,0),Vector2(3*W,3*H),Vector2(2*W,0),Vector2(2*W,3*H),Vector2(3*W,H),Vector2(3*W,2*H),Vector2(2*W,H),Vector2(2*W,2*H)]
const V = 1024
const C = 17
const CH = 3
const CARDINALS = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
const CARDINAL_ROTATIONS = [0, PI/2, PI, -PI/2]
const DIRS = [Vector2.UP,Vector2(1,-1),Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1)]
const UP = 0
const UPRIGHT = 1
const RIGHT = 2
const DOWNRIGHT = 3
const DOWN = 4
const DOWNLEFT = 5
const LEFT = 6
const UPLEFT = 7

const Damage_Label = preload("res://fx/particles/Damage_Label.tscn")
const Gfx = preload("res://fx/Gfx.tscn")
const Mat = preload("res://entity/material.gd")
const L = preload("res://tool/lang.gd")
const Prep = preload("res://ui/explore/Preparation.tscn")
var rng = preload("res://tool/rng.gd").new()
var game = preload("res://tool/gamestate.gd").new()
var sfx
var fx = preload("res://tool/fx.gd").new()
var data = preload("res://tool/json.gd").new()
var time
var factory = preload("res://tool/factory.gd").new()
var world
var census
var ui
var custom = preload("res://tool/custom.gd").new()
var command = preload("res://tool/command.gd").new()
var desc = preload("res://tool/description.gd").new()
var events
var vars
var you
var camera
var generator
var healthbars

func _ready():
	vars = {}
	time = preload("res://tool/time.gd").new()
	sfx = preload("res://fx/Sfx.tscn").instance()
	world = preload("res://world/World.tscn").instance()
	census = preload("res://world/census.gd").new()
	ui = preload("res://ui/Interface.tscn").instance()
	you = preload("res://view/Player.tscn").instance()
	camera = preload("res://view/Camera.tscn").instance()
	generator = preload("res://world/generator.gd").new()
	healthbars = preload("res://tool/healthbars.gd").new()
	events = []
	add_child(camera)
	get_tree().get_root().call_deferred("add_child", ui)
	time.reset()
	add_child(time)
	add_child(healthbars)
	camera.set_process(false)
	time.set_process(false)

func vec_to_tile(vec):
	var x = floor(vec.x / W)
	var y = floor(vec.y / H)
	if G.world.is_inbound(x, y):
		return G.world.get_tile(x, y)

func vec_to_pos(vec):
	return Vector2(vec.x/W, vec.y/H).floor()

func str_to_tile(p):
	var split = p.split(",")
	var chunk = G.world.get_chunk_from_coord(int(split[2]), int(split[3]))
	if chunk != null:
		var x = int(split[0])
		var y = int(split[1])
		return chunk.get_tile(x, y)

func pos_to_vec(x, y):
	return Vector2(x*W+HW, y*H+HH)

func vector_to_dir(x, y):
	var count = 0
	for i in DIRS:
		if i[0] == x and i[1] == y:
			return count
		count += 1
	return -1

func get_dir_to_cardinal_string(p):
	var t = p % 4
	if t == 0:
		return "north"
	elif t == 1:
		return "east"
	elif t == 2:
		return "south"
	elif t == 3:
		return "west"

func make_particle(arg, pos, args=null, force=false):
	if (force and camera.is_pos_in_range(pos)) or pos.visible:
		var r = data.get_particle(arg)
		r.position = pos.position
		r.add()
		if args != null:
			r.run_details(args)
		return r

func display_damage(val, pos, color=Color.white, _scale=1, _speed=800, lifetime=200):
	if pos.visible:
		var r = Damage_Label.instance()
		r.lifetime = lifetime
		r.position = pos.position
		r.position.y -= HH
		world.others.add_child(r)
		r.set_damage(str(val), color, _scale, _speed)

func cmds(args, host=null, ptgt=null):
	if ptgt != null:
		command.tgt = ptgt
	for arg in args:
		if command.stop:
			if arg == null:
				command.stop = false
		elif arg != null:
			cmd(arg, host)
	command.onstop = null
	command.stop = false
	return command.tgt

func cmd(arg, host=null):
	command.tgt = command.run(arg, host)
	command.prev = arg

func script(p, param):
	return custom.run(p, param)

func msg(msgs):
	var r = join(msgs, " , ")
	ui.message.add(r)

func join(arr, delimiter):
	var r = ""
	for i in arr:
		r += str(i) + delimiter
	if !r.empty():
		r = r.substr(0, r.length() - 1 - (delimiter.length() - 1))
	return r

func add_event(countdown, newevent, params=[]):
	events.append([countdown, newevent, params])

func unserialize_target(p):
	if p != null:
		var tile = G.world.get_tile(p[0], p[1])
		if p.size() == 2:
			return tile
		else:
			for i in tile.items:
				if i.item_name == p[2]:
					return i

func diff_to_dir(diffx, diffy):
	if abs(diffx) > abs(diffy):
		if diffx < 0:
			return 6
		elif diffx > 0:
			return 2
	elif diffy < 0:
		return 0
	elif diffy > 0:
		return 4
	return -1
