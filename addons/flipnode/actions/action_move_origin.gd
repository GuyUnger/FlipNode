@tool
class_name ActionMoveOrigin extends Action


func _init(brush: Brush2D):
	self.brush = brush


func start():
	pass


func _complete():
	var offset = brush.get_local_mouse_position()
	brush.position += offset.rotated(brush.rotation) * brush.scale
	
	for stroke: Stroke in brush.strokes:
		stroke.translate(- offset)
	
	for child in brush.get_children():
		if child is Node2D:
			child.position -= offset
	
	#TODO: Why does it need this? It doesn't update the visuals right away without it but why?
	await brush.get_tree().process_frame
	
	brush.draw()
	brush.update_bounds()
