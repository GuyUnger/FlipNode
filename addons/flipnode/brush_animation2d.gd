@tool
@icon("res://addons/flipnode/icons/BrushAnimation2D.svg")
class_name BrushAnimation2D
extends Node2D

signal frame_changed
signal edited

@export var current_frame: int = 0:
	get:
		return current_frame
	set(value):
		if current_frame == value:
			return
		
		if current_clip != null:
			if value > current_clip.y:
				if looping:
					value = current_clip.x
				else:
					value = current_clip.y
		elif free_after_playing and not Engine.is_editor_hint():
			if value > length:
				queue_free()
		elif looping:
			value %= length
		else:
			value = clamp(value, 0, length - 1)
		current_frame = value
		frame_changed.emit()
		draw()

@export var length := 1

@export_range(0, 120) var fps := 0.0

@export var auto_play := true
@export var looping := true
@export var is_playing := false

@export var clips: Dictionary
var current_clip
var layers: Array

var next_frame_delay := 0.0

#TODO turn this into an enum with looping
@export var free_after_playing := false


func _ready():
	_find_layers()
	if Engine.is_editor_hint():
		init()
		stop()
		return
	
	if auto_play:
		play()
	current_frame = 0


func init():
	if layers.size() == 0:
		await get_tree().process_frame
		add_layer(_create_layer())
	for layer: Layer2D in layers:
		layer.find_brushes()
		if layer.brushes.size() == 0:
			layer.set_brush(Brush2D.new(), 0)
	_update_end_frame()


func draw():
	for layer: Layer2D in layers:
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
	if current_frame < length - 1:
		current_frame += 1
		return true
	return false


func previous_frame() -> bool:
	if current_frame > 0:
		current_frame -= 1
		return true
	return false


## Helper function to both seek and start/continue playing.
## `value` can be a frame or clip name.
func goto_and_play(value):
	goto(value)
	is_playing = true


## Helper function to both seek and stop playing.
## `value` can be a frame or clip name.
func goto_and_stop(value):
	goto(value)
	is_playing = false


## Go to a frame or beginning of a clip
func goto(value):
	current_clip = null
	if value is int:
		current_frame = value
	elif value is String:
		if clips.has(value):
			current_clip = clips[value]
			current_frame = current_clip.x
		else:
			push_error("clip '%s' doesn't exist." % value)
	else:
		push_error("goto_and_stop only takes ints (brush number) or strings (clip names).")


func play_clip(clip_name: String, force_from_start := false):
	if not clips.has(clip_name):
		push_error("clip '%s' doesn't exist." % clip_name)
		return
	
	current_clip = clips[clip_name]
	if force_from_start:
		current_frame = current_clip.x
	else:
		if current_frame < current_clip.x or current_frame > current_clip.y:
			current_frame = current_clip.x


func _create_layer() -> Layer2D:
	var layer = Layer2D.new()
	layer.name = "Layer %s" % (layers.size() + 1)
	layer.set_brush(Brush2D.new(), 0)
	return layer


func _find_layers():
	layers = []
	for child in get_children():
		if child is Layer2D:
			layers.push_back(child)
			if not child.tree_exited.is_connected(_on_layer_exited):
				child.tree_exited.connect(_on_layer_exited)


func _update_end_frame():
	length = 1
	for layer in layers:
		length = max(length, layer.length)


func _get_fps():
	if fps > 0:
		return fps
	else:
		return Flip.default_fps


func add_layer(layer: Layer2D):
	add_child(layer)
	layer.owner = owner
	for brush in layer.brushes:
		brush.owner = owner
	_find_layers()


func remove_layer(layer: Layer2D):
	remove_child(layer)
	layer.owner = null
	_find_layers()


func get_current_brush(layer := 0):
	return layers[layer].get_brush(current_frame)


func _on_layer_exited():
	_find_layers()
	#TODO: find a way to do this with signals
	#Flip.editor.timeline.load_brush_animation(self)
