extends RichTextLabel


func get_stats_text(dict):
	var txt = ""
	for i in G.data.vars.stats:
		var stat = G.data.vars.stats[i].name
		var val = dict.get(stat)
		if val != null:
			txt += "[color=#A64][url=*"+i+"]"+stat.capitalize()+"[/url][/color]: "+str(val)+"\n"
	return txt

func get_traits_text(dict):
	var txt = ""
	for trait in dict:
		txt += "[color=#AA4][url=&"+trait+"]"+trait.capitalize()+"[/url][/color]\n"
	return txt

func _on_meta_hover_started(meta):
	on_describe(meta)

func on_describe(meta):
	var abname = meta.substr(1)
	if meta[0] == "*":
		for key in G.data.vars.stats:
			if abname == key:
				var v = G.data.vars.stats[key]
				G.ui.describe("text", v.name, v.desc)
	elif meta[0] == "&":
		for key in G.data.vars.traits:
			if abname == key:
				G.ui.describe("trait", abname.capitalize(), G.data.vars.traits.get(abname))
	else:
		G.ui.describe("text", meta.capitalize(), G.data.vars.desc.get(meta))

func _on_meta_hover_ended(_meta):
	G.ui.description.hide()

func _on_meta_clicked(meta):
	on_describe(meta)
