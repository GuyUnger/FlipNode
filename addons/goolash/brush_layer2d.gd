@tool
@icon("res://addons/goolash/icons/BrushLayer2D.svg")
class_name BrushLayer2D
extends Node2D

signal edited

@export var frame_count: int = 0

@export var locked := false
@export var keyframes: Array

var current_visible_frame: BrushKeyframe2D

@export var layer_num := 0

@export var tweenframes := []
@export var tweenframes_baked: Array[Transform2D]

enum {TWEENFRAME_TRANSFORM, TWEENFRAME_FRAMENUM}


func _ready():
	if GoolashEditor.is_editor_hint():
		update_keyframe_endpoints()
		bake_tweenframes()
		find_keyframes()
	else:
		find_keyframes()
		set_process(false)


func _process(delta):
	if get_clip().is_playing:
		return
	for tweenframe in tweenframes:
		if tweenframe.frame_num == get_clip().current_frame:
			if tweenframe.transform != transform:
				tweenframe.transform = transform
				bake_tweenframes()


func find_keyframes():
	keyframes = []
	for child in get_children():
		if child is BrushKeyframe2D:
			child.modulate = Color.WHITE
			child.z_index = 0
			keyframes.push_back(child)


#TODO: name this something more general about cleaning up stuff
func update_keyframe_endpoints():
	keyframes.sort_custom(_compare_keyframes)
	for i in keyframes.size():
		move_child(keyframes[i], i)
		var keyframe = keyframes[i]
		if i == keyframes.size() - 1:
			keyframe.frame_end_num = frame_count - 1
		else:
			keyframe.frame_end_num = keyframes[i + 1].frame_num - 1
	
	if tweenframes_baked.size() != frame_count:
		bake_tweenframes()


func display_frame(frame_num):
	transform = tweenframes_baked[min(frame_num, frame_count-1)]
	if GoolashEditor.is_editor_hint():
		var onion_skin_frames := 0
		if (
				GoolashEditor.onion_skin_enabled and
				not get_clip().is_playing and
				GoolashEditor.editor.editing_node == get_clip() and
				GoolashEditor.is_editable(get_clip())
		):
			onion_skin_frames = GoolashEditor.onion_skin_frames
		
		for frame in keyframes:
			if frame_num >= frame.frame_num and frame_num <= frame.frame_end_num:
				frame.visible = true
				frame.modulate = Color.WHITE
				current_visible_frame = frame
				frame.z_index = 0
			elif onion_skin_frames > 0:
				var distance: float
				
				var clip := get_clip()
				
				distance = min(
						abs(frame.frame_num - frame_num),
						abs(frame.frame_end_num - frame_num)
					)
				if clip.looping:
					distance = min(
							distance,
							abs(frame.frame_num - clip.frame_count - frame_num),
							abs(frame.frame_num + clip.frame_count - frame_num),
							abs(frame.frame_end_num - clip.frame_count - frame_num),
							abs(frame.frame_end_num + clip.frame_count - frame_num)
						)
				
				frame.visible = distance <= onion_skin_frames
				if frame.visible:
					var alpha = (1.0 - ((distance - 1) / onion_skin_frames)) * 0.4 + 0.1
					frame.modulate = Color(1.0, 1.0, 1.0, alpha)
					frame.z_index = -1
			else:
				frame.visible = false
		return
	
	var visible_frame = get_frame(frame_num)
	if visible_frame == current_visible_frame:
		return
	
	if current_visible_frame:
		current_visible_frame.visible = false
	
	if visible_frame:
		current_visible_frame = visible_frame
		visible_frame.visible = true
		visible_frame.enter()


func get_frame(frame_num: int) -> BrushKeyframe2D:
	if frame_num > frame_count - 1:
		return null
	for i in keyframes.size():
		if keyframes[i].frame_end_num >= frame_num:
			return keyframes[i]
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
	update_keyframe_endpoints()
	edited.emit()


func insert_frame(frame_num: int):
	frame_count += 1
	for keyframe in keyframes:
		if keyframe.frame_num > frame_num:
			keyframe.frame_num += 1
	update_keyframe_endpoints()
	edited.emit()


func remove_frame(frame_num: int):
	if frame_num > frame_count:
		return
	if frame_count == 1:
		get_keyframe(0).clear()
	frame_count -= 1
	for keyframe in keyframes:
		if keyframe.frame_num == frame_num and keyframe.frame_end_num == frame_num:
			remove_child(keyframe)
		elif keyframe.frame_num > frame_num:
			keyframe.frame_num -= 1
	find_keyframes()
	update_keyframe_endpoints()
	edited.emit()


func remove_keyframe(frame_num: int):
	var frame = get_keyframe(frame_num)
	if frame:
		remove_child(frame)
	find_keyframes()
	update_keyframe_endpoints()
	edited.emit()


func _compare_keyframes(a: BrushKeyframe2D, b: BrushKeyframe2D):
	return a.frame_num < b.frame_num


func is_keyframe(frame_num):
	for frame in keyframes:
		if frame.frame_num == frame_num:
			return true
	return false


func bake_tweenframes():
	tweenframes_baked.resize(frame_count)
	
	if tweenframes.size() <= 0:
		## If there are no keyframes, fill it up with new Transforms,
		## if there is 1, fill it up with that one.
		var tween_transform: Transform2D = (
				Transform2D()
			if tweenframes.size() == 0 else
				tweenframes[0]
			)
		for i in frame_count:
			tweenframes_baked[i] = tween_transform
		return
	
	for frame_num in frame_count:
		var from: Tweenframe
		var to: Tweenframe
		
		## Find the keyframe from and keyframe to.
		for keyframe in tweenframes:
			to = keyframe
			## If the keyframe is past the current frame_num, we have set the 'to' in the prev line,
			## and the 'from' in the last cycle, break here.
			## If this is the first cycle, 'from' will not be set (frame is before first keyframe).
			if keyframe.frame_num > frame_num:
				break
			from = keyframe
			## If this is the last keyframe, there will not be another cycle
			## and keyframe_from and keyframe_to will be the same value
		
		## Assign transforms
		if not from or from == to:
			## As established before, if there is no 'from', this is before the first keyframe;
			## if 'from' and 'to' are the same, the is past the last keyframe.
			## Either way the correct transform will be stored in 'to'.
			tweenframes_baked[frame_num] = to.transform
		else:
			## Both 'from' and 'to' are found, interpolate between them.
			var t = from.ease_t((frame_num - from.frame_num) / float(to.frame_num - from.frame_num))
			tweenframes_baked[frame_num] = from.transform.interpolate_with(to.transform, t)
	
	
	for frame_num in frame_count:
		var from: Tweenframe
		var to: Tweenframe
		for keyframe in tweenframes:
			to = keyframe
			if keyframe.frame_num > frame_num:
				break
			from = keyframe
		if not from or from == to:
			tweenframes_baked[frame_num] = to.transform
		else:
			var t = from.ease_t((frame_num - from.frame_num) / float(to.frame_num - from.frame_num))
			tweenframes_baked[frame_num] = from.transform.interpolate_with(to.transform, t)


func get_clip() -> BrushAnimation2D:
	var parent = get_parent()
	if parent is BrushAnimation2D:
		return parent
	return null


class LayerTransformKeyframe:
	var frame: int
	var transform: Transform2D
