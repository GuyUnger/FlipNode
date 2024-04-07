@tool
class_name FlipEditor extends Control

signal editing_brush_changed(brush)
signal editing_animation_changed(animation)
signal selected_layer_changed
signal brush_edited(brush)
signal tool_settings_changed
signal screen_transform_changed

enum {
	TOOL_SELECT, TOOL_PAINT, TOOL_FILL, TOOL_EYEDROPPER, TOOL_OVAL,
	TOOL_RECT, TOOL_SHAPE, TOOL_SMOOTH,
}

enum {MAIN_SCREEN_2D, MAIN_SCREEN_3D, MAIN_SCREEN_SCRIPT}

const TextureEyedropper = preload("res://addons/flipnode/icons/ColorPick.svg")
const TextureFill = preload("res://addons/flipnode/icons/CursorBucket.svg")

var accent_color: Color = Color("ff2222")
var selection_color: Color = Color("ff8000")

# Shortcuts.
var key_extend_brush := KEY_N
var key_new_brush := KEY_B
var key_duplicate_brush := KEY_V

var key_tool_select_paint := KEY_P
var key_tool_select_oval := KEY_O
var key_tool_select_rectangle := KEY_M
var key_tool_select_shape := KEY_Y
var key_tool_select_fill := KEY_G
var key_tool_select_smooth := KEY_T
var key_play := KEY_SLASH
var key_next_frame := KEY_PERIOD
var key_previous_frame := KEY_COMMA
var key_tool_size_decrease := KEY_BRACKETLEFT
var key_tool_size_increase := KEY_BRACKETRIGHT
var key_erase_mode := KEY_X

@onready var toolbar: Toolbar = %Toolbar
var timeline: Timeline

#TODO: make this work with normal undo redo as well
var undo_redo: EditorUndoRedoManager

var active_actions := []

var default_swatches := PackedColorArray([
		Color("fc9735"), Color("ff192b"), Color("780d2a"),
		Color("ffd900"), Color("ff5f00"), Color("3f2617"),
		Color("3f2617"), Color("73a110"), Color("393a28"),
		Color("a8e6cf"), Color("299176"), Color("296458"),
		Color("6ec6ff"), Color("387cd5"), Color("2e397e"),
		Color("fc7a93"), Color("e21077"), Color("ffffff"),
		Color("000000"), Color("181923"), Color("37353c"),
		Color("696764"), Color("c1b3ac"), Color("ffffff"),
	])

var current_tool: int = TOOL_PAINT
var current_tool_override: int = -1
var current_color: Color = Color.BLACK

var current_draw_mode := Flip.DRAW_MODE_FRONT
var current_warp_ease := Flip.WARP_EASE_SMOOTH

var _action_paint_size: float = 16.0
var _action_paint_erase_size: float = 32.0

var _action_warp_size: float = 60.0
var _action_warp_cut_angle: float = deg_to_rad(30.0)
var _action_warp_size_preview_t: float = 0.0

var _action_smooth_strength := 0.5

var _pen_pressure: float = 0.0

var onion_skin_enabled := true
var onion_skin_frames: int = 1
var erase_mode := false

var editing_animation: BrushAnimation2D
var editing_brush: Brush2D
var allow_editing := false
var _selected_highlight: float = 0.0

var _screen_transform_previous

var allow_custom_cursor := true
var allow_hide_cursor := false


#TODO: mirroring, would work better if actions are their own classes
enum {MIRROR_NON, MIRROR_H, MIRROR_V, MIRROR_HV}
var mirror := MIRROR_NON

var hover_edge_selections := []

var selected_layers := {}

var selection: Brush2D

var focus_frame
var focus_darken
var show_focus := true

var clear_color: Color


func _ready() -> void:
	toolbar.init(self)
	create_focus_frame()
	create_focus_darken()


func create_focus_frame():
	focus_frame = ColorRect.new()
	focus_frame.color = Color.WHITE
	focus_frame.color.a = 0.5


func create_focus_darken():
	focus_darken = ColorRect.new()
	focus_darken.color = clear_color
	focus_darken.color.a = 0.5
	focus_darken.size = Vector2.ONE * 100000.0
	focus_darken.position = -focus_darken.size * 0.5


func open():
	visible = true


func close():
	visible = false
	if editing_brush:
		editing_brush.edited.disconnect(_on_brush_edited)
		editing_brush = null
	editing_animation = null


