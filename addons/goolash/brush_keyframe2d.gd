@tool
@icon("res://addons/goolash/icons/BrushKeyframe2D.svg")
class_name BrushKeyframe2D
extends Brush2D

@export var frame_num: int
@export var frame_end_num: int
@export var label: String:
	get:
		return label
	set(value):
		label = value
		if Engine.is_editor_hint():
			update_name()

@export var has_custom_script := false


func copy() -> BrushKeyframe2D:
	var frame = BrushKeyframe2D.new()
	frame.stroke_data = strokes_data.duplicate()
	return frame

func _ready():
	if Engine.is_editor_hint():
		has_custom_script = get_script().source_code != GoolashEditor.KEYFRAME_SCRIPT.source_code
		update_name()
	super()


func get_clip() -> BrushClip2D:
	return get_parent().get_parent()


func get_layer() -> BrushLayer2D:
	return get_parent()


func enter():
	_enter_frame()


func _enter_frame():
	pass


func clear():
	for stroke_data in strokes_data:
		remove_child(stroke_data.stroke)
	strokes_data.clear()


func update_name():
	if label != "":
		name = "Frame %s" % label.capitalize()
	else:
		name = "Frame %s" % frame_num
	if has_custom_script:
		name += " 📃"


func is_blank() -> bool:
	return strokes_data.size() == 0


func get_override_material(stroke) -> Material:
	if stroke._erasing:
		return GoolashEditor.StrokeEraseMaterial
	else:
		var clip = get_clip()
		if clip.material:
			return clip.material
		else:
			return super.get_override_material(stroke)
