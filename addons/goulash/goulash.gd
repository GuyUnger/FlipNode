@tool
class_name Goulash extends EditorPlugin

enum {TOOL_SELECT, TOOL_PAINT, TOOL_FILL, TOOL_EYEDROPPER, TOOL_OVAL, TOOL_RECT, TOOL_PEN}
enum {ACTION_NONE, ACTION_WARP, ACTION_PAINT, ACTION_OVAL, ACTION_RECT, ACTION_MOVE}

static var editor: Goulash
static var default_fps := 12

var key_add_frame = KEY_5
var key_add_keyframe = KEY_6
var key_add_keyframe_blank = KEY_7
var key_paint = KEY_B
var key_play = KEY_S
var key_frame_next = KEY_D
var key_frame_previous = KEY_A
var key_decrease = KEY_BRACKETLEFT
var key_increase = KEY_BRACKETRIGHT

var toolbar
var timeline

var _current_action: int
var _action_position_previous: Vector2
var _action_alt := false
var _selected_layer_id: int
var _action_paint_stroke: BrushStrokeData

var current_tool := -1
var current_tool_override := -1
var current_color: Color = Color.WHITE

var _action_paint_size := 10.0
var _action_paint_erase_size := 20.0

var onion_skin_frames := 0

var editing_brush

var canvas_transform_previous

func _enter_tree():
	editor = self
	
	set_process(false)
	
	_init_project_settings()
	_load_project_settings()
	
	add_custom_type("BrushClip2D", "Node2D", load("res://addons/goulash/brush_clip2d.gd"), null)
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	
	toolbar = load("res://addons/goulash/ui/toolbar.tscn").instantiate()
	toolbar.visible = false
	toolbar.theme = EditorInterface.get_editor_theme()
	EditorInterface.get_editor_viewport_2d().get_parent().get_parent().add_child(toolbar)
	
	timeline = load("res://addons/goulash/ui/timeline.tscn").instantiate()
	add_control_to_bottom_panel(timeline, "Timeline")
	
	ProjectSettings.settings_changed.connect(_on_settings_changed)


func _init_project_settings():
	add_project_setting("goulash/animation/default_fps", 30)
	add_project_setting("goulash/painting/default_color", Color.PERU)


func add_project_setting(name: String, default_value) -> void:
	if ProjectSettings.has_setting(name):
		return
	ProjectSettings.set_setting(name, default_value)
	ProjectSettings.set_initial_value(name, default_value)


func _load_project_settings():
	default_fps = ProjectSettings.get_setting_with_override("goulash/animation/default_fps")
	current_color = ProjectSettings.get_setting_with_override("goulash/painting/default_color")


func _on_settings_changed():
	_load_project_settings()


func _exit_tree() -> void:
	remove_custom_type("BrushClip2D")
	
	remove_control_from_bottom_panel(timeline)
	if is_instance_valid(timeline):
		timeline.queue_free()
	
	if is_instance_valid(toolbar):
		toolbar.queue_free()


func _handles(object) -> bool:
	if object is BrushClip2D or object is BrushKeyframe2D or object is BrushSprite2D:
		return true
	return false


func _on_selection_changed():
	var selection := get_editor_interface().get_selection()
	var selected_nodes = selection.get_selected_nodes()
	if selected_nodes.size() == 1:
		if selected_nodes[0] is BrushClip2D:
			select_clip(selected_nodes[0])
			return
		elif selected_nodes[0] is BrushKeyframe2D:
			var frame: BrushKeyframe2D = selected_nodes[0]
			select_clip(frame.get_clip())
			frame.get_clip().goto(frame.frame_num)
			return
		elif selected_nodes[0] is BrushSprite2D:
			select_sprite(selected_nodes[0])
			return
	
	if editing_brush:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		timeline.load_brush_clip(null)
		_edit_brush_complete()


func select_sprite(sprite):
	_edit_brush_start(sprite)


func select_clip(clip):
	_edit_brush_start(clip)
	timeline.load_brush_clip(clip)
	toolbar._update_used_colors()
	clip.draw()
	return


func _edit_brush_start(brush):
	editing_brush = brush
	
	toolbar.visible = true
	set_process(true)


func _edit_brush_complete():
	var brush = editing_brush
	editing_brush.queue_redraw()
	editing_brush = null
	brush.draw()
	toolbar.visible = false
	set_process(false)


