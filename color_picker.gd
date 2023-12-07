@tool
extends PanelContainer

@onready var container: SubViewportContainer = %SubViewportContainer 
@onready var viewport: SubViewport = %SubViewport
@onready var hue_picker: Control = %HuePicker

enum {MODE_NONE, MODE_PICKING_COLOR, MODE_PICKING_HUE}
var mode := 0

var picking_position: Vector2

func _ready():
	set_process(false)


func _process(delta):
	var texture: ViewportTexture = viewport.get_texture()
	
	match mode:
		MODE_PICKING_COLOR:
			picking_position = container.get_local_mouse_position()
			picking_position.x = clamp(picking_position.x, 0, viewport.size.x - 1)
			picking_position.y = clamp(picking_position.y, 0, viewport.size.y - 1)
		MODE_PICKING_HUE:
			var value = hue_picker.get_local_mouse_position().y / hue_picker.get_rect().size.y
			value = clamp(value, 0, 1.0)
			%Palette.material.set_shader_parameter("h", value)
	
	var color_to = texture.get_image().get_pixel(picking_position.x, picking_position.y)
	GoolashEditor.editor.current_color = color_to
	
	%ColorPreviewTop.modulate = color_to
	%LineEditHex.text = color_to.to_html()


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if container.get_rect().has_point(container.get_parent().get_local_mouse_position()):
				set_process(true)
				mode = MODE_PICKING_COLOR
			elif hue_picker.get_rect().has_point(hue_picker.get_parent().get_local_mouse_position()):
				set_process(true)
				mode = MODE_PICKING_HUE
		else:
			set_process(false)
			%ColorPreviewBottom.modulate = %ColorPreviewTop.modulate
	if event is InputEventMouseMotion:
		if get_rect().has_point(get_parent().get_local_mouse_position()):
			GoolashEditor.editor.allow_hide_cursor = false



func _on_temperature_value_changed(value):
	%Palette.material.set_shader_parameter("temperature", value)