func select_layer(layer):
	selected_layers[editing_animation] = layer
	selected_layer_changed.emit()


func get_selected_layer() -> Layer2D:
	if editing_animation.layers.size() == 0:
		push_error("BrushAnimation2D %s doesn't have any layers" % editing_animation.get_path())
	if not is_instance_valid(editing_animation):
		return null
	if editing_animation in selected_layers:
		return selected_layers[editing_animation]
	return editing_animation.layers[0]


func select_brush(brush: Brush2D):
	if editing_brush == brush:
		return
	if editing_brush:
		editing_brush.edited.disconnect(_on_brush_edited)
		
		editing_brush.set_top(false)
		if is_instance_valid(focus_frame):
			focus_frame.get_parent().remove_child(focus_frame)
		if is_instance_valid(focus_darken):
			focus_darken.get_parent().remove_child(focus_darken)
		editing_brush.queue_redraw()
	
	editing_brush = brush
	if editing_brush:
		editing_brush.edited.connect(_on_brush_edited)
		
		if not is_instance_valid(focus_frame):
			create_focus_frame()
		if not is_instance_valid(focus_darken):
			create_focus_darken()
		editing_brush.get_tree().edited_scene_root.add_child(focus_darken)
		editing_brush.add_child(focus_frame)
		update_focus_frame()
	
	editing_brush_changed.emit(editing_brush)


func _on_brush_edited():
	brush_edited.emit(editing_brush)
	update_focus_frame()


func update_focus_frame():
	focus_frame.visible = show_focus
	focus_darken.visible = show_focus
	editing_brush.set_top(show_focus)
	focus_frame.position = editing_brush.bounds.position
	focus_frame.size = editing_brush.bounds.size


func select_animation(animation: BrushAnimation2D):
	if editing_animation == animation:
		return
	if editing_animation:
		editing_animation.frame_changed.disconnect(_on_animation_frame_changed)
	editing_animation = animation
	if editing_animation:
		_selected_highlight = 1.0
		editing_animation.frame_changed.connect(_on_animation_frame_changed)
	editing_animation_changed.emit()


func try_select_children(parent, packed_parent = null):
	var children: Array = parent.get_children()
	children.reverse()
	
	if not packed_parent and parent.scene_file_path != "" and parent != EditorInterface.get_edited_scene_root():
		packed_parent = parent
	
	for child in children:
		# Skip locked nodes.
		if child.has_meta("_edit_lock_"):
			continue
		if try_select_children(child, packed_parent):
			return true
		if child is Brush2D:
			for stroke in child.strokes:
				if Geometry2D.is_point_in_polygon(child.get_local_mouse_position(), stroke.polygon):
					if packed_parent and child.owner == packed_parent:
						# Brush is inside a packed scene, select the packed scene.
						select(packed_parent)
					else:
						select(child)
					return true
	return false


func select(node):
	if not Engine.is_editor_hint():
		return
	await get_tree().process_frame
	EditorInterface.get_selection().clear()
	EditorInterface.inspect_object(node)
	EditorInterface.get_selection().add_node(node)


func _on_animation_frame_changed():
	# change selected brush on frame change
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.size() == 1 and selected_nodes[0] is Brush2D:
		select(get_selected_layer().get_brush(editing_animation.current_frame))


#region Input


func _input(event):
	if Input.is_key_pressed(KEY_CTRL):
		if event is InputEventKey and event.is_pressed() and event.keycode == KEY_B:
			var parent
			var from_brush
			if EditorInterface.get_selection().get_selected_nodes().size() > 0:
				parent = EditorInterface.get_selection().get_selected_nodes()[0]
			if not parent:
				parent = get_tree().edited_scene_root
			if parent is Brush2D:
				from_brush = parent
				parent = parent.get_parent()
			
			if parent:
				var brush = Brush2D.new()
				brush.name = "Brush2D"
				parent.add_child(brush, true)
				if from_brush:
					brush.position = from_brush.position
					parent.move_child(brush, from_brush.get_index() +1)
				brush.owner = parent if parent == get_tree().edited_scene_root else parent.owner
				select(brush)
		return
	if not (_is_main_screen_visible(MAIN_SCREEN_2D) or _is_main_screen_visible(MAIN_SCREEN_3D)):
		return
	if editing_animation:
		if event is InputEventKey and event.is_pressed():
			_input_animation(event)
	


