extends Node


func check(p):
	if G.vars.setting.tips and !(p in G.vars.tips):
		var text = G.data.vars.tips.get(p)
		if text != null:
			yield(G.get_tree().create_timer(1.0), "timeout")
			G.ui.popup_confirm("TUTORIAL", text, null)
			G.vars.tips.append(p)
