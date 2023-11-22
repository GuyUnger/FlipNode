@tool
@icon("res://addons/goulash/icons/BrushLayer2D.svg")
class_name BrushLayer2D
extends Node2D

@export var frame_count: int = 0

@export var locked := false
var keyframes: Array

var current_visible_frame

@export var layer_num := 0

func _ready():
	show_behind_parent = true
	find_keyframes()
	for keyframe in keyframes:
		keyframe.visible = false
	display_frame(0)


func find_keyframes():
	keyframes = []
	for child in get_children():
		if child is BrushKeyframe2D:
			child.modulate = Color.WHITE
			child.z_index = 0
			keyframes.push_back(child)


func display_frame(frame_num):
	if Engine.is_editor_hint():
		var onion_skin_frames := 0
		if GoulashEditor.onion_skin_enabled and not get_clip().is_playing and GoulashEditor.editor.editing_brush == get_clip():
			onion_skin_frames = GoulashEditor.onion_skin_frames
		for frame in keyframes:
			if frame.frame_num == frame_num:
				frame.visible = true
				frame.modulate = Color.WHITE
				current_visible_frame = frame
				frame.z_index = 0
			elif onion_skin_frames > 0:
				var distance: float = abs(frame.frame_num - frame_num)
				frame.visible = distance <= onion_skin_frames
				if frame.visible:
					var alpha = (1.0 - ((distance - 1) / onion_skin_frames)) * 0.4 + 0.1
					frame.modulate = Color(1.0, 1.0, 1.0, alpha)
					frame.z_index = -1
			else:
				frame.visible = false
		return
	
	if current_visible_frame:
		current_visible_frame.visible = false
	
	current_visible_frame = get_frame(frame_num)
	current_visible_frame.visible = true

#func draw():
	#for keyframe_data in keyframes:
		#var keyframe = BrushKeyframe2D.new()
		#add_child(keyframe)
		#keyframe.owner = owner
		#keyframe.name = "Frame %s" % keyframe_data.frame_num


func get_frame(frame_num: int) -> BrushKeyframe2D:
	if frame_num > frame_count:
		return null
	for i in keyframes.size():
		if keyframes[i].frame_num == frame_num:
			return keyframes[i]
		elif keyframes[i].frame_num > frame_num:
			return keyframes[i - 1]
	return null


func get_keyframe(frame_num: int):
	for i in keyframes.size():
		if keyframes[i].frame_num == frame_num:
			return keyframes[i]
		elif keyframes[i].frame_num > frame_num:
			break
	return null


func set_keyframe(keyframe: BrushKeyframe2D, frame_num: int):
	var occupied_keyframe = get_keyframe(frame_num)
	if occupied_keyframe:
		remove_child(occupied_keyframe)
	
	add_child(keyframe)
	keyframe.owner = owner
	keyframe.frame_num = frame_num
	keyframe.name = "Frame %s" % frame_num
	
	frame_count = max(frame_count, frame_num + 1)
	
	keyframes.push_back(keyframe)
	keyframes.sort_custom(_compare_keyframes)


func _compare_keyframes(a: BrushKeyframe2D, b: BrushKeyframe2D):
	return a.frame_num < b.frame_num


func is_frame_empty(frame_num):
	for frame in keyframes:
		if frame.frame_num == frame_num:
			return false
	return true


func get_clip() -> BrushClip2D:
	return get_parent()


class LayerTransformKeyframe:
	var frame: int
	var transform: Transform2D
