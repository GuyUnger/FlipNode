@tool
class_name BrushClip3D extends Sprite3D

@onready var brush_animation2d = $SubViewport/BrushAnimation2D

var current_frame: int: 
	get:
		return brush_animation2d.current_frame
	set(value):
		brush_animation2d.current_frame = value

@export var is_playing: bool:
	get:
		return is_playing
	set(value):
		is_playing = value
		brush_animation2d.is_playing = value

@export var _editing_layer_num := 0

func draw():
	brush_animation2d.draw()

func play():
	brush_animation2d.play()

func stop():
	brush_animation2d.stop()

func next_frame():
	brush_animation2d.next_frame()

func previous_frame():
	brush_animation2d.previous_frame()

