@tool
class_name Timeline
extends Control

const FRAME_WIDTH = 12

const TimelineLayerFrames = preload("res://addons/goolash/ui/timeline_layer_frames.tscn")
const TimelineLayerInfo = preload("res://addons/goolash/ui/timeline_layer_info.tscn")

var brush_clip: BrushClip2D

var scrubbing := false

func _ready():
	%FrameIndicator.modulate = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
	
	%LabelNoBrushClip.visible = true
	%Timeline.visible = false
	
	%ButtonOnion.button_pressed = GoolashEditor.onion_skin_enabled
	%LineEditOnionFrames.text = str(GoolashEditor.onion_skin_frames)


func load_brush_clip(brush_clip: BrushClip2D):
	if self.brush_clip == brush_clip:
		return
	if is_instance_valid(self.brush_clip):
		self.brush_clip.frame_changed.disconnect(_on_frame_changed)
	self.brush_clip = brush_clip
	
	## Handle if a BrushClip or null is loaded
	var brush_clip_selected := brush_clip != null
	%Timeline.visible = brush_clip_selected
	%LabelNoBrushClip.visible = not brush_clip_selected
	if not brush_clip_selected:
		custom_minimum_size.y = 30.0
		return
	
	## FPS
	%LineEditFPS.placeholder_text = str(Goolash.default_fps)
	if brush_clip.fps_override == 0:
		%LineEditFPS.text = ""
	else:
		%LineEditFPS.text = str(brush_clip.fps_override)
	
	%ButtonAutoPlay.button_pressed = brush_clip.auto_play
	
	_clear_layers()
	var is_editable = GoolashEditor.is_editable(brush_clip)
	if is_editable:
		_load_layers()
		custom_minimum_size.y = 60.0 + brush_clip.layers.size() * 32.0
	else:
		custom_minimum_size.y = 30.0
		size.y = 30.0
	%LayersContainer.visible = is_editable
	%EditorOptions.visible = is_editable
	
	brush_clip.frame_changed.connect(_on_frame_changed)
	brush_clip.edited.connect(_on_brush_clip_edited)
	update_timeline_length()


func _on_frame_changed():
	update_timeline_length()


func _on_brush_clip_edited():
	update_timeline_length()


func update_timeline_length():
	%FrameIndicator.position.x = GoolashEditor.editor.editing_brush.current_frame * FRAME_WIDTH + FRAME_WIDTH * 0.5
	var end_pos = brush_clip.total_frames * FRAME_WIDTH
	%AreaActive.size.x = end_pos
	%AreaInactive.position.x = end_pos
	%AreaInactive.size.x = %FrameCounts.size.x - end_pos


func _on_button_previous_frame_pressed():
	if GoolashEditor.editor.editing_brush:
		GoolashEditor.editor.editing_brush.previous_frame()


func _on_button_play_pressed():
	if GoolashEditor.editor.editing_brush:
		if GoolashEditor.editor.editing_brush.is_playing:
			GoolashEditor.editor.editing_brush.stop()
		else:
			GoolashEditor.editor.editing_brush.play()


func _on_button_next_frame_pressed():
	if GoolashEditor.editor.editing_brush:
		GoolashEditor.editor.editing_brush.next_frame()



func _clear_layers():
	for layer_options in %LayersInfo.get_children():
		layer_options.queue_free()
	
	for layer_frames in %LayersFrames.get_children():
		layer_frames.queue_free()


func _load_layers():
	for layer in GoolashEditor.editor.editing_brush.layers:
		_add_layer(layer)


func _add_layer(layer):
	var layer_info = TimelineLayerInfo.instantiate()
	var layer_frames = TimelineLayerFrames.instantiate()
	%LayersInfo.add_child(layer_info)
	layer_info.init(layer)
	%LayersFrames.add_child(layer_frames)
	layer_frames.init(layer)


func _on_button_add_layer_pressed():
	brush_clip._create_layer()
	GoolashEditor.editor._editing_layer_num = brush_clip.layers.size() - 1
	_clear_layers()
	_load_layers()
	custom_minimum_size.y = 60.0 + brush_clip.layers.size() * 32.0


func _on_line_edit_fps_text_submitted(input: String):
	%LineEditFPS.release_focus()


func _on_line_edit_fps_focus_exited():
	_parse_fps(%LineEditFPS.text)


func _parse_fps(input: String):
	if input.is_valid_float() or input.is_valid_int():
		_set_fps(int(input))
	else:
		var expression = Expression.new()
		expression.parse(input)
		var result = expression.execute()
		if expression.has_execute_failed():
			%LineEditFPS.text = ""
		else:
			_set_fps(int(result))

func _set_fps(value: int):
	GoolashEditor.editor.editing_brush.fps_override = value
	%LineEditFPS.text = str(value)


func _on_button_onion_toggled(toggled_on):
	GoolashEditor.onion_skin_enabled = toggled_on
	if is_instance_valid(brush_clip):
		brush_clip.draw()


func _on_line_edit_onion_frames_text_submitted(new_text):
	%LineEditOnionFrames.release_focus()


func _on_line_edit_onion_frames_focus_exited():
	GoolashEditor.onion_skin_enabled = max(int(%LineEditOnionFrames.text), 1)
	brush_clip.draw()


func _input(event) -> void:
	if not visible or not is_instance_valid(brush_clip):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var tl_node = %FrameCounts
			var rect = Rect2(tl_node.position, get_rect().size - tl_node.position)
			rect.size.y = tl_node.get_rect().size.y + %LayersInfo.get_child_count() * 32.0
			if rect.has_point(get_local_mouse_position()):
				scrubbing = true
		else:
			scrubbing = false


func _process(delta):
	if scrubbing:
		var tl_node = %FrameCounts
		var to_frame = int(floor((get_local_mouse_position().x - tl_node.position.x + 1) / FRAME_WIDTH))
		to_frame = clamp(to_frame, 0, brush_clip.total_frames - 1)
		brush_clip.goto(to_frame)
