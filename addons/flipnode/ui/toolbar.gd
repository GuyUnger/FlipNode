@tool
class_name Toolbar extends Control

const ButtonUsedColor = preload("res://addons/flipnode/ui/button_used_color.tscn")

var editor: FlipEditor

@onready var buttons := [
	%ButtonSelect,
	%ButtonPaint,
	%ButtonOval,
	%ButtonRect,
	%ButtonEyedropper,
	%ButtonFill,
	%ButtonShape,
	%ButtonSmooth,
]

@onready var properties_containers := [
	%PropertiesSelect,
	%PropertiesPaint,
	%PropertiesFill,
	%PropertiesSmooth,
]

var _used_colors := []


func _ready():
	update_default_swatches()
	update_color_picker_color()


func init(editor):
	self.editor = editor
	editor.brush_edited.connect(_on_brush_changed)
	editor.editing_brush_changed.connect(_on_brush_changed)
	editor.tool_settings_changed.connect(_on_tool_settings_changed)
	editor.editing_animation_changed.connect(on_editing_animation_changed)


func on_editing_animation_changed():
	update_used_colors()


func _on_brush_changed(brush):
	if not brush:
		return
	var strokes = brush.strokes.size()
	var vertices = 0
	for stroke in brush.strokes:
		vertices += stroke.get_vertex_count()
	%Stats.text = "strokes: %s\nvertices: %s" % [strokes, vertices]


func _on_tool_settings_changed():
	match Flip.editor.current_tool:
		FlipEditor.TOOL_PAINT:
			%InputPaintSize.text = "%2.1f" % Flip.editor._action_paint_size
			%InputPaintEraseSize.text = "%2.1f" % Flip.editor._action_paint_erase_size
		FlipEditor.TOOL_SMOOTH:
			%InputSmoothSize.text = "%2.1f" % Flip.editor._action_warp_size


func update_default_swatches():
	for button in %DefaultSwatches.get_children():
		button.queue_free()
	
	for color in Flip.editor.default_swatches:
		add_swatch(color, %DefaultSwatches)


func update_used_colors():
	if not is_instance_valid(Flip.editor.editing_brush):
		return
	for button in %UsedColors.get_children():
		button.queue_free()
	_used_colors = []
	for c in %DefaultSwatches.get_children():
		_used_colors.push_back(c.self_modulate.to_html())
	if Flip.editor.editing_animation:
		for layer in Flip.editor.editing_animation.layers:
			for brush in layer.brushes:
				for stroke in brush.strokes:
					if not _used_colors.has(stroke.color.to_html()):
						add_swatch(stroke.color, %UsedColors)
	else:
		for stroke in Flip.editor.editing_brush.strokes:
			if not _used_colors.has(stroke.color.to_html()):
				add_swatch(stroke.color, %UsedColors)


func add_swatch(color: Color, to: Control):
	_used_colors.push_back(color.to_html())
	var button = ButtonUsedColor.instantiate()
	button.set_color(color)
	to.add_child(button)


#region Select Tools


func _on_button_select_pressed():
	Flip.editor.set_tool(FlipEditor.TOOL_SELECT)


func _on_button_paint_pressed():
	Flip.editor.set_tool(FlipEditor.TOOL_PAINT)


func _on_button_fill_pressed():
	Flip.editor.set_tool(FlipEditor.TOOL_FILL)


func _on_button_oval_pressed():
	Flip.editor.set_tool(FlipEditor.TOOL_OVAL)


func _on_button_rect_pressed():
	Flip.editor.set_tool(FlipEditor.TOOL_RECT)


func _on_button_pen_pressed():
	Flip.editor.set_tool(FlipEditor.TOOL_SHAPE)


func _on_button_eyedropper_pressed():
	Flip.editor.set_tool(FlipEditor.TOOL_EYEDROPPER)


func _on_button_smooth_pressed():
	Flip.editor.set_tool(FlipEditor.TOOL_SMOOTH)


func select_tool(tool):
	match tool:
		FlipEditor.TOOL_SELECT:
			set_pressed(%ButtonSelect)
			show_properties(%PropertiesSelect)
		FlipEditor.TOOL_PAINT:
			set_pressed(%ButtonPaint)
			show_properties(%PropertiesPaint)
		FlipEditor.TOOL_SHAPE:
			set_pressed(%ButtonShape)
			show_properties()
		FlipEditor.TOOL_OVAL:
			set_pressed(%ButtonOval)
			show_properties()
		FlipEditor.TOOL_RECT:
			set_pressed(%ButtonRect)
			show_properties()
		FlipEditor.TOOL_EYEDROPPER:
			set_pressed(%ButtoEyedropper)
			show_properties()
		FlipEditor.TOOL_FILL:
			set_pressed(%ButtonFill)
			show_properties(%PropertiesFill)
		FlipEditor.TOOL_SMOOTH:
			set_pressed(%ButtonSmooth)
			show_properties(%PropertiesSmooth)
			%InputSmoothStrength.text = "%1.2f" % Flip.editor._action_smooth_strength


