@tool
extends Control

const ButtonUsedColor = preload("res://addons/goolash/ui/button_used_color.tscn")

@onready var buttons := [
	%ButtonSelect,
	%ButtonPaint,
	%ButtonOval,
	%ButtonRect,
	%ButtonEyedropper,
	%ButtonFill,
	%ButtonShape,
]

@onready var properties_containers := [
	%PropertiesSelect,
	%PropertiesPaint,
	%PropertiesFill,
]

var _used_colors := []


func _ready():
	_update_default_swatches()
	_update_color_picker_color()
	
	GoolashEditor.editor.brush_edited.connect(_update_brush_stats)
	GoolashEditor.editor.selected_brush_changed.connect(_update_brush_stats)


func _update_brush_stats():
	var brush = GoolashEditor.editor._editing_brush
	var strokes = brush.strokes.size()
	var vertices = 0
	for stroke in brush.strokes:
		vertices += stroke.get_vertex_count()
	%Stats.text = "strokes: %s\nvertices: %s" % [strokes, vertices]


func _update_default_swatches():
	for button in %DefaultSwatches.get_children():
		button.queue_free()
	
	for color in GoolashEditor.editor.default_swatches:
		_add_swatch(color, %DefaultSwatches)


func _update_used_colors():
	if GoolashEditor.editor.editing_node == null:
		return
	for button in %UsedColors.get_children():
		button.queue_free()
	_used_colors = []
	for c in %DefaultSwatches.get_children():
		_used_colors.push_back(c.self_modulate.to_html())
	if GoolashEditor.editor.editing_node is BrushAnimation2D:
		for layer in GoolashEditor.editor.editing_node.layers:
			for keyframe in layer.keyframes:
				for stroke in keyframe.strokes:
					if not _used_colors.has(stroke.color.to_html()):
						_add_swatch(stroke.color, %UsedColors)
	else:
		for stroke in GoolashEditor.editor._editing_brush.strokes:
			if not _used_colors.has(stroke.color.to_html()):
				_add_swatch(stroke.color, %UsedColors)


func _add_swatch(color: Color, to: Control):
	_used_colors.push_back(color.to_html())
	var button = ButtonUsedColor.instantiate()
	button.set_color(color)
	to.add_child(button)


func _on_button_select_pressed():
	GoolashEditor.set_tool(GoolashEditor.TOOL_SELECT)


func _on_button_paint_pressed():
	GoolashEditor.set_tool(GoolashEditor.TOOL_PAINT)


func _on_button_fill_pressed():
	GoolashEditor.set_tool(GoolashEditor.TOOL_FILL)


func _on_button_oval_pressed():
	GoolashEditor.set_tool(GoolashEditor.TOOL_OVAL)


func _on_button_rect_pressed():
	GoolashEditor.set_tool(GoolashEditor.TOOL_RECT)


func _on_button_pen_pressed():
	GoolashEditor.set_tool(GoolashEditor.TOOL_SHAPE)


func _on_button_eyedropper_pressed():
	GoolashEditor.set_tool(GoolashEditor.TOOL_EYEDROPPER)


func select_tool(tool):
	match tool:
		GoolashEditor.TOOL_SELECT:
			set_pressed(%ButtonSelect)
			show_properties(%PropertiesSelect)
		GoolashEditor.TOOL_PAINT:
			set_pressed(%ButtonPaint)
			show_properties(%PropertiesPaint)
		GoolashEditor.TOOL_SHAPE:
			set_pressed(%ButtonShape)
			show_properties()
		GoolashEditor.TOOL_OVAL:
			set_pressed(%ButtonOval)
			show_properties()
		GoolashEditor.TOOL_RECT:
			set_pressed(%ButtonRect)
			show_properties()
		GoolashEditor.TOOL_EYEDROPPER:
			set_pressed(%ButtoEyedropper)
			show_properties()
		GoolashEditor.TOOL_FILL:
			set_pressed(%ButtonFill)
			show_properties(%PropertiesFill)


func _on_color_picker_color_changed(color):
	if GoolashEditor.editor.current_color == color:
		return
	GoolashEditor.editor.current_color = color


func _update_color_picker_color():
	%ColorPicker.set_color(GoolashEditor.editor.current_color)


func show_properties(properties = null):
	for p: Control in properties_containers:
		p.visible = false
	if properties:
		properties.visible = true


func set_pressed(button: Button):
	for b: Button in buttons:
		b.button_pressed = false
	button.button_pressed = true


func _draw():
	GoolashEditor.editor._forward_draw_hud()


func _input(event):
	if event is InputEventMouseMotion:
		GoolashEditor.allow_custom_cursor = true
		if %Tools.get_rect().has_point(get_local_mouse_position()):
			GoolashEditor.allow_custom_cursor = false
		if %ColorPicker.get_rect().has_point(%ColorPanels.get_local_mouse_position()):
			GoolashEditor.allow_custom_cursor = false
		if %Swatches.get_rect().has_point(%ColorPanels.get_local_mouse_position()):
			GoolashEditor.allow_custom_cursor = false
		
		if %MenuPaintMode.visible:
			if %MenuPaintMode.get_rect().has_point(%MenuPaintMode.get_parent().get_local_mouse_position()):
				GoolashEditor.allow_custom_cursor = false
	
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
	GoolashEditor.erase_mode = toggled_on


#region Paint Mode


var allow_paintmode_close := false

func set_paint_mode(paint_mode):
	%ButtonPaintMode.icon = %PaintModeButtons.get_child(paint_mode).icon
	%MenuPaintMode.visible = false


func _on_button_paint_mode_button_down():
	%MenuPaintMode.visible = true
	allow_paintmode_close = false


func _on_button_pain_mode_front_button_up():
	GoolashEditor.set_paint_mode(GoolashEditor.PAINT_MODE_FRONT)


func _on_button_pain_mode_behind_button_up():
	GoolashEditor.set_paint_mode(GoolashEditor.PAINT_MODE_BEHIND)


func _on_button_pain_mode_inside_button_up():
	GoolashEditor.set_paint_mode(GoolashEditor.PAINT_MODE_INSIDE)


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
	GoolashEditor.set_warp_ease(GoolashEditor.WARP_EASE_SMOOTH)


func _on_button_warp_ease_sharp_button():
	GoolashEditor.set_warp_ease(GoolashEditor.WARP_EASE_SHARP)


func _on_button_warp_ease_linear_button():
	GoolashEditor.set_warp_ease(GoolashEditor.WARP_EASE_LINEAR)


func _on_button_warp_ease_random_button():
	GoolashEditor.set_warp_ease(GoolashEditor.WARP_EASE_RANDOM)

#endregion
