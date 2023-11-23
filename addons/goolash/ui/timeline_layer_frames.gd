@tool
extends Control

const TimelineKeyframe = preload("res://addons/goolash/ui/timeline_keyframe.tscn")

var layer: BrushLayer2D

func _clear():
	for child in get_children():
		child.queue_free()

func init(layer: BrushLayer2D):
	self.layer = layer
	draw()
	layer.edited.connect(draw)

func draw():
	_clear()
	for keyframe in layer.keyframes:
		var timeline_frame = TimelineKeyframe.instantiate()
		add_child(timeline_frame)
		timeline_frame.position.x = keyframe.frame_num * Timeline.FRAME_WIDTH
		timeline_frame.init(keyframe)
