@tool
class_name Timeline
extends Control

const FRAME_WIDTH = 12
const LAYER_HEIGHT = 36

const TimelineLayerFrames = preload("res://addons/goolash/ui/timeline_layer_frames.tscn")
const TimelineLayerInfo = preload("res://addons/goolash/ui/timeline_layer_info.tscn")

var brush_animation: BrushAnimation2D

var scrubbing := false

@onready var layers_info = %LayersInfo
@onready var layers_frames = %LayersFrames
@onready var frame_indicator = %FrameIndicator
@onready var context_menu = %PopupMenu
@onready var input_fps = %LineEditFPS

func _ready():
	frame_indicator.modulate = GoolashEditor.godot_accent_color
	
	%LabelNoBrushClip.visible = true
	%Timeline.visible = false
	
	%ButtonOnion.button_pressed = GoolashEditor.onion_skin_enabled
	%LineEditOnionFrames.text = str(GoolashEditor.onion_skin_frames)


func load_brush_animation(brush_animation: BrushAnimation2D):
	if self.brush_animation == brush_animation:
		return
	if is_instance_valid(self.brush_animation):
		self.brush_animation.frame_changed.disconnect(_on_frame_changed)
		self.brush_animation.edited.disconnect(_on_brush_animation_edited)
	self.brush_animation = brush_animation
	
	## Handle if a BrushClip or null is loaded
	var brush_animation_selected := brush_animation != null
	%Timeline.visible = brush_animation_selected
	%LabelNoBrushClip.visible = not brush_animation_selected
	if not brush_animation_selected:
		custom_minimum_size.y = 30.0
		size.y = 30.0
		return
	
	## FPS
	input_fps.placeholder_text = str(Goolash.default_fps)
	if brush_animation.fps_override == 0:
		input_fps.text = ""
	else:
		input_fps.text = str(brush_animation.fps_override)
	
	%ButtonAutoPlay.button_pressed = brush_animation.auto_play
	%ButtonLoop.button_pressed = brush_animation.looping
	
	_load_layers()
	
	var is_editable = GoolashEditor.is_editable(brush_animation)
	%LayersContainer.visible = is_editable
	%EditorOptions.visible = is_editable
	if not is_editable:
		custom_minimum_size.y = 30.0
		size.y = 30.0
	
	brush_animation.frame_changed.connect(_on_frame_changed)
	brush_animation.edited.connect(_on_brush_animation_edited)
	update_timeline_length()


func _on_frame_changed():
	update_timeline_length()


func _on_brush_animation_edited():
	update_timeline_length()


func update_timeline_length():
	frame_indicator.position.x = GoolashEditor.editor.editing_node.current_frame * FRAME_WIDTH + FRAME_WIDTH * 0.5
	var end_pos = brush_animation.frame_count * FRAME_WIDTH
	%AreaActive.size.x = end_pos
	%AreaInactive.position.x = end_pos
	%AreaInactive.size.x = %FrameCounts.size.x - end_pos


func _on_button_previous_frame_pressed():
	if GoolashEditor.editor.editing_node:
		GoolashEditor.editor.editing_node.previous_frame()


func _on_button_play_pressed():
	if GoolashEditor.editor.editing_node:
		if GoolashEditor.editor.editing_node.is_playing:
			GoolashEditor.editor.editing_node.stop()
		else:
			GoolashEditor.editor.editing_node.play()


func _on_button_next_frame_pressed():
	if GoolashEditor.editor.editing_node:
		GoolashEditor.editor.editing_node.next_frame()


func _load_layers():
	for layer_options in layers_info.get_children():
		layer_options.queue_free()
	for layer_frames in layers_frames.get_children():
		layer_frames.queue_free()
	
	if not GoolashEditor.is_editable(brush_animation):
		return
	
	for layer in brush_animation.layers:
		_add_layer(layer)
	
	custom_minimum_size.y = 60.0 + brush_animation.layers.size() * LAYER_HEIGHT
	size.y = max(size.y, custom_minimum_size.y + 20.0)


