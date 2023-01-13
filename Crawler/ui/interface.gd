extends CanvasLayer

const ActionSlot = preload("res://ui/ActionSlot.tscn")
const BuffSlot = preload("res://ui/BuffSlot.tscn")
onready var menu
onready var description = $Description
onready var abilities = $Control/Abilities
onready var buffs = $Control/Status
onready var n_fps = $FPS
var last_touch_time = 0
var prompt_cmd
var screen_size
var mouse_pos = Vector2()
var prev_buffs
var prev_abilities
var on = false
var disabled = false

func _ready():
	screen_size = get_viewport().get_size_override()
	$Animation/Fade.set_size(screen_size)
	fadein()

func disable(disable):
	disabled = disable
	G.ui.display_hud(!disable)

func colorize(p):
	$Animation/Fade.color = Color(p)

func fadein():
	$Animation.play("FadeIn")

func _process(_delta):
	last_touch_time += _delta
	if G.vars.setting.showfps:
		n_fps.set_text(str(Engine.get_frames_per_second())+' FPS')

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = get_viewport().get_mouse_position()
	elif event is InputEventMouseButton:
		if event.is_pressed():
			last_touch_time = 0
		else:
			description.hide()
	elif event is InputEventKey:
		if menu != null:
			menu.input_key()

func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("quit"):
			G.game.end_game()
		elif Input.is_action_just_pressed("restart"):
			G.script("start menu", null)
		elif Input.is_action_just_pressed("ui_fullscreen"):
			OS.window_fullscreen = !OS.window_fullscreen
		elif !disabled:
			if Input.is_action_just_pressed("quick_1"):
				if abilities.get_child_count() > 0:
					abilities.get_children()[0].activate()
			elif Input.is_action_just_pressed("quick_2"):
				if abilities.get_child_count() > 1:
					abilities.get_children()[1].activate()
			elif Input.is_action_just_pressed("quick_3"):
				if abilities.get_child_count() > 2:
					abilities.get_children()[2].activate()
			elif Input.is_action_just_pressed("quick_4"):
				if abilities.get_child_count() > 3:
					abilities.get_children()[3].activate()
			elif Input.is_action_just_pressed("quick_5"):
				if abilities.get_child_count() > 4:
					abilities.get_children()[4].activate()
			elif G.you.host != null:
				if Input.is_action_just_pressed("menu"):
					if on:
						clear()
					else:
						display(-1)
				else:
					G.you._on_input(event)
	elif !on and !disabled:
		G.you._on_input(event)

func display(_arg):
	if !on:
		on = true
		G.you.unhandled_input = false
		menu = G.Prep.instance()
		menu.ingame = _arg
		add_child_below_node($Control, menu)

func clear():
	on = false
	if menu != null:
		menu.queue_free()
		menu = null
	description.hide()

func unselect_skills():
	for child in abilities.get_children():
		if !(child is RichTextLabel):
			if child.mode == 1:
				child.set_mode(0)

func describe(header, content, callback=null):
	if !description.visible:
		description.display(header, content, callback)

func display_hud(show):
	if show:
		abilities.show()
		buffs.show()
	else:
		abilities.hide()
		buffs.hide()

func update_hud():
	var count = 0
	var ab = []
	for i in G.you.host.abilities:
		var trigger = i.get("trigger", 0)
		if trigger == 1 or (trigger == 2 and !G.vars.setting.autofire) or i.name in G.you.host.action.cooldowns:
			ab.append([i.name, "skill", i, count])
		count += 1
	ab += G.you.host.get_usable_items()
	var item = G.you.host.pos.get_pickup()
	if item != null:
		ab.append(["pickup", "skill", G.data.ability_data.get("pickup"), -1])
	if ab != prev_abilities:
		abilities.rect_position.y = screen_size.y - 60
		prev_abilities = ab
		for child in abilities.get_children():
			child.queue_free()
			abilities.remove_child(child)
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
	if G.you.host.buffs.states != prev_buffs:
		prev_buffs = G.you.host.buffs.states
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
	var cchecked = []
	var checked = []
	for ability in abilities.get_children():
		if ability.skill in cds:
			cchecked.append(ability)
			ability._update_cooldown(cds[ability.skill] - G.vars.time)
		else:
			ability._update_cooldown(0)
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

func popup_confirm(header, text, onconfirm):
	if onconfirm != null:
		describe(header, text, ["res://assets/images/gui/icon_ok.png", onconfirm, []])
	else:
		describe(header, text)
