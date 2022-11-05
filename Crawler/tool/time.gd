extends Node

var frame
var s
var seconds
var second
var half_second
var quarter_second
var quarter_seconds
var ambient_light = 2
var sun_light = 3

func _process(delta):
	increment_seconds(delta)
	if quarter_second:
		G.world.turn.process_frames += 1
		if second and s % 4 == 0:
			G.vars.time += 1
			for i in range(G.world.turn.expirees.size()-1,-1,-1):
				var expiree = G.world.turn.expirees[i]
				if expiree[1] <= G.vars.time:
					G.world.turn.expirees.remove(i)
					var onrun = expiree[0].get("onexpire")
					if onrun != null:
						expiree[0].d("onexpire")
						G.cmds(onrun, expiree[0])
			for i in range(G.world.turn.timees.size()-1,-1,-1):
				var timee = G.world.turn.timees[i]
				if timee[2] >= timee[1]:
					var onrun = timee[0].get("ontime")
					if onrun != null:
						G.cmds(onrun, timee[0])
					timee[2] = 0
				else:
					timee[2] += 1
			if int(G.vars.time) % 60 == 0:
				on_hour_change()
	G.world.turn.on_process()
	for i in range(G.events.size()-1,-1,-1):
		var event = G.events[i]
		event[0] -= delta
		if event[0] <= 0:
			if typeof(event[1]) == 17:
				event[1].call_funcv(event[2])
			else:
				G.cmds(event[1], event[2][0], event[2][1])
			G.events.remove(i)

func reset():
	second = false
	half_second = false
	quarter_second = false
	s = 0
	frame = 0
	seconds = 0
	quarter_seconds = 0

func increment_seconds(delta):
	frame += delta
	second = false
	half_second = false
	quarter_second = false
	if frame >= .125:
		s += 1
		frame = frame - .125
		quarter_seconds = quarter_seconds + 1
		quarter_second = true
		if quarter_seconds == 2:
			half_second = true
		elif quarter_seconds == 4:
			half_second = true
			second = true
			seconds += 1
			quarter_seconds = 0

func get_days():
	return int(G.vars.time / 1440)

func get_hour():
	return int(G.vars.time / 60) % 24

func get_minutes():
	return int(G.vars.time) % 60

func is_daytime(hour=null):
	if hour == null:
		hour = get_hour()
	return hour > 6 and hour < 20

func on_light_change():
	var new_sunlight = sun_light
	var hour = get_hour()
	if is_daytime(hour):
		ambient_light = 2
		new_sunlight = 3
	else:
		ambient_light = 0
		if hour < 5 or hour > 22:
			new_sunlight = 1
		else:
			new_sunlight = 2
	if new_sunlight != sun_light:
		sun_light = new_sunlight
		G.you.view_dirty = 2

func to_text():
	var hour = G.time.get_hour()
	var minutes = G.time.get_minutes()
	if minutes < 10:
		minutes = "0" + str(minutes)
	else:
		minutes = str(minutes)
	return str(hour) + ":" + minutes

func on_hour_change():
	for hourby in G.world.turn.hourbys:
		hourby.on_sleep(1)
	on_light_change()
