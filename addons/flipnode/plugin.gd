@tool
extends EditorPlugin

var button_select_mode: Button

func _enter_tree():
	# Create editor.
	Flip.editor = load("res://addons/flipnode/ui/editor.tscn").instantiate()
	
	Flip.editor.accent_color = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
	Flip.editor.selection_color = Color("ff8000")
	Flip.editor.clear_color = ProjectSettings.get_setting(
			"rendering/environment/defaults/default_clear_color", Color.WHITE
	)
	
	_init_project_settings()
	_load_project_settings(true)
	
	Flip.editor.undo_redo = get_undo_redo()
	Flip.editor.visible = false
	Flip.editor.theme = EditorInterface.get_editor_theme()
	EditorInterface.get_editor_viewport_2d().get_parent().get_parent().add_child(Flip.editor)
	
	var timeline = load("res://addons/flipnode/ui/timeline.tscn").instantiate()
	Flip.editor.timeline = timeline
	add_control_to_bottom_panel(Flip.editor.timeline, "Timeline")
	timeline.init(Flip.editor)
	
	ProjectSettings.settings_changed.connect(_on_settings_changed)
	
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	
	
	var toolbar = get_editor_interface().get_editor_main_screen()\
			.get_child(0).get_child(0).get_child(0).get_child(0)
	button_select_mode = toolbar.get_child(0)
	var button_move_mode: Button = toolbar.get_child(2)
	var button_rotate_mode: Button = toolbar.get_child(4)
	var button_scale_mode: Button = toolbar.get_child(6)
	
	button_select_mode.pressed.connect(_on_mode_changed)
	button_move_mode.pressed.connect(_on_mode_changed)
	button_rotate_mode.pressed.connect(_on_mode_changed)
	button_scale_mode.pressed.connect(_on_mode_changed)
	
	Flip.editor.allow_editing = button_select_mode.button_pressed


func _exit_tree() -> void:
	remove_custom_type("BrushAnimation2D")
	
	remove_control_from_bottom_panel(Flip.editor.timeline)
	Flip.editor.timeline.queue_free()
	
	Flip.editor.queue_free()
	
	var toolbar = get_editor_interface().get_editor_main_screen().get_child(0).get_child(0).get_child(0).get_child(0)
	var button_move_mode: Button = toolbar.get_child(2)
	var button_rotate_mode: Button = toolbar.get_child(4)
	var button_scale_mode: Button = toolbar.get_child(6)
	
	button_select_mode.pressed.disconnect(_on_mode_changed)
	button_move_mode.pressed.disconnect(_on_mode_changed)
	button_rotate_mode.pressed.disconnect(_on_mode_changed)
	button_scale_mode.pressed.disconnect(_on_mode_changed)


func _on_mode_changed():
	Flip.editor.allow_editing = button_select_mode.button_pressed
	#TODO: this
	#EditorInterface.inspect_object(editing_node)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _init_project_settings():
	# Animation.
	_add_project_setting("animation", "default_fps", 12)
	_add_project_setting("animation", "onion_skin_enabled", true)
	_add_project_setting("animation", "onion_skin_frames", 2)
	
	# Painting.
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
	_add_project_setting("painting", "default_swatches", default_swatches)
	_add_project_setting("painting", "default_paint_size", 8.0)
	
	_add_keybind("tools", "paint_tool", "key_tool_select_paint", KEY_P)
	_add_keybind("tools", "oval_tool", "key_tool_select_oval", KEY_O)
	_add_keybind("tools", "rectangle_tool", "key_tool_select_rectangle", KEY_M)
	_add_keybind("tools", "shape_tool", "key_tool_select_shape", KEY_Y)
	_add_keybind("tools", "fill_tool", "key_tool_select_fill", KEY_G)
	_add_keybind("tools", "smooth_tool", "key_tool_select_smooth", KEY_T)
	_add_keybind("tools", "incease_tool_size", "key_tool_size_decrease", KEY_BRACKETLEFT)
	_add_keybind("tools", "decrease_tool_size", "key_tool_size_increase", KEY_BRACKETRIGHT)
	_add_keybind("timeline", "play_pause", "key_play", KEY_SLASH)
	_add_keybind("timeline", "next_frame", "key_next_frame", KEY_PERIOD)
	_add_keybind("timeline", "previous_frame", "key_previous_frame", KEY_COMMA)
	_add_keybind("timeline", "extend_brush_frames", "key_extend_brush", KEY_N)
	_add_keybind("timeline", "add_new_brush", "key_new_brush", KEY_B)
	_add_keybind("timeline", "duplicate_brush", "key_duplicate_brush", KEY_V)