func _input_animation(event: InputEventKey):
	match event.keycode:
		key_play:
			if editing_animation.is_playing:
				editing_animation.stop()
			else:
				editing_animation.play()
			return true
		key_previous_frame:
			editing_animation.stop()
			if editing_animation.previous_frame():
				select_brush(get_selected_layer().get_brush(editing_animation.current_frame))
				return true
		key_next_frame:
			editing_animation.stop()
			if editing_animation.next_frame():
				select_brush(get_selected_layer().get_brush(editing_animation.current_frame))
				return true
		key_extend_brush:
			if Input.is_key_pressed(KEY_SHIFT):
				remove_brush(editing_animation.current_frame)
			else:
				extend_brush(editing_animation.current_frame)
			return true
		key_duplicate_brush:
			if Input.is_key_pressed(KEY_SHIFT):
				remove_brush(editing_animation.current_frame)
			else:
				duplicate_brush(editing_animation.current_frame)
			return true
		key_new_brush:
			if Input.is_key_pressed(KEY_SHIFT):
				remove_brush(editing_animation.current_frame)
			else:
				new_brush(editing_animation.current_frame)
			return true


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not is_instance_valid(editing_brush):
		return false
	
	if event is InputEventMouse:
		return _input_mouse(event)
	elif event is InputEventKey:
		if event.is_pressed():
			return _on_key_pressed(event)
		else:
			return _on_key_released(event)
	return false


func _on_key_pressed(event: InputEventKey) -> bool:
	if Input.is_key_pressed(KEY_CTRL):
		match event.keycode:
			KEY_CTRL:
				_on_input_key_ctrl_pressed()
		return false
	
	match event.keycode:
		key_play, key_next_frame, key_previous_frame:
			return true
		KEY_ALT:
			_on_input_key_alt_pressed()
		KEY_Q:
			set_tool(TOOL_SELECT)
			return true
		key_tool_select_paint:
			set_tool(TOOL_PAINT)
			return true
		key_tool_select_rectangle:
			set_tool(TOOL_RECT)
			return true
		key_tool_select_fill:
			set_tool(TOOL_FILL)
			return true
		key_tool_select_smooth:
			set_tool(TOOL_SMOOTH)
			return true
		key_tool_select_oval:
			set_tool(TOOL_OVAL)
			return true
		key_tool_select_shape:
			set_tool(TOOL_SHAPE)
			return true
		key_tool_size_decrease:
			if current_tool == TOOL_PAINT:
				_action_paint_erase_size *= 1 / (2.0 ** (1.0 / 6.0))
				_action_paint_size *= 1 / (2.0 ** (1.0 / 6.0))
				tool_settings_changed.emit()
				_queue_redraw()
				return true
			elif current_tool == TOOL_SELECT or current_tool == TOOL_SMOOTH:
				_action_warp_size *= 1 / (2.0 ** (1.0 / 6.0))
				_action_warp_size_preview_t = 1.0
				update_hover_edge_selections()
				tool_settings_changed.emit()
				_queue_redraw()
				return true
		key_tool_size_increase:
			if current_tool == TOOL_PAINT:
				_action_paint_erase_size *= 2.0 ** (1.0 / 6.0)
				_action_paint_size *= 2.0 ** (1.0 / 6.0)
				tool_settings_changed.emit()
				_queue_redraw()
				return true
			elif current_tool == TOOL_SELECT or current_tool == TOOL_SMOOTH:
				_action_warp_size *= 2.0 ** (1.0 / 6.0)
				_action_warp_size_preview_t = 1.0
				update_hover_edge_selections()
				tool_settings_changed.emit()
				_queue_redraw()
				return true
		key_erase_mode:
			set_erase_mode(true)
			return true
	return false


func _on_key_released(event: InputEventKey) -> bool:
	match event.keycode:
		key_erase_mode:
			set_erase_mode(false)
	return false


func _on_input_key_alt_pressed() -> bool:
	current_tool_override = TOOL_EYEDROPPER
	_queue_redraw()
	return false


func _on_input_key_ctrl_pressed() -> bool:
	current_tool_override = TOOL_FILL
	_queue_redraw()
	return false


