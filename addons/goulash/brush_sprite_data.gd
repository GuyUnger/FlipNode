@tool
class_name BrushSpriteData
extends Resource

var strokes: Array

func add_stroke(stroke: BrushStrokeData):
	strokes.push_back(stroke)
	stroke.container = self
