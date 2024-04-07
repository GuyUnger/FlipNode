@tool
class_name EdgeSelection extends Node


var stroke: Stroke
var vertex_indices := []
var vertex_weights := []
var closest_point

var hole_id := -1


func _init(stroke: Stroke):
	self.stroke = stroke


func add_vertex(index: int, weight: float):
	var i = vertex_indices.find(index)
	if i != -1:
		# Already has this vertex, use the heighest weight.
		weight = max(vertex_weights[i], weight)
		return
	
	vertex_indices.push_back(index)
	vertex_weights.push_back(weight)


func add_vertex_unsafe(index: int, weight: float):
	vertex_indices.push_back(index)
	vertex_weights.push_back(weight)


func get_vertex_count() -> int:
	return vertex_indices.size()
