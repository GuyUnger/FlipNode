@tool
@icon("res://addons/flipnode/icons/Layer2D.svg")
class_name Layer2D
extends Node2D

signal edited

@export var length: int = 1

var brushes: Array

var current_visible_brush: Brush2D

@export var transform_keys := []
@export var transform_keys_frames: Array[Transform2D]

@export var brush_frames: Array

enum {TWEENFRAME_TRANSFORM, TWEENFRAME_FRAMENUM}

var animation: BrushAnimation2D:
	get:
		return get_parent()


func _get_configuration_warnings():
	if not animation is BrushAnimation2D:
		return ["Layer2D only serves to group brushes into a layer for an BrushAnimation2D. Please only use it as a child of a BrushAnimation2D."]
	return []


func _ready():
	if Engine.is_editor_hint():
		find_brushes()
		bake()
	else:
		find_brushes()
		
		#TODO: this is temp
		bake()
		
		for brush in brushes:
			brush.visible = false
		display_frame(0)
		set_process(false)


func _process(delta):
	if animation.is_playing:
		return
	if Engine.is_editor_hint():
		# Record transformframes.
		for transform_key in transform_keys:
			if transform_key.frame_num == animation.current_frame:
				if transform_key.transform != transform:
					transform_key.transform = transform
					bake()


func find_brushes():
	brushes = []
	for child in get_children():
		if child is Brush2D:
			child.modulate = Color.WHITE
			child.z_index = 0
			brushes.push_back(child)


#TODO: name this something more general about cleaning up stuff
#func update_brush_endpoints():
	#keybrushes.sort_custom(_compare_keybrushes)
	#for i in keybrushes.size():
		#if keybrushes[i].get_parent():
			#move_child(keybrushes[i], i)
		#
		#var keybrush = keybrushes[i]
		#if i == keybrushes.size() - 1:
			#keybrush.brush_end_num = length - 1
		#else:
			#keybrush.brush_end_num = keybrushes[i + 1].frame_num - 1
	#
	#if tweenbrush_frames.size() != length:
		#bake_tweenbrushes()


func display_frame(frame: int):
	transform = transform_keys_frames[frame]
	if Engine.is_editor_hint() and Flip.editor:
		# Onion skinning.
		var onion_skin_frames := 0
		if (
				Flip.editor.onion_skin_enabled
				and not animation.is_playing
				and Flip.editor.editing_animation == animation
				and Flip.is_node_editable(animation)
		):
			onion_skin_frames = Flip.editor.onion_skin_frames
		
		for brush in brushes:
			if frame >= brush.frame_num and frame <= get_brush_end_frame(brush):
				brush.visible = true
				brush.modulate = Color.WHITE
				current_visible_brush = brush
				brush.z_index = 0
			elif onion_skin_frames > 0:
				var distance: float
				
				distance = min(
						abs(brush.frame_num - frame),
						abs(get_brush_end_frame(brush) - frame)
					)
				if animation.looping:
					distance = min(
							distance,
							abs(brush.frame_num - animation.length - frame),
							abs(brush.frame_num + animation.length - frame),
							abs(get_brush_end_frame(brush) - animation.length - frame),
							abs(get_brush_end_frame(brush) + animation.length - frame)
						)
				
				brush.visible = distance <= onion_skin_frames
				if brush.visible:
					var alpha = (1.0 - ((distance - 1) / onion_skin_frames)) * 0.4 + 0.1
					brush.modulate = Color(1.0, 1.0, 1.0, alpha)
					brush.z_index = -1
			else:
				brush.visible = false
		return
	
	var visible_brush = get_brush(frame)
	if visible_brush == current_visible_brush:
		return
	
	if current_visible_brush:
		current_visible_brush.visible = false
	
	if visible_brush:
		current_visible_brush = visible_brush
		visible_brush.visible = true
		visible_brush._enter()


func get_brush(frame: int) -> Brush2D:
	return get_node(brush_frames[clamp(frame, 0, length - 1)])


#func get_keybrush(frame_num: int):
	#for i in keybrushes.size():
		#if keybrushes[i].frame_num == frame_num:
			#return keybrushes[i]
		#elif keybrushes[i].frame_num > frame_num:
			#break
	#return null


