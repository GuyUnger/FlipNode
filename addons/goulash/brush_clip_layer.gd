@tool
class_name BrushClipLayer extends Resource

@export var name := "Layer"

@export var keyframes: Array
@export var transform_frames: Array

@export var frame_count: int = 0

@export var visible := true
@export var locked := false

func _init():
	set_keyframe(Keyframe.new(), 0)


func get_shapes(frame_num: int) -> Array:
	if frame_num >= frame_count:
		return []
	return get_frame(frame_num).shapes


func get_frame(frame_num: int) -> Keyframe:
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


func set_keyframe(frame: Keyframe, frame_num: int):
	var current_keyframe = get_keyframe(frame_num)
	if current_keyframe != null:
		keyframes.erase(current_keyframe)
	frame.layer = self
	
	frame.frame_num = frame_num
	frame_count = max(frame_count, frame_num + 1)
	
	keyframes.push_back(frame)
	keyframes.sort_custom(_compare_keyframes)


func _compare_keyframes(a: Keyframe, b: Keyframe):
	return a.frame_num < b.frame_num


func is_frame_empty(frame_num):
	for frame in keyframes:
		if frame.frame_num == frame_num:
			return false
	return true


class LayerTransformKeyframe:
	var frame: int
	var transform: Transform2D