#region INPUT
func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not editing_brush:
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
		return false
	
	match event.keycode:
		KEY_ALT:
			_on_input_key_alt_pressed()
		key_play:
			if editing_brush is BrushClip2D:
				if editing_brush.is_playing:
					editing_brush.stop()
				else:
					editing_brush.play()
		key_frame_previous:
			if editing_brush is BrushClip2D:
				if editing_brush.previous_frame():
					return true
		key_frame_next:
			if editing_brush is BrushClip2D:
				if editing_brush.next_frame():
					return true
		KEY_Q:
			set_tool(Goulash.TOOL_SELECT)
			return true
		key_paint:
			set_tool(Goulash.TOOL_PAINT)
			return true
		KEY_R:
			set_tool(Goulash.TOOL_RECT)
			return true
		KEY_G:
			set_tool(Goulash.TOOL_FILL)
			return true
		KEY_O:
			set_tool(Goulash.TOOL_OVAL)
			return true
		KEY_P:
			set_tool(Goulash.TOOL_PEN)
			return true
		key_add_frame:
			if Input.is_key_pressed(KEY_SHIFT):
				pass
			else:
				_add_frame()
			return true
		key_add_keyframe:
			if Input.is_key_pressed(KEY_SHIFT):
				pass
			else:
				_convert_keyframe()
			return true
		key_add_keyframe_blank:
			if Input.is_key_pressed(KEY_SHIFT):
				pass
			else:
				_convert_keyframe_blank()
			return true
		key_decrease:
			_action_paint_erase_size *= 1 / (2.0 ** (1.0 / 6.0))
			_action_paint_size *= 1 / (2.0 ** (1.0 / 6.0))
			return true
		key_increase:
			_action_paint_erase_size *= 2.0 ** (1.0 / 6.0)
			_action_paint_size *= 2.0 ** (1.0 / 6.0)
			
			return true
	return false


func _on_key_released(event: InputEventKey) -> bool:
	match event.keycode:
		KEY_ALT:
			return _on_input_key_alt_released()
	return false


func _on_input_key_alt_pressed() -> bool:
	if current_tool == TOOL_PAINT:
		current_tool_override = TOOL_EYEDROPPER
		editing_brush.queue_redraw()
	return false


func _on_input_key_alt_released():
	current_tool_override = -1
	editing_brush.queue_redraw()
#endregion


func _process(delta):
	if not is_instance_valid(editing_brush):
		set_process(false)
		return
	if get_viewport().canvas_transform != canvas_transform_previous:
		canvas_transform_previous = editing_brush.get_viewport().get_screen_transform()
		editing_brush.queue_redraw()
	
	if current_tool == TOOL_PAINT and toolbar.get_rect().has_point(toolbar.get_local_mouse_position()):
		##todo: this needs more checks
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _add_frame():
	for layer in editing_brush.layers:
		layer.add_frame(editing_brush.current_frame)
	editing_brush.next_frame()
	editing_brush._update_frame_count()


func _convert_keyframe():
	var layer = _get_current_layer()
	if layer.is_frame_empty(editing_brush.current_frame):
		var copy = layer.get_frame(editing_brush.current_frame).duplicate()
		layer.set_keyframe(copy, editing_brush.current_frame)
		editing_brush._update_frame_count()
		return true
	elif layer.is_frame_empty(editing_brush.current_frame + 1):
		var copy = layer.get_frame(editing_brush.current_frame).duplicate()
		layer.set_keyframe(copy, editing_brush.current_frame + 1)
		editing_brush._update_frame_count()
		editing_brush.next_frame()
	else:
		editing_brush._update_frame_count()
		editing_brush.next_frame()


func _convert_keyframe_blank():
	var layer = _get_current_layer()
	if layer.is_frame_empty(editing_brush.current_frame):
		layer.set_keyframe(BrushKeyframe2D.new(), editing_brush.current_frame)
		editing_brush._update_frame_count()
		return true
	elif layer.is_frame_empty(editing_brush.current_frame + 1):
		layer.set_keyframe(BrushKeyframe2D.new(), editing_brush.current_frame + 1)
		editing_brush._update_frame_count()
		editing_brush.next_frame()
	else:
		editing_brush._update_frame_count()
		editing_brush.next_frame()


func set_tool(tool):
	current_tool = tool
	toolbar.select_tool(tool)


func _input_mouse(event: InputEventMouse) -> bool:
	var mouse_position = editing_brush.get_local_mouse_position()
	if event is InputEventMouseButton:
		var event_mouse_button: InputEventMouseButton = event
		if event_mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if event_mouse_button.pressed:
				_on_lmb_pressed(mouse_position)
			else:
				_on_lmb_released()
		elif event_mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			if event_mouse_button.pressed:
				_on_rmb_pressed(mouse_position)
			else:
				_on_rmb_released()
	elif event is InputEventMouseMotion:
		_on_mouse_motion(mouse_position)
	return true


