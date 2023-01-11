extends Control

onready var title = $Panel/Control/Title
onready var content = $Panel/Control/Content
var callback

func reposition():
	set_size(G.ui.screen_size)
	$Panel.rect_size.x = 0 #reset size after long descriptions etc
	$Panel.rect_size.y = 0
	$Panel.rect_position.x = G.ui.screen_size.x/2 - $Panel.rect_size.x/2
	$Panel.rect_position.y = G.ui.screen_size.y/2 - $Panel.rect_size.y/2

func display(header, context, cb):
	if cb != null:
		callback = cb
		context += "\n[right][url=cb][img=32]" + cb[0] + "[/img][/url][/right]"
	on_display(header, context)

func on_display(header, desc):
	title.set_text(header.capitalize())
	content.set_bbcode(desc)
	show()
	reposition()

func _on_meta_clicked(meta):
	if meta == "cb":
		callback[1].call_funcv(callback[2])
