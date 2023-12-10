extends RigidBody2D

@export var wheel_l: RigidBody2D
@export var wheel_r: RigidBody2D

var air_t := 0.0

var closest_floor_distance: float
var closest_floor_direction: Vector2
var closest_floor_normal: Vector2
var closest_floor_position: Vector2

var facing := 1
var facing_turn_t := 0.0
var aim_direction := Vector2()

var boosts := 0
var boost_t := 0.0
var airspin := 0.0

func _integrate_forces(state):
	## Get ground information
	var samples := 32.0
	closest_floor_distance = 500.0
	for i in samples:
		var angle = i / samples * TAU
		%RayFloor.global_rotation = angle
		%RayFloor.force_raycast_update()
		if %RayFloor.is_colliding():
			var floor_position = %RayFloor.get_collision_point()
			var distance = global_position.distance_to(floor_position)
			
			if distance < closest_floor_distance:
				closest_floor_distance = distance
				closest_floor_normal = %RayFloor.get_collision_normal()
				closest_floor_position = floor_position
				closest_floor_direction = Vector2.from_angle(angle - PI * 0.5)
	
	$Arrow.global_rotation = closest_floor_direction.angle()
	
	var wheels_on_gound: int = wheel_l.get_contact_count() + wheel_r.get_contact_count()
	
	## Get control information
	var flipped := Vector2.from_angle(global_rotation - PI * 0.5).dot(closest_floor_direction) < 0.0
	var flipped_direction := -1.0 if flipped else 1.0
	
	var gas := Input.get_axis("ui_left", "ui_right")
	
	var ground_control_distance = 80.0
	var ground_control = (ground_control_distance - closest_floor_distance) / ground_control_distance + 0.3
	ground_control = clamp(ground_control, 0.0, 1.0)
	
	## Facing direction
	if wheels_on_gound >= 1 and gas != 0.0:
		var facing_to = 1 if gas * flipped_direction > 0.0 else -1
		if facing != facing_to:
			facing_turn_t += get_process_delta_time()
			if facing_turn_t > 0.1:
				facing = facing_to
		else: 
			facing_turn_t = 0.0
	else: 
		facing_turn_t = move_toward(facing_turn_t, 0.0, get_process_delta_time())
	aim_direction = transform.x * facing
	
	$Arrow2.global_rotation = aim_direction.angle()
	
	## Wheel moving
	if wheels_on_gound >= 1:
		var initial_boost_strength = max(300.0 - linear_velocity.length(), 0.0) / 300.0
		
		var wheel_torque: float = gas * lerp(1000.0, 10000.0, initial_boost_strength) * flipped_direction
		wheel_l.apply_torque(wheel_torque)
		wheel_r.apply_torque(wheel_torque)
		
		apply_central_force(transform.x * gas * flipped_direction * 10000.0 * initial_boost_strength)
		apply_torque(-gas * 100000.0 * initial_boost_strength)
	else:
		var wheel_torque: float = gas * 1000.0 * flipped_direction
		wheel_l.apply_torque(wheel_torque)
		wheel_r.apply_torque(wheel_torque)
	
	## Boost
	if wheels_on_gound >= 1:
		boosts = 1
		airspin = 0.0
	elif boosts == 0:
		airspin += angular_velocity * get_physics_process_delta_time()
		if abs(airspin) > TAU * 0.9:
			airspin = 0.0
			boosts = 1
	
	if boosts > 0 and Input.is_action_just_pressed("ui_accept"):
		boost_t = 1.0
		boosts -= 1
		
		linear_velocity = lerp(
				linear_velocity,
				aim_direction * max(linear_velocity.length(), 500.0),
				0.5
			)
		wheel_l.linear_velocity = linear_velocity
		wheel_r.linear_velocity = linear_velocity
		if wheels_on_gound >= 1:
			apply_central_impulse(closest_floor_normal * 500.0)
	
	## Damp
	angular_damp = lerp(600.0, 300.0, ground_control)
	
	## Ground control
	apply_central_force(transform.x * gas * flipped_direction * 3000.0 * ground_control)
	
	## Air control
	#apply_central_force(Vector2.RIGHT * gas * 1000.0 * (1.0 - ground_control))
	apply_torque(gas * 70000.0 * (1.0 - ground_control))
	
	## Orient towards ground
	var near_turn_distance = 200.0
	if closest_floor_distance < near_turn_distance:
		var parallel = abs(closest_floor_normal.dot(transform.y))
		var strength = (near_turn_distance - closest_floor_distance) / near_turn_distance * parallel
		var angle_to = closest_floor_normal.angle() + PI * 0.5
		if flipped:
			angle_to += PI
		
		apply_torque( angle_difference(rotation, angle_to) * 30000.0 * strength)
	
	var zoom_to = 0.8 + (linear_velocity.length() / 2000.0)
	zoom = lerp(zoom, zoom_to, get_physics_process_delta_time())
	$Camera2D.zoom = Vector2.ONE / zoom

var zoom: float = 1.0

func _physics_process(delta):
	if boost_t > 0.0:
		boost_t -= delta / 0.2
		apply_central_force(aim_direction * 10000.0)
		
		linear_velocity = lerp(
				linear_velocity,
				aim_direction * max(linear_velocity.length(), 500.0),
				delta * 20.0
			)
		var force_move_amount = aim_direction * 2000.0 * delta * boost_t
		move_and_collide(force_move_amount)
		wheel_l.move_and_collide(force_move_amount)
		wheel_r.move_and_collide(force_move_amount)
	
	var color = Color.CYAN if boosts == 0 else Color.MAGENTA
	
	wheel_l.modulate = color
	wheel_r.modulate = color
	
	if closest_floor_distance < 100.0:
		
		if last_smoke_spawn_pos.distance_to(closest_floor_position) > 70.0:
			last_smoke_spawn_pos = closest_floor_position
			var smoke = Smoke.instantiate()
			smoke.scale = Vector2.ONE * (linear_velocity.length() / 2000.0 + 0.15) * randf_range(0.8, 1.2)
			
			if linear_velocity.rotated(-PI * 0.5).dot(closest_floor_normal) < 0.0:
				smoke.scale.x *= -1.0
			
			get_parent().add_child(smoke)
			smoke.position = closest_floor_position
			smoke.rotation = closest_floor_normal.angle() + PI * 0.5

const Smoke = preload("res://demo/platformer/smoke.tscn")
var last_smoke_spawn_pos := Vector2()
