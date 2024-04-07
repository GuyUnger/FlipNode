@tool
extends Button

@export var is_default := false

func _ready():
	if is_default:
		tooltip_text = name.capitalize()


func set_color(color: Color):
	self_modulate = color


func _on_pressed():
	Flip.editor.current_color = self_modulate
	Flip.editor._update_color_picker_color()
