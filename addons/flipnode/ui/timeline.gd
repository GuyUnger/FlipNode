@tool
class_name Timeline
extends Control

const FRAME_WIDTH = 24
const LAYER_HEIGHT = 36

const LayerFrames = preload("res://addons/flipnode/ui/timeline_layer_frames.tscn")
const LayerInfo = preload("res://addons/flipnode/ui/timeline_layer_info.tscn")
const FrameNumber = preload("res://addons/flipnode/ui/timeline_frame_numbers.tscn")

enum {TYPE_LAYER, TYPE_AUDIO, TYPE_AUDDIO2D}

var animation: BrushAnimation2D

var scrubbing := false

@onready var layers_info = %LayersInfo
@onready var layers_brushes = %LayersFrames
@onready var frame_indicator = %FrameIndicator
@onready var context_menu = %PopupMenu
@onready var input_fps = %LineEditFPS

var editor: FlipEditor


func _ready():
	%LabelNoBrushClip.visible = true
	%Timeline.visible = false


func init(editor):
	self.editor = editor
	frame_indicator.modulate = editor.accent_color
	editor.editing_animation_changed.connect(_on_editing_animation_changed)
	
	%ButtonOnion.button_pressed = editor.onion_skin_enabled
	%LineEditOnionFrames.text = str(editor.onion_skin_frames)


func _on_editing_animation_changed():
	load_animation(editor.editing_animation)


func load_animation(animation: BrushAnimation2D):
	if self.animation == animation:
		return
	if self.animation:
		self.animation.frame_changed.disconnect(_on_frame_changed)
	if animation:
		animation.frame_changed.connect(_on_frame_changed)
	
	self.animation = animation
	
	# Handle if a BrushAnimation2D or null is loaded.
	var brush_animation_selected := animation != null
	if not brush_animation_selected:
		custom_minimum_size.y = 30.0
		size.y = 30.0
		%Timeline.visible = false
		%LabelNoBrushClip.visible = true
		return
	
	%Timeline.visible = true
	%LabelNoBrushClip.visible = false
	
	# FPS.
	input_fps.placeholder_text = str(Flip.default_fps)
	if animation.fps == 0:
		input_fps.text = ""
	else:
		input_fps.text = str(animation.fps)
	
	%ButtonAutoPlay.button_pressed = animation.auto_play
	%ButtonLoop.button_pressed = animation.looping
	
	_load_layers()
	
	var is_editable = Flip.is_node_editable(animation)
	%LayersContainer.visible = is_editable
	%EditorOptions.visible = is_editable
	if not is_editable:
		custom_minimum_size.y = 30.0
		size.y = 30.0
	
	update_timeline_length()


func _on_frame_changed():
	if editor.editing_animation:
		update_timeline_length()


#func _on_brush_edited():
	#if editor.editing_animation:
		#update_timeline_length()


func update_timeline_length():
	frame_indicator.position.x = editor.editing_animation.current_frame * FRAME_WIDTH + FRAME_WIDTH * 0.5
	var end_pos = animation.length * FRAME_WIDTH
	%AreaActive.size.x = end_pos
	%AreaInactive.position.x = end_pos
	%AreaInactive.size.x = %FrameCounts.size.x - end_pos
	
	for child in %FrameNumbers.get_children():
		child.queue_free()
	for i in ceil(animation.length / 5.0):
		var frame_number = FrameNumber.instantiate()
		frame_number.size.x = FRAME_WIDTH * 5.0
		%FrameNumbers.add_child(frame_number)
		frame_number.get_node("Label").text = str(i * 5)


func _on_button_previous_brush_pressed():
	if Flip.editor.editing_animation:
		Flip.editor.editing_animation.previous_frame()


func _on_button_play_pressed():
	if editor.editing_animation:
		if editor.editing_animation.is_playing:
			editor.editing_animation.stop()
		else:
			editor.editing_animation.play()


func _on_button_next_brush_pressed():
	if editor.editing_animation:
		editor.editing_animation.next_frame()


func _load_layers():
	for layer_options in layers_info.get_children():
		layer_options.queue_free()
	for layer_brushes in layers_brushes.get_children():
		layer_brushes.queue_free()
	
	if not Flip.is_node_editable(animation):
		return
	
	for layer in animation.layers:
		_add_layer(layer)
	
	custom_minimum_size.y = 60.0 + animation.layers.size() * LAYER_HEIGHT
	size.y = max(size.y, custom_minimum_size.y + 20.0)


func _add_layer(layer):
	var layer_info = LayerInfo.instantiate()
	var layer_brushes = LayerFrames.instantiate()
	layers_info.add_child(layer_info)
	#TODO: do they need ordering?
	#layers_info.move_child(layer_info, layer)
	layer_info.init(layer, TYPE_LAYER)
	layers_brushes.add_child(layer_brushes)
	#layers_brushes.move_child(layer_brushes, layer.layer_num)
	layer_brushes.init(layer)


func _on_button_add_layer_pressed():
	var layer = editor.create_layer()
	editor.select_layer(layer)


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
	editor.editing_animation.fps = value
	input_fps.text = str(value)

#endregion


func _on_line_edit_onion_brushes_text_submitted(new_text):
	%LineEditOnionFrames.release_focus()


func _on_line_edit_onion_brushes_focus_exited():
	Flip.editor.onion_skin_frames = max(int(%LineEditOnionFrames.text), 1)
	animation.draw()


func _input(event) -> void:
	if not visible or not is_instance_valid(animation):
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
	add_context_menu_item("Add Frame", editor.key_brush_extend)
	add_context_menu_item("Add Keyframe", editor.key_duplicate_brush)
	add_context_menu_item("Add Empty Keyframe", editor.key_new_brush)
	add_context_menu_item("Remove Frame", editor.key_brush_extend, true)
	add_context_menu_item("Remove Keyframe", editor.key_duplicate_brush, true)
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
		to_frame = clamp(to_frame, 0, animation.length - 1)
		animation.goto_and_stop(to_frame)


func _on_button_loop_toggled(toggled_on):
	animation.looping = toggled_on
	if is_instance_valid(animation):
		animation.draw()


func _on_button_auto_play_toggled(toggled_on):
	animation.auto_play = toggled_on


func _on_button_onion_toggled(toggled_on):
	Flip.editor.onion_skin_enabled = toggled_on
	if is_instance_valid(animation):
		animation.draw()


func start_drag(layer_info):
	pass

#TODO: this
#func show():
	#make_bottom_panel_item_visible(timeline)