func _input_mouse(event: InputEventMouse) -> bool:
	var mouse_position: Vector2  = editing_brush.get_local_mouse_position()
	
	if event is InputEventMouseButton:
		var event_mouse_button: InputEventMouseButton = event
		if event_mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if event_mouse_button.pressed:
				return _on_mouse_button_pressed(mouse_position)
			else:
				_on_mouse_button_released()
		elif event_mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			if event_mouse_button.pressed:
				_on_mouse_button_pressed(mouse_position, true)
			else:
				_on_mouse_button_released()
	elif event is InputEventMouseMotion:
		_on_mouse_motion(mouse_position)
	return true


func _on_mouse_motion(mouse_position):
	_queue_redraw()
	
	for action in active_actions:
		if action is ActionPaint:
			action.move_to(
					mouse_position, _action_paint_erase_size if action.is_erasing() else
					_action_paint_size
			)
		elif "move_to" in action:
			action.move_to(mouse_position)
	if active_actions.size() == 0:
		update_hover_edge_selections()


func update_hover_edge_selections():
	var tool = get_current_tool()
	var position = editing_brush.get_local_mouse_position()
	if tool == TOOL_SELECT:
		hover_edge_selections = editing_brush.get_edge_selections_ranged(
				position, _action_warp_size,
				current_warp_ease, true, 6.0 / editing_brush.get_view_scale().x
		)
	elif tool == TOOL_SMOOTH:
		hover_edge_selections = editing_brush.get_edge_selections_ranged(
					position, _action_warp_size,
					Flip.WARP_EASE_SMOOTH, true, 10.0 / editing_brush.get_view_scale().x
			)
		if not hover_edge_selections:
			var stroke: Stroke = editing_brush.get_stroke_at_position(position)
			if stroke:
				hover_edge_selections = stroke.get_edge_selection()


func _on_mouse_button_pressed(mouse_position: Vector2, right_mouse_button := false) -> bool:
	if active_actions.size() > 0:
		return true
	var is_erasing = right_mouse_button != erase_mode
	var draw_mode = Flip.DRAW_MODE_ERASE if is_erasing else current_draw_mode
	match get_current_tool():
		TOOL_SELECT:
			# Move origin.
			if mouse_position.length() < 10.0 / editing_brush.get_view_scale().x:
				var action = ActionMoveOrigin.new(editing_brush)
				add_action(action)
				action.set_undo_redo(undo_redo)
				return true
			
			# Warp.
			if hover_edge_selections.size() > 0:
				var action = ActionWarp.new(editing_brush, hover_edge_selections)
				add_action(action)
				action.set_undo_redo(undo_redo)
				action.start(mouse_position)
				for selection in hover_edge_selections:
					editing_brush.move_stroke_to_front(selection.stroke)
				
				return true
			
			
			for stroke: Stroke in editing_brush.strokes:
				if stroke.is_point_inside(mouse_position):
					var action = ActionMove.new(editing_brush, stroke)
					add_action(action)
					action.start(mouse_position)
					return true
			try_select_children(EditorInterface.get_edited_scene_root())
		TOOL_PAINT:
			var action = ActionPaint.new(editing_brush, draw_mode, current_color, true)
			add_action(action)
			action.set_undo_redo(undo_redo)
			action.start(
					mouse_position, _action_paint_erase_size if is_erasing else
					_action_paint_size
			)
			return true
		TOOL_FILL:
			var action = ActionFill.new(editing_brush, draw_mode, current_color)
			action.set_undo_redo(undo_redo)
			action.start(mouse_position)
			return true
		TOOL_EYEDROPPER:
			current_color = pick_color(mouse_position)
			toolbar.update_color_picker_color()
			return true
		TOOL_OVAL:
			var action = ActionOval.new(editing_brush, draw_mode, current_color)
			add_action(action)
			action.set_undo_redo(undo_redo)
			action.start(mouse_position)
			return true
		TOOL_RECT:
			var action = ActionRect.new(editing_brush, draw_mode, current_color)
			add_action(action)
			action.set_undo_redo(undo_redo)
			action.start(mouse_position)
			return true
		TOOL_SHAPE:
			var action = ActionShape.new(editing_brush, draw_mode, current_color)
			add_action(action)
			action.set_undo_redo(undo_redo)
			action.start(mouse_position)
			return true
		TOOL_SMOOTH:
			var action = ActionSmooth.new(editing_brush, hover_edge_selections)
			action.set_undo_redo(undo_redo)
			action.start(mouse_position, _action_smooth_strength)
			return true
	
	return try_select_children(EditorInterface.get_edited_scene_root())


