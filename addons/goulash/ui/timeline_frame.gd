@tool
extends Control

const KeyframeSymbol = preload("res://addons/goulash/icons/keyframe.svg")
const KeyframeEmptySymbol = preload("res://addons/goulash/icons/keyframe_empty.svg")

var keyframe: BrushKeyframe2D

func draw(keyframe: BrushKeyframe2D, i: int):
	self.keyframe = keyframe
	check_blank()
	%Label.text = keyframe.label
	keyframe.edited.connect(_on_keyframe_edited)

func _on_keyframe_edited():
	check_blank()


func _on_pressed():
	EditorInterface.inspect_object(null)
	EditorInterface.inspect_object(keyframe)
	keyframe.get_clip().goto(keyframe.frame_num)
	GoulashEditor.editor._selected_layer_id = keyframe.get_layer().layer_num

func check_blank():
	var is_blank = keyframe.is_blank()
	%Symbol.texture = KeyframeEmptySymbol if is_blank else KeyframeSymbol
	modulate = Color.DIM_GRAY if is_blank else Color.WHITE
