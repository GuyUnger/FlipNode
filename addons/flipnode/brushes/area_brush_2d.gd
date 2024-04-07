@tool
class_name AreaBrush2D
extends Brush2D

signal mouse_entered
## Emitted when mouse is after pressing inside this area.
signal mouse_exited
## Emitted when mouse pressed inside this area.
signal mouse_pressed
## Emitted when mouse is released after pressing inside this area.
signal mouse_unpressed
## Emitted when mouse is released inside this area.
signal mouse_released
## Emitted when mouse is released inside this area, after pressing inside this area.
signal mouse_clicked

@export_flags_2d_physics var collision_layer: int = 1:
	set(value):
		collision_layer = value
		notify_property_list_changed()
@export_flags_2d_physics var collision_mask: int = 1:
	set(value):
		collision_mask = value
		notify_property_list_changed()

@export var clickable := true
var mouse_hovering := false
@export var disabled := false:
	set(value):
		if disabled == value:
			return
		disabled = value
		for child in area.get_children():
			if child is CollisionPolygon2D:
				child.disabled = value
		#if value:
			#for child in area.get_children():
				#if child is CollisionPolygon2D:
					#child.disabled = value
		#else:
			#for child in area.get_children():
				#if child is CollisionPolygon2D:
					#child.scale = Vector2.ONE

var area: Area2D


func _ready() -> void:
	if Engine.is_editor_hint():
		super()
		Flip.editor.screen_transform_changed.connect(queue_redraw)
		return
	area = Area2D.new()
	area.collision_layer = collision_layer
	area.collision_mask = collision_mask
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_area_mouse_entered)
	area.mouse_exited.connect(_on_area_mouse_exited)
	
	area.input_pickable = clickable
	add_child(area)
	for polygon in get_islands():
		var collision_polygon = CollisionPolygon2D.new()
		area.add_child(collision_polygon)
		collision_polygon.polygon = Flip.douglas_peucker(polygon, 3.0)


func _draw() -> void:
	super._draw()
	
	if Engine.is_editor_hint():
		draw_outline(1.0, Color("0198b1"))


func _on_area_input_event(viewport, event, shape):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_pressed.emit()
			get_tree().process_frame.connect(_process_release)
		else:
			mouse_released.emit()


func _process_release():
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		get_tree().process_frame.disconnect(_process_release)
		if mouse_hovering:
			mouse_clicked.emit()
		mouse_unpressed.emit()


func _on_area_mouse_entered():
	mouse_entered.emit()
	mouse_hovering = true


func _on_area_mouse_exited():
	mouse_exited.emit()
	mouse_hovering = false


func get_override_material(stroke):
	return Flip.MaterialArea
