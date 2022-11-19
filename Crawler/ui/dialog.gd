extends Control

onready var n_text = $"Dialog/RichTextLabel"
var page_data
var host
var params

func display(_page, _host, _params=[]):
	params = _params
	if _page[0] == ">":
		show()
		run_script(_page.substr(1))
	else:
		var data = G.data.dialog_data.get(_page)
		if data != null:
			display_data(data, _host)

func display_data(_data, _host):
	page_data = _data
	host = _host
	var cmd = page_data.get("cmd")
	if cmd != null:
		G.cmds(cmd, host)
	var title = page_data.get("title")
	if title != null:
		G.ui.dialog.set_tab_title(0, title)
		var text
		var req_met = true
		var req = page_data.get("req")
		if req != null:
			req_met = is_req_met(req)
		if req_met:
			text = page_data.get("true", "")
		else:
			text = page_data.get("false", "")
		text = text.replace("$u", G.game.player_name)
		n_text.set_bbcode(text)
		show()
	var script = page_data.get("script")
	if script != null:
		run_script(script)

func run_script(script):
	page_data["opt"] = []
	G.rng.set_seed(G.vars.seed + int(G.vars.time/60))
	if script == "trade":
		add_trade()
	elif script == "vend":
		add_vend(page_data.get("type"), page_data.get("amount", 1))

func is_req_met(reqs):
	for req in reqs:
		if !check_supplies(req[0], req[1]):
			return false
	return true

func check_supplies(item, amount):
	for supply in G.vars.supplies:
		if supply == item:
			amount -= 1
			if amount <= 0:
				return true
	return false

func _on_meta_clicked(meta):
	G.ui.clear()
	var opts = page_data.get("opt", [])
	if opts.size() > int(meta):
		var option = page_data.opt[int(meta)]
		var req = option.get("req")
		if req != null:
			if !is_req_met(req):
				return
		var cmd = option.get("cmd")
		if cmd != null:
			G.cmds(cmd, host)
		var script = option.get("script")
		if script != null:
			run_script(script)

func _on_meta_hover_started(meta):
	var opts = page_data.get("opt", [])
	if opts.size() > int(meta):
		var option = page_data.opt[int(meta)]
		var hover = option.get("hover")
		if hover != null:
			if hover[0] == "text":
				G.ui.describe("text", hover[1], hover[2])
			elif hover[0] == "item":
				var item = G.data.item_data.get(hover[1])
				if item != null:
					G.ui.describe("item", hover[1], item)

func _on_meta_hover_ended(_meta):
	G.ui.description.hide()

func add_vend(type, amount):
	G.ui.display(0)
	var items = ""
	var count = 0
	G.rng.set_seed(host.get("seed",0))
	for _i in range(amount):
		var groups = G.data.get_group(type)
		for group in groups:
			var item_name = group[0]
			var price = int(group[1] / 25) * 25 + 100
			items += "[url="+str(count)+"]> [i]Buy " + item_name + " for "+G.L.str_money(price)+"[/i][/url]\n"
			count += 1
			var option = {"hover": ["item", item_name],
						"cmd": [["onstop","Not enough money..."],["money",-price],["make",item_name],["give","$p","$t"]]}
			page_data.opt.append(option)
	n_text.append_bbcode(items)

func add_trade():
	G.ui.display(0)
	G.rng.set_seed(host.get("seed",0))
	var cha = G.you.host.dat.get("charisma", 1) * .1
	var items = ""
	var count = 0
	var groups = []
	var hh = host.host
	for i in hh.inventory + hh.equipments + [hh.weapon]:
		if i != null:
			groups.append([i.get("name"), G.Mat.get_value_of(i), i])
	for group in groups:
		var item_name = group[0]
		var price = int(group[1] * (G.rng.f() + .7 - cha) / 50) * 50 + 100
		items += "[url="+str(count)+"]> [i]Buy " + item_name + " for "+G.L.str_money(price)+"[/i][/url]\n"
		count += 1
		var option = {"hover": ["item", item_name],
					"cmd": [["onstop","Not enough money..."],["money",-price],["take",hh,item_name],["give","$p","$t"]]}
		page_data.opt.append(option)
	n_text.append_bbcode(items)
