@tool
class_name BrushLayer2D
extends Node2D

var layer_data: BrushLayerData

func draw():
	for keyframe_data in layer_data.keyframes:
		var keyframe = Keyframe2D.new()
		add_child(keyframe)
		keyframe.owner = owner
		keyframe.name = "Frame %s" % keyframe_data.frame_num

#static func new() -> BrushLayer2D:
	#return BrushLayer2D.new()
