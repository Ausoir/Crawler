var host
var states = {}
var in_turn = false
var disrupt_hit = false

class buff:
	var parent
	var skill
	var fx
	var duration
	var dest
	var cancelable
	var turns
	var turn = 0

	func _init(pparent,p1,p2,p3):
		parent = pparent
		skill = p1
		duration = p2
		dest = p3
		cancelable = p1.get("cancelable", false)
		turns = p1.get("turns", 0)
	
	func serialize(pname):
		var r = [pname, str(duration), null]
		if dest != null:
			if dest.item_type == "tile":
				r[2] = dest.to_array()
			else:
				r[2] = [dest.pos.get_x(), dest.pos.get_y(), dest.item_name]
		return r

	func on_turn(host):
		if duration != -1 and duration <= G.vars.time:
			parent.cancel(skill.name)
			return
		turn += 1
		if "onturn" in skill:
			if turn > turns:
				turn = 0
				G.fx.do(skill, host, dest, 1)

func _init(phost):
	host = phost

func serialize():
	var r = []
	for skillname in states:
		var skill = states[skillname]
		r.append(skill.serialize(skillname))
	return r

func unserialize(_data):
	for i in _data:
		var skill = G.data.ability_data.get(i[0])
		var dest = G.unserialize_target(i[2])
		states[i[0]] = buff.new(self, skill, int(i[1]), dest)
	if !_data.empty():
		G.world.turn.add(self)

func add(skill, duration, dest):
	var dur = G.vars.time + duration
	if duration == -1:
		dur = -1
	if skill.name in states:
		if states[skill.name].duration != -1:
			states[skill.name].duration = dur
	else:
		states[skill.name] = buff.new(self, skill, dur, dest)
		G.world.turn.add(self)

func has(p):
	return p in states

func cancel(p):
	var state = states.get(p)
	if state != null:
		states.erase(p)
		if "onend" in state.skill:
			G.fx.do(state.skill, host, state.dest, 2)
		if states.empty():
			G.world.turn.remove(self)

func on_turn():
	var keys = states.keys()
	for i in keys:
		var state = states[i]
		if disrupt_hit and state.cancelable:
			cancel(i)
		else:
			state.on_turn(host)
	disrupt_hit = false

func end(p):
	if p in states:
		states[p].duration = 0

func remove():
	states.clear()
	G.world.turn.remove(self)

func clear():
	for i in states:
		states[i].duration = 0
		states[i].on_turn(host)
	states.clear()
	G.world.turn.remove(self)
