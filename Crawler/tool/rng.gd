extends Node

var init_seed

func set_seed(_seed=-1):
	if _seed == -1:
		randomize()
		_seed = randi()
	init_seed = _seed
	seed(init_seed)

func ir(_from, _to):
	var diff = int(_to - _from + 1)
	if diff == 0:
		return _from
	return randi() % diff + _from

func fr(_from, _to):
	var diff = _to - _from
	if diff == 0:
		return _from
	return randf() * diff + _from

func vfr(diff):
	return Vector2(fr(-diff, diff), fr(-diff, diff))

func f():
	return randf()

func i():
	return randi()

func r_arr(arr):
	if arr and !arr.empty():
		return arr[ir(0, len(arr)-1)]
	return null

func r_arr_pop(arr):
	if arr and !arr.empty():
		var idx = ir(0, len(arr)-1)
		var r = arr[idx]
		arr.remove(idx)
		return r

func r_range(p):
	return ir(p[0], p[1])

func b():
	return ir(0, 1) == 1

func r_percent(p):
	return f() < p

func r_dice(times, dice):
	var r = 0
	for _i in range(times):
		r += ir(1, dice)
	return r

func r_pie(slices):
	var distribution = []
	var avg: float = 0
	for _i in range(slices):
		var t = G.rng.fr(0, 1)
		avg += t
		distribution.append(t)
	for i in range(slices):
		distribution[i] /= avg
		distribution[i] /= 1.0/slices
	return distribution
