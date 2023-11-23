@tool
extends Node

static var default_fps := 12
var frame := 0.0

func _process(delta):
	frame += delta * default_fps
	
	RenderingServer.global_shader_parameter_set("goulash_frame", floor(frame) )
