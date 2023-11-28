@tool
extends Button

var color: Color

func set_color(color: Color):
	self.color = color
	modulate = color


func _on_pressed():
	GoolashEditor.editor.current_color = color
	GoolashEditor.hud._update_color_picker_color()
