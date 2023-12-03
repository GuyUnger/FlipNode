@tool
class_name BrushClip3D extends Sprite3D

@onready var brush_clip2d = $SubViewport/BrushClip2D

var current_frame: int: 
	get:
		return brush_clip2d.current_frame
	set(value):
		brush_clip2d.current_frame = value

@export var is_playing: bool:
	get:
		return is_playing
	set(value):
		is_playing = value
		brush_clip2d.is_playing = value

@export var _editing_layer_num := 0

func draw():
	brush_clip2d.draw()

func play():
	brush_clip2d.play()

func stop():
	brush_clip2d.stop()

func next_frame():
	brush_clip2d.next_frame()

func previous_frame():
	brush_clip2d.previous_frame()

