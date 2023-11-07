@tool
extends HBoxContainer

const TimelineFrame = preload("res://addons/goulash/ui/timeline_frame.tscn")

var layer: BrushClipLayer

func _clear():
	for child in get_children():
		child.queue_free()

func draw(layer: BrushClipLayer):
	redraw()
	layer.changed.connect(redraw)

func redraw():
	_clear()
	for i in layer.frame_count:
		var keyframe = layer.get_keyframe(i)
		var timeline_frame = TimelineFrame.instantiate()
		timeline_frame.draw(keyframe, i)
		add_child(timeline_frame)
	
