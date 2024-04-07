@tool
extends Control

const TimelineFrame = preload("res://addons/flipnode/ui/timeline_frame.tscn")
const TimelineTweenframe = preload("res://addons/flipnode/ui/timeline_transform_key.tscn")

var layer: Layer2D


func _clear():
	for child in get_children():
		child.queue_free()


func init(layer: Layer2D):
	self.layer = layer
	draw()
	layer.edited.connect(draw)


func draw():
	_clear()
	
	for brush in layer.brushes:
		var timeline_brush = TimelineFrame.instantiate()
		add_child(timeline_brush)
		timeline_brush.position.x = brush.frame_num * Timeline.FRAME_WIDTH
		timeline_brush.init(brush)
	
	for transform_key in layer.transform_keys:
		var timeline_transform_key = TimelineTweenframe.instantiate()
		add_child(timeline_transform_key)
		timeline_transform_key.position.x = transform_key[1] * Timeline.FRAME_WIDTH
	
	custom_minimum_size.x = (layer.length + 1) * Timeline.FRAME_WIDTH
