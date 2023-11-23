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
	if GoolashEditor.editor.editing_brush == null:
		return
	
	for button in %UsedColors.get_children():
		button.queue_free()
	_used_colors = []
	if GoolashEditor.editor.editing_brush is BrushClip2D:
		for layer in GoolashEditor.editor.editing_brush.layers:
			for keyframe in layer.keyframes:
				for stroke in keyframe.stroke_data:
					if not _used_colors.has(stroke.color):
						_add_used_color(stroke.color)
	else:
		for stroke in GoolashEditor.editor.editing_brush.stroke_data:
			if not _used_colors.has(stroke.color):
				_add_used_color(stroke.color)


func _add_used_color(color):
	_used_colors.push_back(color)
	var button = ButtonUsedColor.instantiate()
	button.modulate = color
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
			set_pressed(%ButtonPen)
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
	GoolashEditor.editor.forward_draw(self)

func _input(event):
	if event is InputEventMouseMotion:
		GoolashEditor.allow_custom_cursor = true
		if %Tools.get_rect().has_point(get_local_mouse_position()):
			GoolashEditor.allow_custom_cursor = false
		if %Colors.get_rect().has_point(get_local_mouse_position()):
			GoolashEditor.allow_custom_cursor = false
