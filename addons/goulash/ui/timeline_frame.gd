@tool
extends Control

func draw(keyframe, i: int):
	if keyframe:
		var blank = keyframe.shapes.size() == 0
		$Back.modulate.a = 0.15 if blank else 0.3
		$Keyframe.visible = true
		$Keyframe.text = "O" if blank else "⚪"
	else:
		$Keyframe.visible = false
		$Back.modulate.a = 0.05 if i % 5 == 0 else 0.1