func _on_mouse_motion(mouse_position):
	editing_brush.queue_redraw()
	match _current_action:
		ACTION_WARP:
			action_warp_process(mouse_position)
		ACTION_PAINT:
			action_paint_process(mouse_position)
		ACTION_MOVE:
			action_move_process(mouse_position)


func _on_lmb_pressed(mouse_position: Vector2):
	if _current_action != ACTION_NONE:
		return
	_action_alt = false
	_action_start(mouse_position, false)


func _on_rmb_pressed(mouse_position: Vector2):
	if _current_action != ACTION_NONE:
		return
	_action_alt = true
	_action_start(mouse_position, true)


func _on_lmb_released():
	current_action_complete()


func _on_rmb_released():
	current_action_complete()


func _action_start(mouse_position, alt):
	_action_alt = alt
	match _get_current_tool():
		TOOL_SELECT:
			if action_warp_try(mouse_position):
				return
			action_move_try(mouse_position)
		TOOL_PAINT:
			action_paint_start(mouse_position)
		TOOL_FILL:
			action_fill_try(mouse_position)
		TOOL_EYEDROPPER:
			for stroke: BrushStrokeData in _get_editing_sprite().stroke_data:
				if stroke.is_point_inside(mouse_position):
					current_color = stroke.color
					toolbar._update_color_picker_color()
		TOOL_OVAL:
			action_oval_start(mouse_position)


func current_action_complete():
	match _current_action:
		ACTION_WARP:
			action_warp_complete()
		ACTION_PAINT:
			action_paint_complete()
			toolbar._update_used_colors()
		ACTION_MOVE:
			action_move_complete()
	_current_action = ACTION_NONE


#func _select_frame(frame: BrushKeyframe2D):
	#_selected_frame = frame
	#
	#if frame.frame_num == editing_brush.current_frame:
		#return
	#
	#editing_brush.goto_frame(frame.frame_num)


func forward_draw(target: BrushClip2D):
	var zoom = target.get_viewport().get_screen_transform().get_scale().x
	var mouse_position = target.get_local_mouse_position()
	match _get_current_tool():
		TOOL_PAINT:
			if not (_current_action == ACTION_PAINT and _action_alt):
				_draw_circle_outline(target, mouse_position, _action_paint_size, Color.BLACK, 1.0 / zoom)
				_draw_circle_outline(target, mouse_position, _action_paint_size + 2.0 / zoom, Color.WHITE, 1.0 / zoom)
			else:
				_draw_circle_outline(target, mouse_position, _action_paint_erase_size, Color.BLACK, 1.0 / zoom, true)
			if not (_current_action == ACTION_PAINT and not _action_alt):
				_draw_circle_outline(target, mouse_position, _action_paint_erase_size, Color(1.0, 1.0, 1.0, 0.2), 1.0 / zoom, true)
			
			target.draw_circle(mouse_position, 2.0 / zoom, Color.WHITE)
		TOOL_SELECT:
			for stroke: BrushStrokeData in _get_editing_sprite().stroke_data:
				if _is_hovering_edge(stroke, mouse_position):
					target.draw_circle(
							stroke.polygon_curve.get_closest_point(mouse_position), 3.0, Color.WHITE
						)
		TOOL_EYEDROPPER:
			for stroke: BrushStrokeData in _get_editing_sprite().stroke_data:
				if stroke.is_point_inside(mouse_position):
					target.draw_circle(mouse_position, 32.0 / zoom, stroke.color)
					_draw_circle_outline(target, mouse_position, 32.0 / zoom, Color.WHITE)
				else:
					_draw_circle_outline(target, mouse_position, 20.0 / zoom, Color(1.0, 1.0, 1.0, 0.2))
				
				target.draw_circle(mouse_position, 2.0 / zoom, Color.WHITE)
	
	#match _current_action:
		#ACTION_OVAL:
			#_draw_action_oval()

func _draw_circle_outline(target, draw_position: Vector2, size: float, color: Color = Color.WHITE, width = 0.5, striped := false):
	var point_count := 36
	for i in point_count:
		if striped and i % 4 < 3:
			continue
		var from = draw_position + Vector2.RIGHT.rotated(i / float(point_count) * TAU) * size
		var to = draw_position + Vector2.RIGHT.rotated((i + 1) / float(point_count) * TAU) * size
		target.draw_line(from, to, color, width, true)


## ACTION WARP
var action_warp_selections := []

