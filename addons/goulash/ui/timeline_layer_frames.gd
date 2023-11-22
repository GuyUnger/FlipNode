@tool
extends HBoxContainer

const TimelineFrame = preload("res://addons/goulash/ui/timeline_frame.tscn")

var layer: BrushLayer2D

func _clear():
	for child in get_children():
		child.queue_free()

func draw(layer: BrushLayer2D):
	self.layer = layer
	redraw()
	#layer.changed.connect(redraw)

func redraw():
	_clear()
	for i in layer.frame_count:
		var keyframe = layer.get_keyframe(i)
		var timeline_frame = TimelineFrame.instantiate()
		timeline_frame.draw(keyframe, i)
		add_child(timeline_frame)
	