#TODO: move this somewhere else
func pick_color(position):
	# Stroke color picking.
	var stroke = find_stroke_at_position(position)
	if stroke:
		return stroke.color
	
	# Viewport color picking.
	var viewport_mouse_position = editing_brush.get_global_mouse_position()
	viewport_mouse_position *= editing_brush.get_viewport_transform()
	
	var image = editing_brush.get_viewport().get_texture().get_image()
	return image.get_pixel(viewport_mouse_position.x, viewport_mouse_position.y)


func find_stroke_at_position(position):
	var stroke = editing_brush.get_stroke_at_position(position)
	if stroke:
		return stroke
	
	return _find_stroke_at_position_loop(
			editing_brush.get_tree().edited_scene_root,
			editing_brush.to_global(position)
	)


func _find_stroke_at_position_loop(parent, position):
	for child in parent.get_children():
		if child.owner:
			var stroke = _find_stroke_at_position_loop(child, position)
			if stroke:
				return stroke
	if parent is Brush2D:
		var stroke = parent.get_stroke_at_position(parent.to_local(position))
		if stroke:
			return stroke
	return null


func add_action(action: Action):
	active_actions.push_back(action)


func _on_mouse_button_released():
	for action in active_actions:
		action.complete()
	active_actions = []

#endregion


func _process(delta):
	if not is_instance_valid(editing_brush) or not allow_editing:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	
	var screen_transform = editing_brush.get_viewport().get_screen_transform()
	if screen_transform != _screen_transform_previous:
		_screen_transform_previous = screen_transform
		screen_transform_changed.emit()
		_queue_redraw()
	
	allow_hide_cursor = (
			EditorInterface.get_editor_main_screen().get_child(0).visible
			and get_rect().has_point(get_local_mouse_position())
			and allow_custom_cursor
			and DisplayServer.window_is_focused()
			and not _is_panning()
	)
	if (current_tool == TOOL_PAINT or current_tool == TOOL_FILL) and allow_hide_cursor:
		#TODO: this needs more checks
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if current_tool_override == TOOL_EYEDROPPER and not Input.is_key_pressed(KEY_ALT):
		current_tool_override = -1
		_queue_redraw()
	
	if current_tool_override == TOOL_FILL and not Input.is_key_pressed(KEY_CTRL):
		current_tool_override = -1
		_queue_redraw()
	
	if _action_warp_size_preview_t > 0.0:
		_action_warp_size_preview_t -= delta / 0.45
	
	_selected_highlight = move_toward(_selected_highlight, 0.0, delta / 0.5)


func extend_brush(frame):
	undo_redo.create_action("Insert Keybrush")
	for layer in editing_animation.layers:
		if editing_animation.current_frame >= layer.length:
			continue
		if editing_brush.animation and layer != editing_brush.layer:
			continue
		undo_redo.add_do_method(layer, "insert_frame", frame)
		undo_redo.add_undo_method(layer, "remove_brush", frame)
	
	undo_redo.add_do_method(editing_animation, "_update_end_frame")
	undo_redo.add_undo_method(editing_animation, "_update_end_frame")
	
	undo_redo.add_do_method(editing_animation, "goto", frame + 1)
	undo_redo.add_undo_method(editing_animation, "goto", frame)
	
	undo_redo.commit_action()


func contract_brush(frame):
	undo_redo.create_action("Remove Frame")
	
	for layer: Layer2D in editing_animation.layers:
		if editing_animation.current_frame >= editing_animation.length:
			continue
		if editing_brush.animation and layer != editing_brush.layer:
			continue
		undo_redo.add_do_method(layer, "remove_brush", frame)
		var brush = layer.get_brush(frame)
		if brush:
			undo_redo.add_undo_method(layer, "insert_frame", frame - 1)
			undo_redo.add_undo_method(layer, "set_brush", brush, frame)
		else:
			undo_redo.add_undo_method(layer, "insert_frame", frame)
	
	var max_frame = (
			editing_brush.layer.length - 1 if editing_brush.animation else
			editing_animation.length - 1
	)
	
	if frame >= max_frame:
		undo_redo.add_do_method(editing_animation, "goto", frame - 1)
		undo_redo.add_undo_method(editing_animation, "goto", frame)
	
	undo_redo.commit_action()


