@tool
extends Control

const TimelineLayerFrames = preload("res://addons/goulash/ui/timeline_layer_frames.tscn")
const TimelineLayerInfo = preload("res://addons/goulash/ui/timeline_layer_info.tscn")

var brush_clip: BrushClip2D

var scrubbing := false

func _ready():
	%FrameIndicator.modulate = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
	
	%LabelNoBrushClip.visible = true
	%Timeline.visible = false
	
	%ButtonOnion.button_pressed = GoulashEditor.onion_skin_enabled
	%LineEditOnionFrames.text = str(GoulashEditor.onion_skin_frames)


func load_brush_clip(brush_clip: BrushClip2D):
	if self.brush_clip == brush_clip:
		return
	if is_instance_valid(self.brush_clip):
		self.brush_clip.frame_changed.disconnect(_on_frame_changed)
	self.brush_clip = brush_clip
	_clear_layers()
	if brush_clip == null:
		%LabelNoBrushClip.visible = true
		%Timeline.visible = false
		return
	
	%LabelNoBrushClip.visible = false
	%Timeline.visible = true
	
	%LineEditFPS.placeholder_text = str(Goulash.default_fps)
	
	if brush_clip.fps_override == 0:
		%LineEditFPS.text = ""
	else:
		%LineEditFPS.text = str(brush_clip.fps_override)
	_load_layers()
	brush_clip.frame_changed.connect(_on_frame_changed)
	
	custom_minimum_size.y = 60.0 + brush_clip.layers.size() * 32.0


func _on_frame_changed():
	%FrameIndicator.position.x = GoulashEditor.editor.editing_brush.current_frame * 12 + 3


func _on_button_previous_frame_pressed():
	if GoulashEditor.editor.editing_brush:
		GoulashEditor.editor.editing_brush.previous_frame()


func _on_button_play_pressed():
	if GoulashEditor.editor.editing_brush:
		if GoulashEditor.editor.editing_brush.is_playing:
			GoulashEditor.editor.editing_brush.stop()
		else:
			GoulashEditor.editor.editing_brush.play()


func _on_button_next_frame_pressed():
	if GoulashEditor.editor.editing_brush:
		GoulashEditor.editor.editing_brush.next_frame()



func _clear_layers():
	for layer_options in %LayersInfo.get_children():
		layer_options.queue_free()
	
	for layer_frames in %LayersFrames.get_children():
		layer_frames.queue_free()


func _load_layers():
	for layer in GoulashEditor.editor.editing_brush.layers:
		_add_layer(layer)


func _add_layer(layer):
	var info = TimelineLayerInfo.instantiate()
	var frames = TimelineLayerFrames.instantiate()
	%LayersInfo.add_child(info)
	info.init(layer)
	%LayersFrames.add_child(frames)
	frames.draw(layer)


func _on_button_add_layer_pressed():
	brush_clip._create_layer()
	GoulashEditor.editor._selected_layer_id = brush_clip.layers.size() - 1
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
	GoulashEditor.editor.editing_brush.fps_override = value
	%LineEditFPS.text = str(value)


func _on_button_onion_toggled(toggled_on):
	GoulashEditor.onion_skin_enabled = toggled_on
	if is_instance_valid(brush_clip):
		brush_clip.draw()


func _on_line_edit_onion_frames_text_submitted(new_text):
	%LineEditOnionFrames.release_focus()


func _on_line_edit_onion_frames_focus_exited():
	GoulashEditor.onion_skin_enabled = max(int(%LineEditOnionFrames.text), 1)
	brush_clip.draw()


func _input(event) -> void:
	if not visible or not is_instance_valid(brush_clip):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var tl_node = %FrameCounts
			var rect = Rect2(tl_node.position, get_rect().size - tl_node.position)
			rect.size.y = tl_node.get_rect().size.y
			if rect.has_point(get_local_mouse_position()):
				scrubbing = true
		else:
			scrubbing = false


func _process(delta):
	if scrubbing:
		var tl_node = %FrameCounts
		var to_frame = int((get_local_mouse_position().x - tl_node.position.x - 5.0) / 10.0)
		to_frame = clamp(to_frame, 0, brush_clip.total_frames - 1)
		brush_clip.goto(to_frame)
