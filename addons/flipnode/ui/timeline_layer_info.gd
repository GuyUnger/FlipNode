@tool
extends Panel

const IconVisibilityVisible = preload("res://addons/flipnode/icons/GuiVisibilityVisible.svg")
const IconVisibilityHidden = preload("res://addons/flipnode/icons/GuiVisibilityHidden.svg")

var type := Timeline.TYPE_LAYER
var layer: Layer2D

@export var style_normal := StyleBoxEmpty.new()
@export var style_active: StyleBoxFlat


func init(layer, type):
	self.layer = layer
	Flip.editor.selected_layer_changed.connect(_on_selected_layer_changed)
	%LineEditName.text = str(layer.name)
	set_visibility(layer.visible)
	update_style()


func _on_selected_layer_changed():
	if not is_instance_valid(layer):
		Flip.editor.selected_layer_changed.disconnect(_on_selected_layer_changed)
		return
	update_style()


func update_style():
	add_theme_stylebox_override(
			"panel",
			style_active if Flip.editor.get_selected_layer() == layer else
			style_normal
	)


func _on_line_edit_name_text_submitted(new_text):
	%LineEditName.release_focus()


func _on_line_edit_name_focus_exited():
	layer.name = %LineEditName.text


func _on_button_visible_toggled(toggled_on):
	set_visibility(not toggled_on)


func set_visibility(value: bool):
	%ButtonVisible.button_pressed = not value
	%ButtonVisible.icon = IconVisibilityVisible if value else IconVisibilityHidden
	layer.visible = value


func _on_line_edit_name_focus_entered():
	EditorInterface.inspect_object(null)
	EditorInterface.inspect_object(layer)


func _on_button_delete_pressed():
	Flip.editor.remove_layer(layer)


func _on_button_mouse_exited():
	%EditCover.visible = true


func _on_edit_cover_button_down():
	Flip.editor.timeline.start_drag(self)


func _on_edit_cover_pressed():
	%EditCover.visible = false
