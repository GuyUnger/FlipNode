@tool
class_name Brush3D extends Sprite3D

@onready var brush2d = $SubViewport/Brush2D

func draw():
	brush2d.draw()