func action_warp_try(action_position: Vector2) -> bool:
	var range := 200.0
	for stroke in _get_editing_sprite().stroke_data:
		_warp_stroke_try(stroke, action_position, range)
	if action_warp_selections.size() > 0:
		_current_action = ACTION_WARP
		_action_position_previous = action_position
		return true
	return false


func _warp_stroke_try(stroke: BrushStrokeData, action_postion: Vector2, range: float):
	var closest_vertex_i = -1
	var closest_distance := 10.0
	
	var polygon = stroke.polygon
	var l = polygon.size()
	
	for vertex_i in l:
		var dist = action_postion.distance_to(polygon[vertex_i])
		if dist < closest_distance:
			closest_distance = dist
			closest_vertex_i = vertex_i
	
	if closest_vertex_i == -1:
		return
	
	var selection := ActionWarpSelection.new(stroke)
	action_warp_selections.push_back(selection)
	
	selection.add_vertex(closest_vertex_i, 1.0)
	
	## travel clockwise of dragging point 👉
	var total_dist := 0.0
	for i in int(l * 0.5) - 1:
		var vertex_i = (closest_vertex_i + i + 1) % l
		var vertex_i_prev = (closest_vertex_i + i) % l
		var dist = polygon[vertex_i].distance_to(polygon[vertex_i_prev])
		
		total_dist += dist
		if total_dist > range:
			## passed range, stop looking ✋
			break
		
		var weight = 1.0 - (total_dist / range)
		weight = _warp_ease(weight)
		selection.add_vertex(vertex_i, weight)
	
	## travel counterclockwise of dragging point 👈
	total_dist = 0.0
	for i in int(l * 0.5) - 1:
		var vertex_i = (closest_vertex_i - i - 1) % l
		var vertex_i_prev = (closest_vertex_i - i) % l
		var dist = polygon[vertex_i].distance_to(polygon[vertex_i_prev])
		
		total_dist += dist
		if total_dist > range:
			## passed range, stop looking ✋
			break
		
		var weight = 1.0 - (total_dist / range)
		weight = _warp_ease(weight)
		selection.add_vertex(vertex_i, weight)


func _is_hovering_edge(stroke, mouse_position):
	if not stroke.polygon_curve:
		stroke.create_curves()
	var closest_point = stroke.polygon_curve.get_closest_point(mouse_position)
	return closest_point.distance_to(mouse_position) < 10.0


func action_warp_complete():
	for selection: ActionWarpSelection in action_warp_selections:
		merge_stroke(selection.stroke)
	for selection: ActionWarpSelection in action_warp_selections:
		selection.stroke.optimize()
	for selection: ActionWarpSelection in action_warp_selections:
		if Geometry2D.is_polygon_clockwise(selection.stroke.polygon):
			selection.stroke.polygon.reverse()
		var invert_fix_results = Geometry2D.offset_polygon(selection.stroke.polygon, 0.0, Geometry2D.JOIN_ROUND)
		
		_get_editing_sprite().stroke_data.erase(selection.stroke)
		for polygon in invert_fix_results:
			_get_editing_sprite().add_stroke(BrushStrokeData.new(polygon, [], selection.stroke.color))
	_get_editing_sprite().draw()
	action_warp_selections = []


func action_warp_process(action_position):
	var move_delta = action_position - _action_position_previous
	_action_position_previous = action_position
	
	for selection: ActionWarpSelection in action_warp_selections:
		for i in selection.vertex_count():
			var index = selection.vertex_indexes[i]
			var weight = selection.vertex_weights[i]
			selection.stroke.polygon[index] += move_delta * weight
	
	_get_editing_sprite().draw()

func _warp_ease(t):
	if _action_alt:
		return ease(t, 2.0)
	else:
		return ease(t, -1.5)


class ActionWarpSelection:
	var stroke: BrushStrokeData
	var vertex_indexes := []
	var vertex_weights := []
	
	
	func _init(stroke: BrushStrokeData):
		self.stroke = stroke
	
	
	func add_vertex(index: int, weight: float):
		var i = vertex_indexes.find(index)
		if i != -1:
			## already has this vertex, use the heighest weight
			vertex_weights = max(vertex_weights[i], weight)
			return
		
		vertex_indexes.push_back(index)
		vertex_weights.push_back(weight)
	
	
	func vertex_count():
		return vertex_indexes.size()


class ActionWarpSelectionHole extends ActionWarpSelection:
	var hole_id := 0


## ACTION MOVE

var moving_stroke
func action_move_try(action_position: Vector2) -> bool:
	for stroke: BrushStrokeData in _get_editing_sprite().stroke_data:
		if stroke.is_point_inside(action_position):
			moving_stroke = stroke
			_action_position_previous = action_position
			_current_action = ACTION_MOVE
			return true
	return false


