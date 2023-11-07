@tool
class_name Keyframe extends Resource

@export var shapes: Array
@export var triggers: Array
@export var frame_num: int

@export var layer: BrushClipLayer

func add_shape(shape: BrushShape2D):
	shapes.push_back(shape)
	shape.container = self


func copy() -> Keyframe:
	var frame = Keyframe.new()
	## todo: check if deep is necessary
	frame.shapes = shapes.duplicate()
	return frame


## todo: figure out triggers
class TriggerAudioStreamPlayer:
	var brush: BrushClip2D
	
	@export var player: NodePath
	
	func trigger():
		brush.get_node(player).play()
