@tool
extends HBoxContainer

var layer: BrushClipLayer

func init(layer):
	self.layer = layer
	%LineEditName.text = str(layer.name)

func _on_line_edit_name_text_submitted(new_text):
	%LineEditName.release_focus()


func _on_line_edit_name_focus_exited():
	layer.name = %LineEditName.text
