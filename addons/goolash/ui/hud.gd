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
	_update_color_picker_color()


func _update_used_colors():
	if GoolashEditor.editor.editing_node == null:
		return
	for button in %UsedColors.get_children():
		button.queue_free()
	_used_colors = []
	for c in %DefaultColors.get_children():
		_used_colors.push_back(c.self_modulate.to_html())
	if GoolashEditor.editor.editing_node is BrushClip2D:
		for layer in GoolashEditor.editor.editing_node.layers:
			for keyframe in layer.keyframes:
				for stroke in keyframe.strokes:
					if not _used_colors.has(stroke.color.to_html()):
						_add_used_color(stroke.color.to_html())
	else:
		for stroke in GoolashEditor.editor._editing_brush.strokes:
			if not _used_colors.has(stroke.color.to_html()):
				_add_used_color(stroke.color.to_html())


func _add_used_color(color):
	_used_colors.push_back(color)
	var button = ButtonUsedColor.instantiate()
	button.set_color(Color(color))
	%UsedColors.add_child(button)


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
	%ColorPicker.color = GoolashEditor.editor.current_color


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
		if %Colors.get_rect().has_point(get_local_mouse_position()):
			GoolashEditor.allow_custom_cursor = false
		
		if %MenuPaintMode.visible:
			if %MenuPaintMode.get_rect().has_point(%MenuPaintMode.get_parent().get_local_mouse_position()):
				GoolashEditor.allow_custom_cursor = false
	
		if event is InputEventMouseButton:
			if not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
				if allow_paintmode_close:
					%MenuPaintMode.visible = false
				else:
					allow_paintmode_close = true

var allow_paintmode_close := false

func _on_button_paint_mode_button_down():
	%MenuPaintMode.visible = true
	allow_paintmode_close = false


@onready var paint_mode_textures = [
	preload("res://addons/goolash/icons/paint_mode_front.svg"),
	preload("res://addons/goolash/icons/paint_mode_behind.svg"),
	preload("res://addons/goolash/icons/paint_mode_inside.svg"),
]

func set_paint_mode(paint_mode):
	%ButtonPaintMode.icon = paint_mode_textures[paint_mode]


func _on_button_pain_mode_front_button_up():
	GoolashEditor.set_paint_mode(GoolashEditor.PAINT_MODE_FRONT)
	%MenuPaintMode.visible = false


func _on_button_pain_mode_behind_button_up():
	GoolashEditor.set_paint_mode(GoolashEditor.PAINT_MODE_BEHIND)
	%MenuPaintMode.visible = false


func _on_button_pain_mode_inside_button_up():
	GoolashEditor.set_paint_mode(GoolashEditor.PAINT_MODE_INSIDE)
	%MenuPaintMode.visible = false


func _on_button_erase_mode_toggled(toggled_on):
	GoolashEditor.erase_mode = toggled_on


func set_erase_mode(value: bool):
	%ButtonEraseMode.button_pressed = value
