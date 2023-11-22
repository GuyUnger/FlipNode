@tool
extends Control

var keyframe: BrushKeyframe2D

func draw(keyframe: BrushKeyframe2D, i: int):
	self.keyframe = keyframe
	var blank = keyframe.stroke_data.size() == 0
	%Keyframe.text = "O" if blank else "⚪"
	%Label.text = keyframe.label


func _on_pressed():
	keyframe.get_clip().goto(keyframe.frame_num)
