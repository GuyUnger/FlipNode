@tool
extends Control

func _ready():
	%FrameIndicator.modulate = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
	
	if not Engine.is_editor_hint():
		load_brush_clip(null)

func load_brush_clip(brush_clip: BrushClip2D):
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


func _on_frame_changed():
	%FrameIndicator.position.x = Goulash.editor.editing_brush.current_frame * 12


func _on_button_previous_frame_pressed():
	if Goulash.editor.editing_brush:
		Goulash.editor.editing_brush.previous_frame()


func _on_button_play_pressed():
	if Goulash.editor.editing_brush:
		if Goulash.editor.editing_brush.is_playing:
			Goulash.editor.editing_brush.stop()
		else:
			Goulash.editor.editing_brush.play()


func _on_button_next_frame_pressed():
	if Goulash.editor.editing_brush:
		Goulash.editor.editing_brush.next_frame()


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
	Goulash.editor.editing_brush.fps_override = value
	%LineEditFPS.text = str(value)


const IconDelete = preload("res://addons/goulash/icons/Remove.svg")
const IconLayer = preload("res://addons/goulash/icons/CanvasLayer.svg")


func _on_button_delete_mouse_entered():
	%ButtonDelete.icon = IconDelete


func _on_button_delete_mouse_exited():
	%ButtonDelete.icon = IconLayer

const TimelineLayerFrames = preload("res://addons/goulash/ui/timeline_layer_frames.tscn")
const TimelineLayerInfo = preload("res://addons/goulash/ui/timeline_layer_info.tscn")


func _clear_layers():
	for layer_options in %LayersInfo.get_children():
		layer_options.queue_free()
	
	for layer_frames in %LayersFrames.get_children():
		layer_frames.queue_free()


func _load_layers():
	for layer in Goulash.editor.editing_brush.layers:
		_add_layer(layer)


func _add_layer(layer):
	var info = TimelineLayerInfo.instantiate()
	var frames = TimelineLayerFrames.instantiate()
	%LayersInfo.add_child(info)
	info.init(layer)
	%LayersFrames.add_child(frames)
	frames.draw(layer)
