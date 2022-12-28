extends ConfirmationDialog

const SIZE = Vector2(480, 320)
var onconfirm

func make(text, p):
	set_text(text)
	onconfirm = p
	popup_centered_clamped(SIZE)

func _on_confirmed():
	hide()
	G.cmds(onconfirm, G.command.prev_host)