var keybind_settings: Dictionary

func _add_keybind(section: String, alias: String, variable: String, default_key: int):
	section = "shortcuts/%s" % section
	var character = char(default_key)
	
	
	_add_project_setting(section, alias, character)
	keybind_settings[variable] = "flipnode/%s/%s" % [section, alias]


func _add_project_setting(category, name: String, default_value) -> void:
	var path = "flipnode/%s/%s" % [category, name]
	
	if ProjectSettings.has_setting(path):
		return
	ProjectSettings.set_setting(path, default_value)
	ProjectSettings.set_initial_value(path, default_value)


func _load_project_settings(init := false):
	Flip.editor.onion_skin_enabled = ProjectSettings.get_setting_with_override("flipnode/animation/onion_skin_enabled")
	Flip.editor.onion_skin_frames = ProjectSettings.get_setting_with_override("flipnode/animation/onion_skin_frames")
	
	var project_default_swatches = ProjectSettings.get_setting_with_override("flipnode/painting/default_swatches")
	Flip.editor.default_swatches = project_default_swatches
	
	for variable in keybind_settings.keys():
		var path = keybind_settings[variable]
		var value: String = ProjectSettings.get_setting_with_override(path)
		
		var value_changed := false
		if value != value.to_upper():
			value = value.to_upper()
			value_changed = true
		if value.length() > 1:
			value_changed = true
			value = value[value.length()-1]
		if value_changed:
			ProjectSettings.set_setting(path, value)
		var keycode = value.unicode_at(0)
		Flip.editor[variable] = keycode


func _on_settings_changed():
	_load_project_settings()


func _handles(object) -> bool:
	if object is BrushAnimation2D or object is Brush2D or object is Layer2D:
		return true
	return false


#region Node Selection


func _on_selection_changed():
	var selection := get_editor_interface().get_selection()
	var selected_nodes = selection.get_selected_nodes()
	
	if selected_nodes.size() == 1:
		if select_node(selected_nodes[0]):
			Flip.editor.open()
			return
	else:
		select_node(null)
	Flip.editor.close()


func select_node(node):
	if node is BrushAnimation2D:
		Flip.editor.select_animation(node)
		Flip.editor.select_brush(Flip.editor.get_selected_layer().get_brush(node.current_frame))
		return true
	elif node is Brush2D:
		if Flip.editor.editing_brush == node:
			printt("reselect")
			return
		if node.animation:
			node.animation.goto(node.frame_num)
			Flip.editor.select_animation(node.animation)
			Flip.editor.select_layer(node.layer)
			Flip.editor.select_brush(node)
		else:
			Flip.editor.select_brush(node)
		
		#for timeline_keybrush in get_tree().get_nodes_in_group("timeline_keybrushes"):
			#if timeline_keybrush.keybrush == keybrush:
				#timeline_keybrush.grab_focus()
		
		return true
	elif node is Layer2D:
		Flip.editor.select_animation(node.animation)
		Flip.editor.select_layer(node)
		return true
	Flip.editor.select_animation(null)
	Flip.editor.select_brush(null)
	return false


func _forward_canvas_gui_input(event):
	if not Flip.editor.allow_editing:
		return false
	return Flip.editor._forward_canvas_gui_input(event)
