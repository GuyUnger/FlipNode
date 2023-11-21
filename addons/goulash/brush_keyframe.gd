@tool
class_name Keyframe
extends Resource

@export var sprite_data: BrushSpriteData
@export var triggers: Array
@export var frame_num: int

@export var layer: BrushLayerData


func copy() -> Keyframe:
	var frame = Keyframe.new()
	## todo: check if deep is necessary
	frame.sprite_data = sprite_data.duplicate()
	return frame


## todo: figure out triggers
class TriggerAudioStreamPlayer:
	var brush: BrushClip2D
	
	@export var player: NodePath
	
	func trigger():
		brush.get_node(player).play()
