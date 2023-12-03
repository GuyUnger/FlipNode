@tool
extends Node

static var default_fps := 12
var frame := 0.0

@onready var material = preload("res://addons/goolash/shading/brush_stroke_material.tres")

func _process(delta):
	frame += delta * default_fps
	material.set_shader_parameter("goolash_frame", fmod(floor(frame), 1000.0) )
