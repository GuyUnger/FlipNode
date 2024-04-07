@tool
extends Control

var brush: Brush2D

@export var style_filled: StyleBoxFlat
@export var style_empty: StyleBoxFlat

var preview: Brush2D


func init(brush: Brush2D):
	self.brush = brush
	brush.edited.connect(_on_keybrush_edited)
	Flip.editor.editing_brush_changed.connect(_on_editing_brush_changed)
	%Selected.modulate = Flip.editor.accent_color
	await get_tree().process_frame
	draw()


func _on_editing_brush_changed(brush):
	%Selected.visible = brush == self.brush


func _on_keybrush_edited():
	call_deferred("draw")


func draw():
	var is_empty = brush.is_empty()
	self_modulate = Color.DIM_GRAY if is_empty else Color.WHITE
	add_theme_stylebox_override("normal", style_empty if is_empty else style_filled)
	size.x = (brush.get_end_frame() - brush.frame_num + 1) * Timeline.FRAME_WIDTH
	
	if not preview:
		preview = Brush2D.new()
		add_child(preview)
	preview.strokes = brush.strokes
	preview.update_bounds()
	
	preview.lods = [preview.generate_lod(5.0)]
	preview.draw(0)
	
	var preview_scale = 20.0 / max(preview.bounds.size.x, preview.bounds.size.y)
	preview.scale = Vector2.ONE * preview_scale
	preview.position = -preview.bounds.position * preview_scale + Vector2.ONE * 2


func _on_pressed():
	EditorInterface.inspect_object(null)
	Flip.editor.select_layer(brush.layer)
	Flip.editor.select_brush(brush)
	#TODO: hmmm
	#EditorInterface.inspect_object(brush)
