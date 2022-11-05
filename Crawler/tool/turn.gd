extends Node


var takers = [[],[],[],[],[]]
var light_sources = []
var timees = []
var expirees = []
var hourbys = []
var add_idx = 0
var turn_idx = 0
var process_frames = 0

func clear():
	takers = [[],[],[],[],[]]

func increment_index(idx):
	idx += 1
	if idx >= len(takers):
		idx = 0
	return idx

func has(p):
	for i in takers:
		if p in i:
			return true
	return false

func add(p):
	if !has(p):
		takers[add_idx].append(p)
		add_idx = increment_index(add_idx)

func remove(p):
	for i in takers:
		var index = i.find(p)
		if index != -1:
			i.remove(index)
			return index

func on_process():
	if process_frames > 0:
		for i in takers[turn_idx]:
			i.on_turn()
		turn_idx = increment_index(turn_idx)
		if turn_idx == 0:
			process_frames -= 1

func add_light(obj):
	if !(obj in light_sources):
		light_sources.append(obj)

func add_timee(obj):
	for i in range(timees.size()):
		var timed = timees[i]
		if timed[0] == obj[0]:
			timed[1] = obj[1]
			return
	timees.append(obj)

func remove_timee(obj):
	for i in range(timees.size()):
		var timed = timees[i]
		if timed[0] == obj:
			timees.remove(i)
			return

func add_expiree(obj):
	for i in range(expirees.size()):
		var expir = expirees[i]
		if expir[0] == obj[0]:
			expir[1] = obj[1]
			return
	expirees.append(obj)

func remove_expiree(obj):
	for i in range(expirees.size()):
		var expir = expirees[i]
		if expir[0] == obj:
			expirees.remove(i)
			return

func process_light():
	for i in range(light_sources.size()-1, -1, -1):
		var obj = light_sources[i]
		if obj.light > obj.pos.get_default_light():
			if obj.pos.distance_to(G.camera.target.pos) <= G.camera.max_sight_x:
				obj.pos.set_light(obj.light)
				for flips in G.camera.OCTANT_FLIP:
					obj.cast_light(obj.light, 1, 1.0, 0.0, flips)
		else:
			light_sources.remove(i)
