var item_type = "tag"
var host
var v
var m

func _init(_dict, phost=null):
	host = phost
	v = {}
	for key in _dict:
		var value = _dict[key]
		if value is Dictionary or value is Array:
			v[key] = value.duplicate()
		else:
			v[key] = value
	if !v.empty():
		var name = v.get("name")
		if name != null:
			m = {"name": name}
		else:
			m = {}

func get_display_name():
	var r = get("name_", get("name")).capitalize()
	var amount = get("amount", 0)
	if amount > 0:
		return r + " ("+str(amount)+")"
	return r

func run(script):
	var onrun = get(script)
	if onrun != null:
		G.cmds(onrun, self)
		return true

func get(key, default=null):
	if key in m:
		return m[key]
	if key in v:
		return v[key]
	return default

func geti(key, default=null):
	var r = get(key, default)
	if r == null:
		return r
	return int(r)

func getc(key, default=null):
	var r = get(key, default)
	if r == null:
		return r
	return r.capitalize()

func keys():
	return get_combined().keys()

func a(key, val):
	var orig = get(key)
	if orig == null or orig != val:
		m[key] = val
		dirty(2)

func d(key):
	if !m.erase(key):
		m[key] = null
	dirty(2)

func swap(key1, key2):
	var v1 = get(key1)
	var v2 = get(key2)
	a(key1, v2)
	a(key2, v1)
	dirty(2)

func add(key, val, pmin=null, pmax=null):
	if val != null:
		if key in m:
			m[key] += val
		else:
			var origval = get(key)
			if origval != null:
				m[key] = val + origval
			else:
				m[key] = val
		dirty(2)
	if pmin != null:
		m[key] = max(m[key], pmin)
	if pmax != null:
		m[key] = min(m[key], pmax)
	return m[key]

func mult(key, val):
	if val != null:
		if key in m:
			m[key] *= val
		else:
			var origval = get(key)
			if origval != null:
				m[key] = val * origval
		dirty(2)
	return m[key]

func combine(_dict):
	for key in _dict:
		a(key, _dict[key])

func get_combined():
	var r = {}
	for key in v:
		r[key] = v[key]
	for key in m:
		r[key] = m[key]
	return r

func get_health():
	var vit = get("durability", 999)
	if vit <= 0:
		return 0
	var hurt = get("damage", 0)
	return 1 - (hurt / vit)

func untake(pos):
	var item = G.factory.make_item(get("name"), pos)
	item.dat.m = m

func dirty(p):
	if is_instance_valid(host):
		if host.dat != self:
			var eidx = host.equipments.find(self)
			if eidx != -1:
				host.add_dirty(10+eidx)
			else:
				var iidx = host.inventory.find(self)
				if iidx != -1:
					host.add_dirty(100+iidx)
		else:
			host.add_dirty(p)

func use(p=1, msg=null):
	var r = get("uses")
	if r == null:
		return true
	var diff = r - p
	if diff <= 0:
		if host == G.you.host:
			G.msg(["Out of uses."])
		run("onused")
		if diff == 0:
			m["uses"] = diff
			return true
		if msg != null:
			G.msg([msg])
		return false
	m["uses"] = diff
	return true

func remove():
	if is_instance_valid(host):
		if host.dat == self:
			host.remove()
		else:
			host.auto_equip(self, false)
		host = null
	on_remove()

func expired():
	var expire = get("expire")
	if expire == null:
		return false
	return G.vars.time > expire

func on_change(p):
	if p == 2:
		var expire = get("expire")
		if expire == null:
			G.world.turn.remove_expiree(self)
		elif expire < 0:
			expire = G.vars.time + -expire
			m["expire"] = expire
			G.world.turn.add_expiree([self, expire])
		var turns = get("turns")
		if turns != null:
			G.world.turn.add_timee([self, turns, 0])
		else:
			G.world.turn.remove_timee(self)
	elif p == 1:
		if get("onmake") != null:
			G.add_event(0, funcref(self, "run"), ["onmake"])
		var expire = get("expire")
		if expire != null:
			G.world.turn.add_expiree([self, expire])

func on_remove():
	G.world.turn.remove_expiree(self)
	G.world.turn.remove_timee(self)
