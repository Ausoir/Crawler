extends RichTextLabel

func refresh():
	var txt2 = ""
	txt2 += "[color=#A64][url=autofight]Autofight "+str(G.vars.setting.autofight)+"[/url][/color]\n"
	txt2 += "[color=#A64][url=autoaim]Autoaim "+str(G.vars.setting.autoaim)+"[/url][/color]\n"
	txt2 += "[color=#A64][url=autofire]Autofire "+str(G.vars.setting.autofire)+"[/url][/color]\n"
	txt2 += "[color=#A64][url=smoothcam]Smooth Camera "+str(G.vars.setting.smoothcam)+"[/url][/color]\n"
	txt2 += "[color=#A64][url=landscape]Landscape Mode "+str(G.vars.setting.landscape)+"[/url][/color]\n"
	txt2 += "[color=#A64][url=fps]Show FPS: "+str(G.vars.setting.showfps)+"[/url][/color]\n"
	txt2 += "[color=#A64]Sound[/color]: [url=sound]"+G.vars.setting.sound.capitalize()+"[/url]\n"
	txt2 += "[color=#A64][url=retire]Retire[/url][/color]\n"
	txt2 += "[color=#942][url=exit]Exit Game[/url][/color]\n"
	set_bbcode(txt2)

func _on_meta_clicked(meta):
	if meta == "autofight":
		G.vars.setting.autofight = !G.vars.setting.autofight
		refresh()
	elif meta == "autoaim":
		G.vars.setting.autoaim = !G.vars.setting.autoaim
		refresh()
	elif meta == "autofire":
		G.vars.setting.autofire = !G.vars.setting.autofire
		refresh()
		G.ui.update_hud()
	elif meta == "landscape":
		G.vars.setting.landscape = !G.vars.setting.landscape
		if G.vars.setting.landscape:
			OS.set_screen_orientation(OS.SCREEN_ORIENTATION_LANDSCAPE)
		else:
			OS.set_screen_orientation(OS.SCREEN_ORIENTATION_PORTRAIT)
	elif meta == "smoothcam":
		G.vars.setting.smoothcam = !G.vars.setting.smoothcam
	elif meta == "fps":
		G.vars.setting.showfps = !G.vars.setting.showfps
		refresh()
		if G.vars.setting.showfps:
			G.ui.n_fps.show()
		else:
			G.ui.n_fps.hide()
	elif meta == "sound":
		if G.vars.setting.sound == "low":
			G.vars.setting.sound = "normal"
		elif G.vars.setting.sound == "normal":
			G.vars.setting.sound = "high"
		elif G.vars.setting.sound == "high":
			G.vars.setting.sound = "off"
		elif G.vars.setting.sound == "off":
			G.vars.setting.sound = "low"
		G.sfx.adjust_sound()
		refresh()
	elif meta == "retire":
		G.cmds([["menu","confirm","Abandon character and start over?",[["^=","dead",true],["fn",funcref(G.game, "abandon_game"),[]]]]])
	elif meta == "exit":
		G.cmds([["menu","confirm","Exit game?",[["fn",funcref(G.game, "end_game"),[]]]]])