func duplicate_brush(frame: int):
	undo_redo.create_action("Convert Keybrush")
	
	var layer: Layer2D = get_selected_layer()
	if not layer.is_brush_start(frame):
		# Current frame is empty, insert a brush.
		
		var copy = layer.get_brush(min(frame, layer.length-1)).duplicate()
		undo_redo.add_do_method(layer, "set_brush", copy, frame)
		undo_redo.add_undo_method(layer, "remove_brush", frame)
		
		if layer.length < frame:
			undo_redo.add_do_property(layer, "length", frame)
			undo_redo.add_undo_property(layer, "length", layer.length)
		
	elif not layer.is_brush_start(frame + 1):
		# Current frame is start of a brush, add a brush to the next frame.
		var copy = layer.get_brush(frame).duplicate()
		undo_redo.add_do_method(layer, "set_brush", copy, frame + 1)
		undo_redo.add_undo_method(layer, "remove_brush", frame + 1)
		
		undo_redo.add_do_method(editing_animation, "goto", frame + 1)
		undo_redo.add_undo_method(editing_animation, "goto", frame)
	else:
		# Current and next brushes are a brushes, only move a brush forward.
		undo_redo.add_do_method(editing_animation, "goto", frame + 1)
		undo_redo.add_undo_method(editing_animation, "goto", frame)
	
	undo_redo.commit_action()


func new_brush(frame: int):
	undo_redo.create_action("Convert Blank Keybrush")
	
	var layer: Layer2D = get_selected_layer()
	if not layer.is_brush_start(frame):
		# No brush on frame,
		# start a new brush from this frame.
		var brush = Brush2D.new()
		undo_redo.add_do_method(layer, "set_brush", brush, frame)
		undo_redo.add_undo_method(layer, "remove_brush", frame)
		
		undo_redo.add_do_method(editing_animation, "goto", frame)
		undo_redo.add_undo_method(editing_animation, "goto", frame)
	elif not layer.is_brush_start(frame + 1):
		# There's a brush on this frame but not the next,
		# start a new brush on the next frame.
		var brush = Brush2D.new()
		undo_redo.add_do_method(layer, "set_brush", brush, frame + 1)
		undo_redo.add_undo_method(layer, "remove_brush", frame + 1)
		
		undo_redo.add_do_method(editing_animation, "goto", frame + 1)
		undo_redo.add_undo_method(editing_animation, "goto", frame)
	else:
		# This and the next frame are occupied,
		# just move to the next frame.
		undo_redo.add_do_method(editing_animation, "goto", frame + 1)
		undo_redo.add_undo_method(editing_animation, "goto", frame)
	
	undo_redo.commit_action()


func remove_brush(frame):
	var layer: Layer2D = get_selected_layer()
	var brush = layer.get_brush(editing_animation.current_frame)
	if brush:
		undo_redo.create_action("Remove Keybrush")
		undo_redo.add_do_method(layer, "remove_brush", editing_animation.current_frame)
		undo_redo.add_undo_method(layer, "set_brush", brush, editing_animation.current_frame)
		
		undo_redo.add_do_method(editing_animation, "goto", editing_animation.current_frame)
		undo_redo.add_undo_method(editing_animation, "goto", editing_animation.current_frame)
		
		undo_redo.commit_action()


func set_tool(tool):
	current_tool = tool
	#TODO: find hack for this hack
	#if not allow_editing:
		#button_select_mode.emit_signal("pressed")
	toolbar.select_tool(tool)


func set_erase_mode(value):
	erase_mode = value
	toolbar.set_erase_mode(value)


func set_draw_mode(paint_mode):
	current_draw_mode = paint_mode
	toolbar.set_draw_mode(paint_mode)


func set_warp_ease(warp_ease):
	current_warp_ease = warp_ease
	toolbar.set_warp_ease(warp_ease)


