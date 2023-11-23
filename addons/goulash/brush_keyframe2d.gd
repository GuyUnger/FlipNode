@tool
@icon("res://addons/goulash/icons/BrushKeyframe2D.svg")
class_name BrushKeyframe2D
extends BrushSprite2D

@export var frame_num: int
@export var frame_end_num: int
@export var label: String:
	get:
		return label
	set(value):
		label = value
		update_name()

@export var tweening := false
@export var key_transform: Transform2D

#func copy() -> Keyframe2D:
	#var frame = Keyframe.new()
	### todo: check if deep is necessary
	#sprite_data.duplicate()
	#return frame

func _ready():
	if not Engine.is_editor_hint():
		set_process(false)
	update_name()
	super()


func get_clip() -> BrushClip2D:
	return get_parent().get_parent()


func get_layer() -> BrushLayer2D:
	return get_parent()


func _enter_frame():
	pass


func clear():
	stroke_data.clear()
	draw()


func update_name():
	if label != "":
		name = "Frame %s" % label.capitalize()
		return
	name = "Frame %s" % frame_num
	if is_blank():
		name += " (Blank)"


func is_blank() -> bool:
	return stroke_data.size() == 0


func _process(delta):
	if get_clip().current_frame == frame_num:
		key_transform = transform
