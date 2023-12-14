extends CharacterBody2D

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		queue_free()
		
		var ground = get_parent().get_node("Brush2D")
		var polygon = Goolash.create_polygon_circle(position, 20.0)
		ground.subtract_polygon(polygon)
		#ground.generate_static_body()