func _draw_brush(brush: Brush2D):
	var cursor_position = brush.get_local_mouse_position()
	
	for action in active_actions:
		action._draw_brush()
	
	match current_tool:
		TOOL_SELECT:
			if active_actions.size() == 0:
				if hover_edge_selections.size() > 0:
					draw_hover_edge_selections()
					
					var view_scale: float = editing_brush.get_view_scale().x
					for selection: EdgeSelection in hover_edge_selections:
						editing_brush.draw_circle(
								selection.closest_point, 5.0 / view_scale,
								Color.WHITE
						)
						_draw_circle_outline(
								editing_brush, selection.closest_point, 8.0 / view_scale,
								Color.WHITE, 1.0 / view_scale
						)
						
						_draw_range_circle(editing_brush, selection.closest_point, _action_warp_size)
				else:
					var alpha = lerp(0.0, 1.0, ease(_action_warp_size_preview_t, 0.4))
					_draw_range_circle(
							brush, brush.get_local_mouse_position(),
							_action_warp_size, alpha
					)
		TOOL_SMOOTH:
			if hover_edge_selections.size() > 0:
				draw_hover_edge_selections()
			
			var alpha = lerp(0.4, 1.0, ease(_action_warp_size_preview_t, 0.4))
			_draw_range_circle(
					brush, brush.get_local_mouse_position(),
					_action_warp_size, alpha
			)
	
	if _selected_highlight > 0.0:
		draw_brush_highlight(brush)



func draw_brush_highlight(brush: Brush2D):
	var view_scale: float = editing_brush.get_view_scale().x
	if _selected_highlight > 0.6 and fmod(_selected_highlight / 0.3, 1.0) > 0.5:
		return
	var thickness = 2.0 / view_scale
	for stroke: Stroke in brush.strokes:
		if stroke.polygon.size() < 3 or stroke._erasing:
			continue
		brush.draw_stroke_outline(
				stroke, thickness, selection_color, ease(_selected_highlight, 0.2)
		)


func draw_hover_edge_selections():
	var view_scale: float = editing_brush.get_view_scale().x
	for selection: EdgeSelection in hover_edge_selections:
		draw_edge_selection(selection)
		if selection.hole_id == -1:
			editing_brush.draw_polygon_outline(
					selection.stroke.polygon, 1.0 / view_scale,
					Color.WHITE, 0.5
			)
		else:
			editing_brush.draw_polygon_outline(
					selection.stroke.holes[selection.hole_id], 1.0 / view_scale,
					Color.WHITE, 0.5
			)


func draw_edge_selection(selection: EdgeSelection):
	var view_scale: float = editing_brush.get_view_scale().x
	var stroke = selection.stroke
	
	var polygon = stroke.polygon if selection.hole_id == -1 else stroke.holes[selection.hole_id]
	
	var color := Color.WHITE
	
	for i in selection.vertex_indices.size() - 1:
		var from = polygon[selection.vertex_indices[i]]
		var to = polygon[selection.vertex_indices[i + 1]]
		var thickness_from = selection.vertex_weights[i]
		var thickness_to = selection.vertex_weights[i + 1]
		
		var steps := 3.0
		for j in steps:
			var t_from = j / steps
			var t_to = (j + 1) / steps
			var pos_from = lerp(from, to, t_from)
			var pos_to = lerp(from, to, t_to)
			var thickness = lerp(thickness_from, thickness_to, j / steps) * 3.0 / view_scale
			editing_brush.draw_line(pos_from, pos_to, color, thickness)


func _draw_range_circle(brush, position, size, alpha = 1.0):
	var view_scale: float = brush.get_view_scale().x
	var color_outer = Color(0.0, 0.0, 0.0, 0.5 * alpha)
	var color_inner = Color(1.0, 1.0, 1.0, 1.0 * alpha)
	_draw_circle_outline(brush, position, size + 0.5 / view_scale, color_outer, 1.5 / view_scale)
	_draw_circle_outline(brush, position, size - 0.5 / view_scale, color_inner, 1.5 / view_scale)


func _draw():
	if allow_custom_cursor and allow_hide_cursor:
		_draw_custom_cursor()


