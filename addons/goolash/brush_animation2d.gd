@tool
@icon("res://addons/goolash/icons/BrushAnimation2D.svg")
class_name BrushAnimation2D
extends Node2D

signal frame_changed
signal edited

@export var current_frame: int = 0:
	get:
		return current_frame
	set(value):
		if free_after_playing and not Engine.is_editor_hint():
			if value > _frame_count:
				queue_free()
		elif looping:
			value %= _frame_count
		else:
			value = clamp(value, 0, _frame_count - 1)
		current_frame = value
		if Engine.is_editor_hint():
			#TODO: replace this with signal?
			GoolashEditor.editor._get_editing_brush()
		draw()
		frame_changed.emit()

@export var _frame_count := 1:
	get:
		return _frame_count

var frame_count: int: 
	get:
		return _frame_count

@export_range(0, 120) var fps_override := 0

@export var auto_play := true
@export var looping := true
@export var is_playing := false

@export var labels: Dictionary
var layers: Array

var next_frame_delay := 0.0

var _editing_layer_num := 0 #Stored here so it can be remembered during the session 

#TODO: turn this into an enum with looping
@export var free_after_playing := false

func _validate_property(property):
	var hidden = ["labels", "_frame_count"]
	if hidden.has(property.name):
		property.usage = PROPERTY_USAGE_STORAGE


func _ready():
	_find_layers()
	if Engine.is_editor_hint():
		init()
		stop()
	else:
		if auto_play:
			play()
	current_frame = 0


func init():
	if layers.size() == 0:
		await get_tree().process_frame
		add_layer(_create_layer())
	for layer: BrushLayer2D in layers:
		layer.find_keyframes()
		if layer.keyframes.size() == 0:
			layer.set_keyframe(BrushKeyframe2D.new(), 0)
	_update_frame_count()


func draw():
	for layer: BrushLayer2D in layers:
		layer.display_frame(current_frame)


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
func goto_and_stop(frame_num_or_label):
	goto(frame_num_or_label)
	is_playing = false


## Helper function to both go to a specified frame/label, and start/continue playing.
func goto_and_play(frame_num_or_label):
	goto(frame_num_or_label)
	is_playing = true


## Helper function to both go to a specified frame or label, and start/continue playing.
func goto(frame_num_or_label):
	if frame_num_or_label is int:
		current_frame = frame_num_or_label
	elif frame_num_or_label is String:
		if labels.has(frame_num_or_label):
			current_frame = labels[frame_num_or_label]
		else:
			push_error("label '%s' doesn't exist." % frame_num_or_label)
	else:
		push_error("goto_and_stop only takes ints (frame number) or strings (label names).")


func _create_layer(add_child := true) -> BrushLayer2D:
	var layer = BrushLayer2D.new()
	layer.name = "Layer %s" % (layers.size() + 1)
	layer.set_keyframe(BrushKeyframe2D.new(), 0)
	return layer


func _find_layers():
	layers = []
	for i in get_child_count():
		var child = get_child(i)
		if child is BrushLayer2D:
			child.modulate = Color.WHITE
			child.layer_num = i
			layers.push_back(child)


func _update_frame_count():
	_frame_count = 1
	for layer in layers:
		_frame_count = max(_frame_count, layer.frame_count)


func _get_fps():
	if fps_override > 0:
		return fps_override
	else:
		return Goolash.default_fps


func add_layer(layer: BrushLayer2D):
	add_child(layer)
	move_child(layer, layer.layer_num)
	layer.owner = owner
	for keyframe in layer.keyframes:
		keyframe.owner = owner
	_find_layers()
	_editing_layer_num = min(_editing_layer_num, layers.size() - 1)


func remove_layer(layer: BrushLayer2D):
	remove_child(layer)
	layer.owner = null
	_find_layers()
	_editing_layer_num = min(_editing_layer_num, layers.size() - 1)

