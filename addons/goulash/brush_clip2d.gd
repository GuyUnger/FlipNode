@tool
@icon("res://addons/goulash/brush_clip.svg")
class_name BrushClip2D
extends Node2D

signal frame_changed

@export var current_frame: int = 0:
	get:
		return current_frame
	set(value):
		current_frame = value % (_frame_count)
		frame_changed.emit()

@export var _frame_count := 1:
	get:
		return _frame_count

var total_frames: int:
	get:
		return _frame_count

@export_range(0, 120) var fps_override := 0

@export var auto_play := true
@export var is_playing := false

@export var layers_data: Array
@export var labels: Dictionary

@export var expose_frames_in_tree := false

## DISPLAY
var layers: Node2D

var next_frame_delay := 0.0

func _ready():
	if layers_data.size() == 0:
		_create_layer_data()
	
	if auto_play and not Engine.is_editor_hint():
		play()
	else:
		stop()
	draw()


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


func draw():
	var layer_count = layers_data.size()
	for i in layer_count:
		var layer_data = layers_data[i]
		var layer = BrushLayer2D.new()
		layer.name = layer_data.name
		layer.layer_data = layer_data
		add_child(layer)
		layer.draw()
		layer.owner = owner


func _draw():
	if Goulash.editor:
		Goulash.editor.forward_draw(self)


func _create_layer_data():
	var layer = BrushLayerData.new()
	layers_data.push_back(layer)


func _update_frame_count():
	_frame_count = 1
	for layer_data in layers_data:
		_frame_count = max(_frame_count, layer_data.frame_count)


func _get_fps():
	if fps_override > 0:
		return fps_override
	else:
		return Goulash.default_fps