func _draw_custom_cursor():
	if not editing_brush or _is_panning():
		return
	var view_scale: float = editing_brush.get_view_scale().x
	var cursor_position = get_local_mouse_position()
	match get_current_tool():
		TOOL_PAINT:
			var erasing := false
			if active_actions.size() > 0:
				if erasing:
					erasing = true
					var size = _action_paint_erase_size * 0.5 * view_scale
					_draw_circle_outline(
							self, cursor_position, size - 1.0, Color.BLACK, 1.0
					)
					_draw_circle_outline(
							self, cursor_position, size + 1.0, Color.WHITE, 1.0
					)
				else:
					var size = _action_paint_size * 0.5 * view_scale
					_draw_circle_outline(
							self, cursor_position, size - 1.0, Color.BLACK, 1.0
					)
					_draw_circle_outline(
							self, cursor_position, size + 1.0, Color.WHITE, 1.0
					)
			else:
				erasing = erase_mode
				var alpha_paint = 0.2 if erase_mode else 1.0
				var size_paint = _action_paint_size * 0.5 * view_scale
				_draw_circle_outline(
						self, cursor_position, size_paint - 1.0, Color.BLACK, 1.0, erase_mode
				)
				_draw_circle_outline(
						self, cursor_position, size_paint + 1.0, Color(1.0, 1.0, 1.0, alpha_paint),
						1.0, erase_mode
				)
				
				var alpha_erase = 1.0 if erase_mode else 0.2
				var size_erase = _action_paint_erase_size * 0.5 * view_scale
				_draw_circle_outline(
						self, cursor_position, size_erase - 1.0, Color.BLACK, 1.0, not erase_mode
				)
				_draw_circle_outline(
						self, cursor_position, size_erase + 1.0, Color(1.0, 1.0, 1.0, alpha_erase),
						1.0, not erase_mode
				)
			if erasing:
				# Erase mode, draw cross.
				draw_line(
						cursor_position - Vector2.ONE * 4.0,
						cursor_position + Vector2.ONE * 4.0,
						Color.WHITE, 2.0
					)
				draw_line(
						cursor_position + Vector2(1, -1) * 4.0,
						cursor_position + Vector2( -1, 1) * 4.0,
						Color.WHITE, 2.0
					)
			else:
				# Paint mode, draw dot.
				draw_circle(cursor_position, 2.0, Color.WHITE)
		TOOL_EYEDROPPER:
			var preview_size := 20.0
			var color = pick_color(editing_brush.get_local_mouse_position())
			draw_circle(cursor_position, 3.0, Color(0, 0, 0, 0.2))
			draw_texture(TextureEyedropper, cursor_position + Vector2(- 8, -16))
			
			var circle_position = cursor_position + Vector2.UP * 32.0
			draw_circle(circle_position, preview_size, color)
			_draw_circle_outline(self, circle_position, preview_size - 1.0, Color.BLACK)
			_draw_circle_outline(self, circle_position, preview_size + 1.0, Color.WHITE)
			
		TOOL_FILL:
			draw_texture(TextureFill, cursor_position)


func _draw_circle_outline(
		target, draw_position: Vector2, size: float, color: Color = Color.WHITE,
		width = 0.5, striped := false
):
	var point_count := 72.0
	var points = []
	if striped:
		for i in point_count:
			if int(i) % 8 < 5:
				continue
			var from = draw_position + Vector2.from_angle(i / point_count * TAU) * size
			var to = draw_position + Vector2.from_angle((i + 1) / point_count * TAU) * size
			draw_line(from, to, color, width, true)
	else:
		for i in point_count:
			points.push_back(draw_position + Vector2.from_angle(i / point_count * TAU) * size)
		points.push_back(points[0])
		target.draw_polyline(PackedVector2Array(points), color, width, true)


func get_current_tool() -> int:
	if current_tool_override != -1:
		return current_tool_override
	return current_tool


func _queue_redraw():
	queue_redraw()
	if editing_brush:
		editing_brush.queue_redraw()



func _is_panning():
	return Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)


func _is_main_screen_visible(screen: int):
	return EditorInterface.get_editor_main_screen().get_child(screen).visible


#region Layers


func remove_layer(layer: Layer2D):
	var clip = layer.get_clip()
	
	undo_redo.create_action("Remove Layer")
	undo_redo.add_do_method(clip, "remove_layer", layer)
	undo_redo.add_undo_method(clip, "add_layer", layer)
	undo_redo.add_do_method(timeline, "_on_layer_added_or_removed")
	undo_redo.add_undo_method(timeline, "_on_layer_added_or_removed")
	
	undo_redo.add_do_method(self, "set_editing_brush")
	undo_redo.add_undo_method(self, "set_editing_brush")
	
	undo_redo.commit_action()


func create_layer():
	if not editing_animation:
		return null
	
	var layer = editing_animation._create_layer()
	undo_redo.create_action("New Layer")
	undo_redo.add_do_method(editing_animation, "add_layer", layer)
	undo_redo.add_undo_method(editing_animation, "remove_layer", layer)
	undo_redo.add_do_method(timeline, "_on_layer_added_or_removed")
	undo_redo.add_undo_method(timeline, "_on_layer_added_or_removed")
	undo_redo.commit_action()
	return layer

#endregion
