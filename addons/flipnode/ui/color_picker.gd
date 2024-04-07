@tool
extends Panel

@onready var container: SubViewportContainer = %SubViewportContainer 
@onready var viewport: SubViewport = %SubViewport
@onready var hue_picker: Control = %HuePicker

enum {MODE_NONE, MODE_PICKING_COLOR, MODE_PICKING_HUE}
var mode := 1

var sv: Vector2

var h := 0.0
var temperature: float = 0.0

func _ready():
	set_process(false)


func _process(delta):
	var texture: ViewportTexture = viewport.get_texture()
	
	match mode:
		MODE_PICKING_COLOR:
			sv = container.get_local_mouse_position() / Vector2(viewport.size)
			sv.x = clamp(sv.x, 0, 1)
			sv.y = clamp(1.0 - sv.y, 0, 1)
		MODE_PICKING_HUE:
			h = hue_picker.get_local_mouse_position().y / hue_picker.get_rect().size.y
			h = clamp(h, 0, 1.0)
	
	queue_redraw()
	
	var color_to = get_color(h, sv.x, sv.y)
	Flip.editor.current_color = color_to
	
	%ColorPreviewTop.modulate = color_to
	%LineEditHex.text = color_to.to_html()


func _draw():
	var sv_picker_position = Vector2(sv.x, 1.0 - sv.y) * Vector2(viewport.size)
	$Indicator.position = sv_picker_position
	#draw_circle(sv_picker_position, 2.0, Color.WHITE)
	%HueIndicator.position.y = h * hue_picker.get_rect().size.y
	%Palette.material.set_shader_parameter("h", h)
	var color = get_color(h, sv.x, sv.y)
	%ColorPreviewTop.modulate = color
	%ColorPreviewBottom.modulate = color


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


func _on_temperature_value_changed(value):
	temperature = value
	%Palette.material.set_shader_parameter("temperature", value)


func find_valley(color) -> Vector3:
	var position: Vector3 = Vector3.ONE * 0.5
	var step_size: float = 0.1
	
	var directions := [
			Vector3.UP, Vector3.DOWN,
			Vector3.LEFT, Vector3.RIGHT,
			Vector3.FORWARD, Vector3.BACK,
		]
	temperature = 1.0
	var current_value = validate(color, position)
	for i in 200:
		var neighbors := []
		
		for direction in directions:
			var v = validate(color, position + direction * step_size)
			neighbors.push_back(validate(color, position + direction * step_size))
		
		var min_neighbor_value = neighbors.min()
		if min_neighbor_value < current_value:
			var min_index = neighbors.find(min_neighbor_value)
			position += directions[min_index] * step_size
			position.x = clamp(position.x, 0.0, 1.0)
			position.y = clamp(position.y, 0.0, 1.0)
			position.z = clamp(position.z, 0.0, 1.0)
			current_value = min_neighbor_value
		
		step_size *= 0.97
		step_size = max(step_size, 1.0 / 256.0)
		temperature *= 1.0 - min_neighbor_value * 0.01
	return position


func validate(color_a, hsv_b):
	var color_b = get_color(
			clamp(hsv_b.x, 0.0, 1.0),
			clamp(hsv_b.y, 0.0, 1.0),
			clamp(hsv_b.z, 0.0, 1.0)
		)
	
	var color_a_vec3 = Vector3(color_a.r, color_a.g, color_a.b)
	var color_b_vec3 = Vector3(color_b.r, color_b.g, color_b.b)
	
	return color_a_vec3.distance_to(color_b_vec3)


func hsv2rgb(hsv: Vector3) -> Vector3:
	var color = Color.RED
	color.h = hsv.x
	color.s = hsv.y
	color.v = hsv.z
	return Vector3(color.r, color.g, color.b)


func rgb2hsv(rgb: Vector3) -> Vector3:
	var color = Color(rgb.x, rgb.y, rgb.z)
	return Vector3(color.h, color.s, color.v)


func get_color(h: float, s: float, v: float) -> Color:
	var hsv_in: Vector3 = Vector3(h, s, v)
	
	var hsv: Vector3 = hsv_in
	hsv.y *= lerp(1.0, hsv.z, 0.4)
	hsv.y = 1.0 - pow(1.0 - hsv.y, 2.0)
	var color: Vector3 = hsv2rgb(hsv)
	
	color = lerp(color, hsv2rgb(Vector3(0.66, hsv.y, hsv.z)), (1.0 - hsv_in.z) * 0.8)
	color = lerp(color, hsv2rgb(Vector3(0.16, hsv.y, hsv.z)), (1.0 - hsv_in.y) * 0.7)
	
	var blue_yellow: Vector3 = lerp(Vector3(0.15, 0.4, 0.6), Vector3(1.0, 1.0, 0.4), pow(v, 2.0 - s * 1.5))
	color = lerp(color, blue_yellow, sin(hsv_in.z * PI) * 0.12)
	
	color = rgb2hsv(color)
	color.y = lerp(hsv_in.y, 1.0 - pow(1.0 - color.y, 1.5), 0.8)
	color = hsv2rgb(color)
	
	color = lerp(hsv2rgb(hsv_in), color, temperature)
	color = lerp(hsv2rgb(hsv_in), color, temperature)
	
	var c = Color(color.x, color.y, color.z)
	
	return c


func set_color(color: Color, use_temperature := false):
	%LineEditHex.text = color.to_html()
	if not use_temperature:
		sv = Vector2(color.s, color.v)
		h = color.h
	else:
		var valley = find_valley(color)
		sv = Vector2(valley.y, 1.0 - valley.z)
		h = valley.x
	Flip.editor.current_color = color
	queue_redraw()


func _on_line_edit_hex_text_submitted(new_text):
	%LineEditHex.release_focus()


func _on_line_edit_hex_focus_exited():
	if Color.html_is_valid(%LineEditHex.text):
		set_color(Color(%LineEditHex.text))
