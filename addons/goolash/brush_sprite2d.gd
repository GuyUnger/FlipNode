@tool
@icon("res://addons/goolash/icons/BrushSprite2D.svg")
class_name BrushSprite2D
extends Node2D

const BrushStroke2D = preload("res://addons/goolash/brush_stroke2d.tscn")

signal edited

@export var stroke_data: Array
var strokes: Array

func _ready():
	draw()
	show_behind_parent = true


func add_stroke(stroke: BrushStrokeData):
	stroke_data.push_back(stroke)


func draw():
	var stroke_count = stroke_data.size()
	
	while strokes.size() > stroke_count:
		remove_child(strokes[strokes.size() - 1])
		strokes.pop_back()
	
	while strokes.size() < stroke_count:
		var stroke = BrushStroke2D.instantiate()
		add_child(stroke)
		strokes.push_back(stroke)
	
	for i in stroke_data.size():
		strokes[i].draw(stroke_data[i])
