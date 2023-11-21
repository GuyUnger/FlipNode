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
	if not is_instance_valid(layers):
		if has_node("Layers"):
			layers = get_node("Layers")
		else:
			layers = Node2D.new()
			add_child(layers)
	
	var layer_count = data.strokes.size()
	
	while layers.get_child_count() > layer_count:
		layers.remove_child(strokes[strokes.size() - 1])
		strokes.pop_back()
	
	while data.strokes.size() < layer_count:
		var stroke = BrushStroke2D.instantiate()
		add_child(stroke)
		strokes.push_back(stroke)
	
	for i in strokes_data.size():
		strokes[i].draw(strokes_data[i])
	while layers.get_child_count() < 
	
	for layer_data in layers_data:
		
		#.append_array(layer_data.get_frame(current_frame) )
	


func _draw():
	if Goulash.editor:
		Goulash.editor.forward_draw(self)


func _create_layer_data():
	var layer = BrushClipLayer.new()
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