func _add_layer(layer):
	var layer_info = TimelineLayerInfo.instantiate()
	var layer_frames = TimelineLayerFrames.instantiate()
	layers_info.add_child(layer_info)
	layers_info.move_child(layer_info, layer.layer_num)
	layer_info.init(layer)
	layers_frames.add_child(layer_frames)
	layers_frames.move_child(layer_frames, layer.layer_num)
	layer_frames.init(layer)


func _on_button_add_layer_pressed():
	GoolashEditor.editor.create_layer()
	GoolashEditor.editor.set_editing_layer_num(brush_animation.layers.size() - 1)


func _on_layer_added_or_removed():
	_load_layers()


#region FPS

func _on_line_edit_fps_text_submitted(input: String):
	input_fps.release_focus()


func _on_line_edit_fps_focus_exited():
	_parse_fps(input_fps.text)


func _parse_fps(input: String):
	if input.is_valid_float() or input.is_valid_int():
		_set_fps(int(input))
	else:
		var expression = Expression.new()
		expression.parse(input)
		var result = expression.execute()
		if expression.has_execute_failed():
			input_fps.text = ""
		else:
			_set_fps(int(result))


func _set_fps(value: int):
	GoolashEditor.editor.editing_node.fps_override = value
	input_fps.text = str(value)

#endregion


func _on_line_edit_onion_frames_text_submitted(new_text):
	%LineEditOnionFrames.release_focus()


func _on_line_edit_onion_frames_focus_exited():
	GoolashEditor.onion_skin_frames = max(int(%LineEditOnionFrames.text), 1)
	brush_animation.draw()


func _input(event) -> void:
	if not visible or not is_instance_valid(brush_animation):
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				var mouse_position = get_local_mouse_position()
				var tl_node = %FrameCounts
				var rect = Rect2(tl_node.position, get_rect().size - tl_node.position)
				rect.size.y = tl_node.get_rect().size.y + layers_info.get_child_count() * LAYER_HEIGHT
				
				if rect.has_point(mouse_position):
					if mouse_position.y < rect.position.y + rect.size.y + LAYER_HEIGHT and mouse_position.x > rect.position.x + rect.size.x - 60.0:
						pass
					else:
						scrubbing = true
						GoolashEditor.editor.selected_keyframe = null
			else:
				scrubbing = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				var mouse_position = get_local_mouse_position()
				var tl_node = %FrameCounts
				var rect = Rect2(tl_node.position, get_rect().size - tl_node.position)
				rect.position.y = 30.0
				rect.size.y = layers_info.get_child_count() * LAYER_HEIGHT
				
				if rect.has_point(mouse_position):
					init_context_menu()


func init_context_menu():
	context_menu.clear()
	add_context_menu_item("Add Frame", GoolashEditor.editor.key_add_frame)
	add_context_menu_item("Add Keyframe", GoolashEditor.editor.key_add_keyframe)
	add_context_menu_item("Add Empty Keyframe", GoolashEditor.editor.key_add_keyframe_blank)
	add_context_menu_item("Remove Frame", GoolashEditor.editor.key_add_frame, true)
	add_context_menu_item("Remove Keyframe", GoolashEditor.editor.key_add_keyframe, true)
	context_menu.position = get_global_mouse_position()
	context_menu.reset_size()
	context_menu.show()


func add_context_menu_item(text: String, key: int, shift := false):
	var shortcut = char(key)
	if shift:
		shortcut = "Shift+" + shortcut
	text = "%s (%s)" % [text, shortcut]
	context_menu.add_item(text, -1, key)


func _process(delta):
	if scrubbing:
		var tl_node = %FrameCounts
		var to_frame = int(floor((get_local_mouse_position().x - tl_node.position.x + 1) / FRAME_WIDTH))
		to_frame = clamp(to_frame, 0, brush_animation.frame_count - 1)
		brush_animation.goto_and_stop(to_frame)


func _on_button_loop_toggled(toggled_on):
	brush_animation.looping = toggled_on
	if is_instance_valid(brush_animation):
		brush_animation.draw()


func _on_button_auto_play_toggled(toggled_on):
	brush_animation.auto_play = toggled_on


func _on_button_onion_toggled(toggled_on):
	GoolashEditor.onion_skin_enabled = toggled_on
	if is_instance_valid(brush_animation):
		brush_animation.draw()
