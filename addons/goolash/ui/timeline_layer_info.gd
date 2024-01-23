@tool
extends Panel

const IconVisibilityVisible = preload("res://addons/goolash/icons/GuiVisibilityVisible.svg")
const IconVisibilityHidden = preload("res://addons/goolash/icons/GuiVisibilityHidden.svg")

var node

@export var style_normal := StyleBoxEmpty.new()
@export var style_active: StyleBoxFlat

func init(layer):
	self.layer = layer
	GoolashEditor.editor.editing_layer_changed.connect(_on_goolash_editing_layer_changed)
	%LineEditName.text = str(layer.name)
	set_visibility(layer.visible)
	update_style()


func _on_goolash_editing_layer_changed():
	if not is_instance_valid(node):
		GoolashEditor.editor.editing_layer_changed.disconnect(_on_goolash_editing_layer_changed)
		return
	update_style()


func update_style():
	var active := false
	if node is BrushLayer2D:
		active = GoolashEditor.editor.get_editing_layer_num() == node.layer_num
	else:
		active = EditorInterface.get_selection().get_selected_nodes()[0] == node
	add_theme_stylebox_override("panel", style_active if active else style_normal)


func _on_line_edit_name_text_submitted(new_text):
	%LineEditName.release_focus()


func _on_line_edit_name_focus_exited():
	node.name = %LineEditName.text


func _on_button_visible_toggled(toggled_on):
	set_visibility(not toggled_on)


func set_visibility(value: bool):
	%ButtonVisible.button_pressed = not value
	%ButtonVisible.icon = IconVisibilityVisible if value else IconVisibilityHidden
	node.visible = value


func _on_line_edit_name_focus_entered():
	EditorInterface.inspect_object(null)
	EditorInterface.inspect_object(node)


func _on_button_delete_pressed():
	if node is BrushLayer2D:
		GoolashEditor.editor.remove_layer(node)
