@tool
extends Button

func set_color(color: Color):
	modulate = color


func _on_pressed():
	GoolashEditor.editor.current_color = modulate
	GoolashEditor.hud._update_color_picker_color()
