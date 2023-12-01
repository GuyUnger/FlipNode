@tool
extends Control

const KeyframeSymbol = preload("res://addons/goolash/icons/keyframe.svg")
const KeyframeBlankSymbol = preload("res://addons/goolash/icons/keyframe_blank.svg")

var keyframe: BrushKeyframe2D

@export var style_filled: StyleBoxFlat
@export var style_blank: StyleBoxFlat


func init(keyframe: BrushKeyframe2D):
	self.keyframe = keyframe
	keyframe.edited.connect(_on_keyframe_edited)
	draw()


func _on_keyframe_edited():
	call_deferred("draw")


func draw():
	await get_tree().process_frame
	var is_blank = keyframe.is_blank()
	%Symbol.texture = KeyframeBlankSymbol if is_blank else KeyframeSymbol
	%Symbol.modulate = Color.WEB_GRAY if is_blank else Color.WHITE
	add_theme_stylebox_override("normal", style_blank if is_blank else style_filled)
	
	%Label.visible = keyframe.label != ""
	%Label.text = keyframe.label
	size.x = (keyframe.frame_end_num - keyframe.frame_num + 1) * Timeline.FRAME_WIDTH
	
	%Script.visible = keyframe.has_custom_script


func _on_pressed():
	EditorInterface.inspect_object(null)
	GoolashEditor.editor.set_editing_layer_num(keyframe.get_layer().layer_num)
	GoolashEditor.editor.selected_keyframe = keyframe
	EditorInterface.inspect_object(keyframe)
