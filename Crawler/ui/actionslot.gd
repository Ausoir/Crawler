extends Panel

const MODE_NORMAL = 0
const MODE_SELECTED = 1
const MODE_COOLDOWN = 2
const MODE_ACTIVE = 3

onready var overlay = $Overlay
onready var label = $Label
var mode = MODE_NORMAL
var skill_index: int
var stylebox = get_stylebox("panel", "")
var skill
var skill_data
var skill_type
var skill_description

func set_mode(p):
	if p == 3:
		overlay.hide()
		stylebox.texture = G.data.get_image("gui/skillslot_use")
	elif p == 2:
		overlay.hide()
		stylebox.texture = G.data.get_image("gui/skillslot_disabled")
	elif p == 1:
		overlay.show()
		stylebox.texture = G.data.get_image("gui/skillslot")
	else:
		overlay.hide()
		stylebox.texture = G.data.get_image("gui/skillslot")
	mode = p

func assign(p):
	skill = p[0]
	var type = p[1]
	if type == "skill":
		skill_data = p[2]
		skill_type = skill_data.get("target")
		skill_description = skill_data.get("desc")
		$Sprite.texture = G.data.get_image(skill_data.get("img", "gui/sk_hand"))
	elif type == "item":
		skill_data = p[0]
		skill_type = "item"
		skill_description = skill.get("desc")
		$Sprite.texture = G.data.get_image(skill_data.get("img", "gui/sk_hand"))
	elif type == "object": #outdated
		skill_data = G.data.item_data.get(p)
		skill_type = "object"
		skill_description = skill.dat.get("desc")
		if skill.item_type == "unit":
			$Sprite.texture = skill.n_sprite.texture
		else:
			$Sprite.texture = skill.texture
			$Sprite.set_region(true)
			$Sprite.set_region_rect(Rect2(0, 0, 32, 32))

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			_on_mouse_entered()
		else:
			_on_mouse_exited()
			if G.ui.last_touch_time < .25:
				activate()

func activate():
	if mode == MODE_NORMAL:
		G.ui.unselect_skills()
		if skill_type == "self":
			G.you.host.action.next_action = ["ability", skill_index, G.you.host.pos]
		elif skill_type == "item":
			var action = skill.get("aim")
			if action != null:
				set_mode(MODE_SELECTED)
				G.you.aim_ability(-2)
				G.you.on_point = [skill.get("onuse"), skill, action.get("col", 14), action.get("range", G.C), action.get("target", 1)]
			else:
				G.you.host.action.next_action = ["command", skill.get("onuse"), skill, G.you.host.pos]
		elif G.vars.setting.autoaim and skill_data.get("trigger") == 2:
			var tgt = G.you.closest_enemy
			if tgt != null and tgt.pos.distance_to(G.you.host.pos) <= skill_data.get("range", 1):
				G.you.host.action.next_action = ["ability", skill_index, tgt.pos]
		else:
			set_mode(MODE_SELECTED)
			G.you.aim_ability(skill_index)
	elif mode == MODE_SELECTED:
		if skill_type != "self":
			set_mode(MODE_NORMAL)
			G.you.stop_aim()
	elif mode == MODE_ACTIVE:
		G.you.host.action.next_action = ["ability", skill_index, G.you.host.pos]
	G.ui.description.hide()

func _update_cooldown(cd):
	if cd > 0:
		label.set_text(str(cd))
		if mode != MODE_COOLDOWN:
			set_mode(MODE_COOLDOWN)
			set_modulate(Color.webgray)
	elif mode != MODE_NORMAL:
		label.set_text("")
		set_mode(MODE_NORMAL)
		set_modulate(Color.white)

func _on_mouse_entered():
	if skill_type == "item":
		if skill != null and is_instance_valid(skill):
			G.ui.describe("$" + skill.get("name"))
	else:
		G.ui.describe("%" + skill)

func _on_mouse_exited():
	G.ui.description.hide()