#endregion


func _on_color_picker_color_changed(color):
	if Flip.editor.current_color == color:
		return
	Flip.editor.current_color = color


func update_color_picker_color():
	%ColorPicker.set_color(Flip.editor.current_color)


func show_properties(properties = null):
	for p: Control in properties_containers:
		p.visible = false
	if properties:
		properties.visible = true


func set_pressed(button: Button):
	for b: Button in buttons:
		b.button_pressed = false
	button.button_pressed = true


func _input(event):
	if event is InputEventMouseMotion:
		Flip.editor.allow_custom_cursor = true
		if %Tools.get_rect().has_point(get_local_mouse_position()):
			Flip.editor.allow_custom_cursor = false
		if %ColorPicker.get_rect().has_point(%ColorPanels.get_local_mouse_position()):
			Flip.editor.allow_custom_cursor = false
		if %Swatches.get_rect().has_point(%ColorPanels.get_local_mouse_position()):
			Flip.editor.allow_custom_cursor = false
		
		if %MenuPaintMode.visible:
			if %MenuPaintMode.get_rect().has_point(%MenuPaintMode.get_parent().get_local_mouse_position()):
				Flip.editor.allow_custom_cursor = false
	
	if event is InputEventMouseButton:
		if not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			if %MenuPaintMode.visible:
				if allow_paintmode_close:
					%MenuPaintMode.visible = false
				else:
					allow_paintmode_close = true
			
			if %MenuWarpEase.visible:
				if allow_warp_ease_close:
					%MenuWarpEase.visible = false
				else:
					allow_warp_ease_close = true


func _on_button_erase_mode_toggled(toggled_on):
	Flip.editor.erase_mode = toggled_on


#region Paint Mode


var allow_paintmode_close := false


func set_draw_mode(paint_mode):
	%ButtonPaintMode.icon = %PaintModeButtons.get_child(paint_mode).icon
	%MenuPaintMode.visible = false


func _on_button_paint_mode_button_down():
	%MenuPaintMode.visible = true
	allow_paintmode_close = false


func _on_button_pain_mode_front_button_up():
	Flip.editor.set_draw_mode(Flip.DRAW_MODE_FRONT)


func _on_button_pain_mode_behind_button_up():
	Flip.editor.set_draw_mode(Flip.DRAW_MODE_BEHIND)


func _on_button_pain_mode_inside_button_up():
	Flip.editor.set_draw_mode(Flip.DRAW_MODE_INSIDE)


func set_erase_mode(value: bool):
	%ButtonEraseMode.button_pressed = value

#endregion


#region Warp Ease

var allow_warp_ease_close := false
func _on_button_warp_ease_button_down():
	%MenuWarpEase.visible = true
	allow_warp_ease_close = false


func set_warp_ease(warp_ease):
	%ButtonWarpEase.icon = %WarpEaseButtons.get_child(warp_ease).icon


func _on_button_warp_ease_smooth_button():
	Flip.editor.set_warp_ease(Flip.WARP_EASE_SMOOTH)


func _on_button_warp_ease_sharp_button():
	Flip.editor.set_warp_ease(Flip.WARP_EASE_SHARP)


func _on_button_warp_ease_linear_button():
	Flip.editor.set_warp_ease(Flip.WARP_EASE_LINEAR)


func _on_button_warp_ease_random_button():
	Flip.editor.set_warp_ease(Flip.WARP_EASE_RANDOM)

#endregion



func _on_input_paint_size_focus_exited():
	if %InputPaintSize.text.is_valid_float():
		Flip.editor._action_paint_size = float(%InputPaintSize.text)
	else:
		%InputPaintSize.text = Flip.editor._action_paint_size


func _on_input_paint_erase_size_focus_exited():
	if %InputPaintEraseSize.text.is_valid_float():
		Flip.editor._action_paint_erase_size = float(%InputPaintEraseSize.text)
	else:
		%InputPaintEraseSize.text = Flip.editor._action_paint_erase_size


func _on_input_smooth_strength_text_submitted(new_text):
	%InputSmoothStrength.release_focus()


func _on_input_smooth_strength_focus_exited():
	if %InputSmoothStrength.text.is_valid_float():
		Flip.editor._action_smooth_strength = %InputSmoothStrength.text
	else:
		%InputSmoothStrength.text = "%1.2f" % Flip.editor._action_smooth_size


func _on_button_focus_pressed() -> void:
	editor.show_focus = %ButtonFocus.button_pressed
	editor.update_focus_frame()
