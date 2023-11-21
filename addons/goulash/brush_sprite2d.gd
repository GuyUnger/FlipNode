@tool
class_name BrushSprite2D extends Node2D

const BrushStroke2D = preload("res://addons/goulash/brush_stroke2d.tscn")

var data: BrushSpriteData
var strokes := []

func draw():
	var strokes_data := []
	
	var stroke_count = data.strokes.size()
	
	while strokes.size() > stroke_count:
		remove_child(strokes[strokes.size() - 1])
		strokes.pop_back()
	
	while data.strokes.size() < stroke_count:
		var stroke = BrushStroke2D.instantiate()
		add_child(stroke)
		strokes.push_back(stroke)
	
	for i in strokes_data.size():
		strokes[i].draw(strokes_data[i])

