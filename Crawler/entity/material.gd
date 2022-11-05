static func get_material(_host):
	var _matname = _host.get("mat", "other")
	var r = G.data.vars.material.get(_matname)
	if r == null:
		return G.data.vars.material.get("other")
	return r

static func get_durability_of(_host):
	var hdur = _host.get("durability")
	if hdur != null:
		return hdur
	else:
		var _dat = get_material(_host)
		var dur = _dat.get("durability", 1)
		var size = _host.get("size", 1)
		return dur * .5 + size * dur

static func get_value_of(_host):
	var _dat = get_material(_host)
	var value = _host.get("value", 0)
	var size = _host.get("size", 1)
	var r = int(_dat.get("value", 1) * size)
	return r + value

static func get_armor_of(_host):
	var _dat = get_material(_host)
	var harmor = _host.get("armor")
	if harmor != null:
		return harmor
	else:
		return _dat.get("armor", 0)

static func get_resistance_of(_host):
	var _dat = get_material(_host)
	var harmor = _host.get("resistance")
	if harmor != null:
		return harmor
	else:
		return _dat.get("resistance", 0)

static func get_weight_of(_host):
	var _dat = get_material(_host)
	var size = _host.get("size", -1)
	if size == -1:
		return 0
	var r = int(_dat.get("weight", 0) * size * 100)
	return r / 100.0

static func get_broken_quote(_host):
	var _dat = get_material(_host)
	return _dat.get("break", "Broken")

static func make_step_sound_of(dat, at):
	var _dat = get_material(dat)
	var sfx = _dat.get("sfx_step", "steps/dirt")
	if sfx != null:
		G.sfx.play(sfx, at)

static func make_hit_sound(_host):
	var _dat = get_material(_host.dat)
	var sfx = _dat.get("sfx_hit")
	if sfx != null:
		G.sfx.play(sfx, _host.pos)

static func make_die_sound(_host):
	var _dat = get_material(_host.dat)
	var sfx = _dat.get("sfx_die")
	if sfx != null:
		G.sfx.play(sfx, _host.pos)

static func make_hit_effect(_host):
	var _dat = get_material(_host.dat)
	var gfx = _dat.get("gfx_hit")
	if gfx != null:
		G.make_particle(gfx, _host.pos)

static func on_die(host):
	make_die_sound(host)
	var dat = get_material(host.dat)
	var loot = dat.get("loot")
	var hloot = host.dat.get("loot")
	if hloot != null:
		if !hloot.empty():
			G.factory.make_any(hloot, host.pos)
	elif loot != null:
		var sz = host.dat.get("size", 1)
		sz = int(sz * G.rng.ir(10, 50)) / 100.0
		if sz >= .1:
			var mat = G.factory.make_any(loot, host.pos)
			if mat != null:
				mat.dat.a("size", sz)
