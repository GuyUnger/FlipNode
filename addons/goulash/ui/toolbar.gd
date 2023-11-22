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
	%ButtonPen,
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
	if Goulash.editor.editing_brush == null:
		return
	
	for button in %UsedColors.get_children():
		button.queue_free()
	_used_colors = []
	for layer in Goulash.editor.editing_brush.layers:
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
	Goulash.editor.set_tool(Goulash.TOOL_SELECT)


func _on_button_brush_pressed():
	Goulash.editor.set_tool(Goulash.TOOL_PAINT)


func _on_button_fill_pressed():
	Goulash.editor.set_tool(Goulash.TOOL_FILL)


func _on_button_oval_pressed():
	Goulash.editor.set_tool(Goulash.TOOL_OVAL)


func _on_button_rect_pressed():
	Goulash.editor.set_tool(Goulash.TOOL_RECT)


func _on_button_pen_pressed():
	Goulash.editor.set_tool(Goulash.TOOL_PEN)


func _on_button_eyedropper_pressed():
	Goulash.editor.set_tool(Goulash.TOOL_EYEDROPPER)


func select_tool(tool):
	match tool:
		Goulash.TOOL_SELECT:
			set_pressed(%ButtonSelect)
			show_properties(%PropertiesSelect)
		Goulash.TOOL_PAINT:
			set_pressed(%ButtonBrush)
			show_properties(%PropertiesBrush)
		Goulash.TOOL_PEN:
			set_pressed(%ButtonPen)
			show_properties()
		Goulash.TOOL_OVAL:
			set_pressed(%ButtonOval)
			show_properties()
		Goulash.TOOL_RECT:
			set_pressed(%ButtonRect)
			show_properties()
		Goulash.TOOL_EYEDROPPER:
			set_pressed(%ButtoEyedropper)
			show_properties()
		Goulash.TOOL_FILL:
			set_pressed(%ButtonFill)
			show_properties(%PropertiesFill)


func _on_color_picker_color_changed(color):
	if Goulash.editor.current_color == color:
		return
	Goulash.editor.current_color = color


func _update_color_picker_color():
	%ColorPicker.color = Goulash.editor.current_color


func show_properties(properties = null):
	for p: Control in properties_containers:
		p.visible = false
	if properties:
		properties.visible = true


func set_pressed(button: Button):
	for b: Button in buttons:
		b.button_pressed = false
	button.button_pressed = true
