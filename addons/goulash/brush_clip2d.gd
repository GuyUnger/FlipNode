@tool
@icon("res://addons/goulash/brush_clip.svg")
class_name BrushClip2D extends Node2D

const BrushStroke2D = preload("res://addons/goulash/brush_stroke2d.tscn")

signal frame_changed


@export var current_frame: int = 0:
	get:
		return current_frame
	set(value):
		current_frame = value % (_frame_count)
		frame_changed.emit()
		_redraw()

@export var _frame_count := 1:
	get:
		return _frame_count

var total_frames: int:
	get:
		return _frame_count

@export_range(0, 120) var fps_override := 0

@export var auto_play := true
@export var is_playing := false

@export var layers: Array
@export var labels: Dictionary

@export var expose_frames_in_tree := false

## DISPLAY
var _brushes: Array

var next_frame_delay := 0.0

func _ready():
	if layers.size() == 0:
		_create_layer()
	
	if auto_play and not Engine.is_editor_hint():
		play()
	else:
		stop()
	_redraw()


func _process(delta):
	if is_playing:
		next_frame_delay -= delta
		if next_frame_delay <= 0:
			next_frame_delay += 1.0 / _get_fps()
			current_frame += 1


func play():
	is_playing = true


func stop():
	is_playing = false


func next_frame() -> bool:
	if current_frame < _frame_count - 1:
		current_frame += 1
		return true
	return false


func previous_frame() -> bool:
	if current_frame > 0:
		current_frame -= 1
		return true
	return false


## Helper function to both go to a specified frame/label, and stop playing.
func goto_and_stop(frame_or_label):
	goto(frame_or_label)
	is_playing = false


## Helper function to both go to a specified frame/label, and start/continue playing.
func goto_and_play(frame_or_label):
	is_playing = true


## Helper function to both go to a specified frame or label, and start/continue playing.
func goto(frame_or_label):
	if frame_or_label is int:
		current_frame = frame_or_label
	elif frame_or_label is String:
		if labels.has(frame_or_label):
			current_frame = labels[frame_or_label]
		else:
			push_error("label '%s' doesn't exist." % frame_or_label)
	else:
		push_error("goto_and_stop only takes ints (frame number) or strings (label names).")


func _redraw():
	var shapes := []
	
	for layer in layers:
		shapes.append_array(layer.get_shapes(current_frame) )
	
	var shape_count = shapes.size()
	while _brushes.size() < shape_count:
		var brush_shape = BrushStroke2D.instantiate()
		add_child(brush_shape)
		_brushes.push_back(brush_shape)
	
	while _brushes.size() > shape_count:
		remove_child(_brushes[_brushes.size()-1])
		_brushes.pop_back()
	
	for i in shapes.size():
		_brushes[i].draw(shapes[i])

func _draw():
	if Goulash.editor:
		Goulash.editor.forward_draw(self)


func _create_layer():
	var layer = BrushClipLayer.new()
	layers.push_back(layer)


func _update_frame_count():
	var count = 1
	for layer in layers:
		count = max(count, layer.frame_count)
	_frame_count = count


func _get_fps():
	if fps_override > 0:
		return fps_override
	else:
		return Goulash.default_fps