func action_move_complete():
	merge_stroke(moving_stroke)
	moving_stroke = null


func action_move_process(action_position: Vector2):
	moving_stroke.translate(action_position - _action_position_previous)
	_action_position_previous = action_position


## ACTION FILL

func action_fill_try(action_position: Vector2):
	for stroke: BrushStrokeData in _get_editing_sprite().stroke_data:
		if stroke.is_point_inside(action_position):
			stroke.color = current_color
			merge_stroke(stroke)
			return
	for stroke: BrushStrokeData in _get_editing_sprite().stroke_data:
		for i in stroke.holes.size():
			if Geometry2D.is_point_in_polygon(action_position, stroke.holes[i]):
				if stroke.color == current_color:
					stroke.holes.remove_at(i)
				else:
					var polygon = stroke.holes[i].duplicate()
					polygon.reverse()
					_get_editing_sprite().add_stroke(BrushStrokeData.new(polygon, [], current_color))
				return


## ACTION BRUSH

func action_paint_start(action_position: Vector2):
	_current_action = ACTION_PAINT
	
	_action_position_previous = action_position
	
	var color = Color.WHITE if _action_alt else current_color
	_action_paint_stroke = BrushStrokeData.new([], [], color)
	_get_editing_sprite().add_stroke(_action_paint_stroke)
	
	action_paint_process(action_position)


func action_paint_complete():
	_action_paint_stroke.optimize()
	if _action_alt:
		_action_paint_complete_subtract()
	else:
		_action_paint_complete_add()


func _action_paint_complete_add():
	var strokes := []
	while _get_editing_sprite().stroke_data.size() > 0:
		var stroke = _get_editing_sprite().stroke_data.pop_front()
		if stroke == _action_paint_stroke:
			continue
		if _action_paint_stroke.is_stroke_overlapping(stroke):
			if _action_paint_stroke.color == stroke.color:
				_action_paint_stroke.union_stroke(stroke)
			else:
				strokes.append_array(stroke.subtract_stroke(_action_paint_stroke))
		else:
			strokes.push_back(stroke)
	
	strokes.push_back(_action_paint_stroke)
	
	for stroke in strokes:
		_get_editing_sprite().add_stroke(stroke)
	
	_action_paint_stroke = null
	_get_editing_sprite().draw()


func _action_paint_complete_subtract():
	var strokes := []
	_get_editing_sprite().stroke_data.erase(_action_paint_stroke)
	while _get_editing_sprite().stroke_data.size() > 0:
		var stroke: BrushStrokeData = _get_editing_sprite().stroke_data.pop_front()
		strokes.append_array(stroke.subtract_stroke(_action_paint_stroke))
	
	for stroke in strokes:
		_get_editing_sprite().add_stroke(stroke)
	
	_action_paint_stroke = null
	_get_editing_sprite().draw()


func action_paint_process(action_position: Vector2):
	var brush_size = _action_paint_erase_size if _action_alt else _action_paint_size
	var brush_polygon = _create_polygon_circle(_action_position_previous, action_position, brush_size)
	_action_paint_stroke.union_polygon(brush_polygon)
	_action_position_previous = action_position
	_get_editing_sprite().draw()


func _create_polygon_circle(start_position: Vector2, end_position: Vector2, size: float) -> PackedVector2Array:
	var angle = start_position.angle_to_point(end_position)
	var brush_polygon = []
	var points := 16.0
	for i in points:
		brush_polygon.push_back(start_position + Vector2.DOWN.rotated(angle + i / points * PI) * size)
	for i in points:
		brush_polygon.push_back(end_position + Vector2.DOWN.rotated(angle + PI + i / points * PI) * size)
	return PackedVector2Array(brush_polygon)

## ACTION OVAL

func action_oval_start(action_position):
	_current_action = ACTION_OVAL
	
	_action_position_previous = action_position

#func action_oval_complete():
	#

#func _draw_action_oval():
	#

func merge_stroke(stroke):
	_action_paint_stroke = stroke
	_action_paint_complete_add()


func _get_editing_sprite() -> BrushSprite2D:
	if editing_brush is BrushSprite2D:
		return editing_brush
	else:
		return editing_brush.layers[_selected_layer_id].get_frame(editing_brush.current_frame)

func _get_current_layer():
	return editing_brush.layers[_selected_layer_id]


func _get_current_tool() -> int:
	if current_tool_override != -1:
		return current_tool_override
	return current_tool
