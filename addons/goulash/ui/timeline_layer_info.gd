@tool
extends HBoxContainer

const IconVisibilityVisible = preload("res://addons/goulash/icons/GuiVisibilityVisible.svg")
const IconVisibilityHidden = preload("res://addons/goulash/icons/GuiVisibilityHidden.svg")

var layer: BrushLayer2D

func init(layer):
	self.layer = layer
	%LineEditName.text = str(layer.name)
	set_visibility(layer.visible)

func _on_line_edit_name_text_submitted(new_text):
	%LineEditName.release_focus()


func _on_line_edit_name_focus_exited():
	layer.name = %LineEditName.text


func _on_button_visible_toggled(toggled_on):
	set_visibility(not toggled_on)

func set_visibility(value):
	%ButtonVisible.button_pressed = not value
	%ButtonVisible.icon = IconVisibilityVisible if value else IconVisibilityHidden
	layer.visible = value
	
