
extends CanvasLayer

const ActionSlot = preload("res://ui/ActionSlot.tscn")
const BuffSlot = preload("res://ui/BuffSlot.tscn")
onready var menu = $Control/Menu
onready var prompt = $Control/AcceptDialog
onready var confirm = $Control/ConfirmDialog
onready var dialog = $Control/Dialog
onready var message = $Control/Message
onready var tint = $Control/Tint
onready var description = $Control/Description
onready var abilities = $Control/Abilities
onready var buffs = $Control/Status
onready var n_fps = $FPS
var last_touch_time = 0
var prompt_cmd
var screen_size
var mouse_pos = Vector2()
var on = false

func _ready():
	screen_size = get_viewport().get_size_override()
	$AnimationPlayer/Fade.set_size(screen_size)
	fadein()
	tint.get_stylebox("panel", "").set_bg_color(Color(0,0,0, .7))

func colorize(p):
	$AnimationPlayer/Fade.color = Color(p)

func fadein():
	$AnimationPlayer.play("FadeIn")

func _process(_delta):
	last_touch_time += _delta
	if G.vars.setting.showfps:
		n_fps.set_text(str(Engine.get_frames_per_second())+' FPS')

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = get_viewport().get_mouse_position()
		menu._on_mouse_move()
	elif event is InputEventMouseButton:
		if event.is_pressed():
			last_touch_time = 0

func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("quit"):
			G.game.end_game()
		elif Input.is_action_just_pressed("restart"):
			G.script("start menu", null)
		elif Input.is_action_just_pressed("ui_fullscreen"):
			OS.window_fullscreen = !OS.window_fullscreen
		elif Input.is_action_just_pressed("quick_1"):
			if on:
				menu.tabs.set_current_tab(0)
			elif abilities.get_child_count() > 0:
				abilities.get_children()[0].activate()
		elif Input.is_action_just_pressed("quick_2"):
			if on:
				menu.tabs.set_current_tab(1)
			elif abilities.get_child_count() > 1:
				abilities.get_children()[1].activate()
		elif Input.is_action_just_pressed("quick_3"):
			if on:
				menu.tabs.set_current_tab(2)
			elif abilities.get_child_count() > 2:
				abilities.get_children()[2].activate()
		elif Input.is_action_just_pressed("quick_4"):
			if on:
				menu.tabs.set_current_tab(3)
			elif abilities.get_child_count() > 3:
				abilities.get_children()[3].activate()
		elif Input.is_action_just_pressed("quick_5"):
			if on:
				menu.tabs.set_current_tab(4)
			elif abilities.get_child_count() > 4:
				abilities.get_children()[4].activate()
		elif G.you.host != null:
			if Input.is_action_just_pressed("menu"):
				if on:
					clear()
				else:
					G.cmds([["menu", "pickup", -1]], G.you.host)
			else:
				G.you._on_input(event)
	elif !on:
		G.you._on_input(event)

func display_dialog(_page, _host, _params=[]):
	tint.set_size(screen_size)
	tint.show()
	dialog.display(_page, _host, _params)
	dialog.rect_position = screen_size / 2 - dialog.rect_size / 2
	menu.hide()
	on = true

func display(_arg):
	if !on:
		on = true
		G.you.unhandled_input = false
		tint.set_size(screen_size)
		tint.show()
		menu.display(_arg)

func clear():
	on = false
	menu.clear()
	tint.hide()
	description.hide()
	dialog.hide()

func unselect_skills():
	for child in abilities.get_children():
		if !(child is RichTextLabel):
			if child.mode == 1:
				child.set_mode(0)

func describe(type, header, subject):
	if !description.visible:
		if header != null and subject != null:
			description.display(type, header, subject)

func update_hud():
	abilities.rect_position.y = screen_size.y - 60
	for child in abilities.get_children():
		child.queue_free()
		abilities.remove_child(child)
	var count = 0
	var ab = []
	for i in G.you.host.abilities:
		var trigger = i.get("trigger", 0)
		if trigger == 1 or (trigger == 2 and !G.vars.setting.autofire) or i.name in G.you.host.action.cooldowns:
			ab.append([i.name, "skill", i, count])
		count += 1
	count = 0
	if G.you.host.dat.get("body") == "man":
		ab += G.you.host.get_usable_items()
	for i in ab:
		var newslot = ActionSlot.instance()
		newslot.assign(i)
		if i[1] == "skill":
			newslot.skill_index = i[3]
		abilities.add_child(newslot)
		if newslot.skill_type == "self" and G.you.host.buffs.has(i[0]):
			newslot.set_mode(3)
		elif G.you.aiming == count:
			newslot.set_mode(1)
		else:
			newslot.set_mode(0)
		count += 1
	buffs.rect_position.x = screen_size.x - 48
	for i in buffs.get_children():
		i.queue_free()
		buffs.remove_child(i)
	for i in G.you.host.buffs.states:
		var buff = G.you.host.buffs.states[i]
		var slot = BuffSlot.instance()
		slot.assign(i, buff)
		buffs.add_child(slot)

func _update_cooldowns(cds):
	var delete_abilities = []
	var cchecked = []
	var checked = []
	for ability in abilities.get_children():
		if ability.skill in cds:
			cchecked.append(ability)
			ability._update_cooldown(cds[ability.skill] - G.vars.time)
		else:
			ability._update_cooldown(0)
			var trigger = ability.skill_data.get("trigger", 0)
			if trigger == 2 and G.vars.setting.autofire:
				delete_abilities.append(ability)
	for i in delete_abilities:
		i.queue_free()
		abilities.remove_child(i)
	var state = G.you.host.buffs.states
	for i in range(buffs.get_child_count()-1, -1, -1):
		var child = buffs.get_child(i)
		if child.buff.skill.name in state:
			checked.append(child.buff)
			var time = child.buff.duration
			if time == -1:
				child.label.set_text("")
			else:
				child.label.set_text(str(time - G.vars.time))
		else:
			child.queue_free()
			buffs.remove_child(child)
	if checked.size() < state.size() or cchecked.size() < cds.size():
		update_hud()

func popup_confirm(text, onconfirm):
	confirm.make(text, onconfirm)
	confirm.show()

func popup_prompt(title, callback):
	prompt.window_title = title
	prompt_cmd = callback
	prompt.show()

func _on_prompt_confirmed():
	G.cmds(prompt_cmd, G.you.host, prompt.get_node("Text").text)
