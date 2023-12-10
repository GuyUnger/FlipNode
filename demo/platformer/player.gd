extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -750.0

var t_since_on_floor := 0.0

var allow_jump_break := false

@export var car: RigidBody2D

func _physics_process(delta):
	if is_on_floor():
		t_since_on_floor = 0.0
	else:
		t_since_on_floor += delta
		var hover = 1.0
		if allow_jump_break:
			hover = min(abs(velocity.y) / 100.0 + 0.1, 1.0)
		velocity.y += 2000.0 * delta * hover
	
	if Input.is_action_just_pressed("ui_accept") and t_since_on_floor < 0.2:
		velocity.y = JUMP_VELOCITY
		allow_jump_break = true
	
	if Input.is_action_just_released("ui_accept") and allow_jump_break and velocity.y < 0.0:
		velocity.y *= 0.5
		allow_jump_break = false
	
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	apply_floor_snap()
	move_and_slide()
	
	var ground = get_parent().get_node("Brush2D")
	if Input.is_action_just_pressed("ui_down"):
		var polygon = Goolash.create_polygon_circle(position + Vector2.UP * 30.0, 120.0)
		ground.subtract_polygon(polygon)
		ground.generate_static_body()