func set_brush(brush: Brush2D, frame: int):
	var occupied_brush = get_brush(frame)
	if occupied_brush and occupied_brush.frame_num == frame:
		remove_child(occupied_brush)
	add_child(brush)
	brush.owner = owner
	brush.frame_num = frame
	brush.set_animation_name()
	length = max(length, frame + 1)
	
	brushes.push_back(brush)
	bake()
	animation._update_end_frame()
	edited.emit()


func insert_frame(frame: int):
	length += 1
	for brush in brushes:
		if brush.frame_num > frame:
			brush.frame_num += 1
	bake()
	edited.emit()


func remove_brush(frame: int):
	if frame > length:
		return
	length -= 1
	
	var brush = get_brush(frame)
	remove_child(brush)
	
	for i in range(brushes.find(brush), brushes.size()):
		brushes[i].frame_num -= 1
	
	find_brushes()
	bake()
	
	animation._update_end_frame()
	edited.emit()


#func remove_brush(frame: int):
	#var brush = get_keybrush(frame)
	#if brush:
		#remove_child(brush)
	#find_brushes()
	#bake_brushes()
	#edited.emit()


func _compare_brushes(a: Brush2D, b: Brush2D):
	return a.frame_num < b.frame_num


func is_brush_start(frame: int):
	return get_brush(frame).frame_num == frame
	#for brush in brushes:
		#if brush.frame_num == frame:
			#return true
	#return false


func bake():
	length = max(length, 1, brushes[brushes.size() - 1].frame_num)
	# Frames.
	brushes.sort_custom(_compare_brushes)
	if brushes.size() == 0:
		return
	brush_frames = []
	var brush_i := 0
	var next_t = get_brush_end_frame(brush_i)
	for frame in length:
		if frame > next_t:
			brush_i += 1
			next_t = get_brush_end_frame(brush_i)
		brush_frames.push_back(get_path_to(brushes[brush_i]))
	
	# Transforms.
	transform_keys_frames.resize(length)
	
	if transform_keys.size() <= 0:
		# If there are no brushes, fill it up with new Transforms,
		# If there is 1, fill it up with that one.
		var key_transform: Transform2D = (
				Transform2D()
			if transform_keys.size() == 0 else
				transform_keys[0]
			)
		for i in length:
			transform_keys_frames[i] = key_transform
		return
	
	for frame in length:
		var from: Tweenframe
		var to: Tweenframe
		
		# Find the brush from and brush to.
		for key in transform_keys:
			to = key
			# If the brush is past the current frame_num, we have set the 'to' in the prev line,.
			# And the 'from' in the last cycle, break here.
			# If this is the first cycle, 'from' will not be set (brush is before first brush).
			if key.frame_num > frame:
				break
			from = key
			# If this is the last brush, there will not be another cycle.
			# And brush and brush will be the same value.
		
		# Assign transforms.
		if not from or from == to:
			# If there is no 'from', this is before the first brush;.
			# If 'from' and 'to' are the same, the is past the last brush.
			# Either way the correct transform will be stored in 'to'.
			transform_keys_frames[frame] = to.transform
		else:
			# Both 'from' and 'to' are found, interpolate between them.
			var weight = from.ease_t((frame - from.frame_num) / float(to.frame_num - from.frame_num))
			transform_keys_frames[frame] = from.transform.interpolate_with(to.transform, weight)
	
	
	for frame in length:
		var from: Tweenframe
		var to: Tweenframe
		for key in transform_keys:
			to = key
			if key.frame_num > frame:
				break
			from = key
		if not from or from == to:
			transform_keys_frames[frame] = to.transform
		else:
			var weight = from.ease_t((frame - from.frame_num) / float(to.frame_num - from.frame_num))
			transform_keys_frames[frame] = from.transform.interpolate_with(to.transform, weight)


func get_brush_end_frame(brush) -> int:
	var next = get_brush_next(brush)
	if next:
		return next.frame_num - 1
	return length - 1


func get_brush_next(brush):
	var next_index = (
			brush if brush is int else
			brushes.find(brush)
	) + 1
	if next_index < brushes.size():
		return brushes[next_index]
	return null
