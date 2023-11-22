@tool
extends Control

const ButtonUsedColor = preload("res://addons/goulash/ui/button_used_color.tscn")

@onready var buttons := [
	%ButtonSelect,
	%ButtonBrush,
	%ButtonOval,
	%ButtonRect,
	%ButtonEyedropper,
	%ButtonFill,
	%ButtonShape,
]

@onready var properties_containers := [
	%PropertiesSelect,
	%PropertiesBrush,
	%PropertiesFill,
]

var _used_colors := []


func _ready():
	_update_color_picker_color()


func _update_used_colors():
	if GoulashEditor.editor.editing_brush == null:
		return
	
	for button in %UsedColors.get_children():
		button.queue_free()
	_used_colors = []
	for layer in GoulashEditor.editor.editing_brush.layers:
		for keyframe in layer.keyframes:
			for stroke in keyframe.stroke_data:
				if not _used_colors.has(stroke.color):
					_add_used_color(stroke.color)


func _add_used_color(color):
	_used_colors.push_back(color)
	var button = ButtonUsedColor.instantiate()
	button.modulate = color
	%UsedColors.add_child(button)


func _on_button_select_pressed():
	GoulashEditor.set_tool(GoulashEditor.TOOL_SELECT)


func _on_button_brush_pressed():
	GoulashEditor.set_tool(GoulashEditor.TOOL_PAINT)


func _on_button_fill_pressed():
	GoulashEditor.set_tool(GoulashEditor.TOOL_FILL)


func _on_button_oval_pressed():
	GoulashEditor.set_tool(GoulashEditor.TOOL_OVAL)


func _on_button_rect_pressed():
	GoulashEditor.set_tool(GoulashEditor.TOOL_RECT)


func _on_button_pen_pressed():
	GoulashEditor.set_tool(GoulashEditor.TOOL_SHAPE)


func _on_button_eyedropper_pressed():
	GoulashEditor.set_tool(GoulashEditor.TOOL_EYEDROPPER)


func select_tool(tool):
	match tool:
		GoulashEditor.TOOL_SELECT:
			set_pressed(%ButtonSelect)
			show_properties(%PropertiesSelect)
		GoulashEditor.TOOL_PAINT:
			set_pressed(%ButtonBrush)
			show_properties(%PropertiesBrush)
		GoulashEditor.TOOL_SHAPE:
			set_pressed(%ButtonPen)
			show_properties()
		GoulashEditor.TOOL_OVAL:
			set_pressed(%ButtonOval)
			show_properties()
		GoulashEditor.TOOL_RECT:
			set_pressed(%ButtonRect)
			show_properties()
		GoulashEditor.TOOL_EYEDROPPER:
			set_pressed(%ButtoEyedropper)
			show_properties()
		GoulashEditor.TOOL_FILL:
			set_pressed(%ButtonFill)
			show_properties(%PropertiesFill)


func _on_color_picker_color_changed(color):
	if GoulashEditor.editor.current_color == color:
		return
	GoulashEditor.editor.current_color = color


func _update_color_picker_color():
	%ColorPicker.color = GoulashEditor.editor.current_color


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
	GoulashEditor.editor.forward_draw(self)

func _input(event):
	if event is InputEventMouseMotion:
		GoulashEditor.allow_custom_cursor = true
		if %Tools.get_rect().has_point(get_local_mouse_position()):
			GoulashEditor.allow_custom_cursor = false
		if %Colors.get_rect().has_point(get_local_mouse_position()):
			GoulashEditor.allow_custom_cursor = false
