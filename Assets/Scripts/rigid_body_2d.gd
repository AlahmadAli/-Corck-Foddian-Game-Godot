extends RigidBody2D

@export var push_force: float = 200.0
@export var max_force: float = 600
@export var max_speed: float = 400
@export var raycast_distance: float = 150.0
var fall_gravity: float = 2000
var debug_ray_start: Vector2
var debug_ray_end: Vector2
var show_debug_ray: bool = false
var tumbling = false
var is_grounded = null

#############

#############

#############

#############

#############

#############

#############

#############

#############

#############
#############

#############

#############

#############

#############

#############

#############

#############

############# make minimum speed lower, it feels too fast. Possibly change max speed if needed 





func _physics_process(delta):
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func _process(delta: float) -> void:
	$"../Camera2D".global_position = global_position
	var mouse_pos = get_global_mouse_position()
	var distance = global_position.distance_to(mouse_pos)

	# Normalize against viewport so resolution doesn't affect force
	var max_possible_distance = get_viewport_rect().size.length()
	var normalized_distance = clamp(distance / max_possible_distance, 0.0, 1.0)

	push_force = 90 * sqrt(normalized_distance * max_force)

func _draw():
	if show_debug_ray:
		draw_line(debug_ray_start - global_position, debug_ray_end - global_position, Color.RED, 2.0)
		draw_circle(debug_ray_end - global_position, 5.0, Color.YELLOW)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			create_raycast()

func push_away_from_mouse():
	var mouse_pos = get_global_mouse_position()
	var character_pos = global_position
	var push_direction = (character_pos - mouse_pos).normalized()

	linear_velocity = linear_velocity * 0.2

	var tween = create_tween()
	var tween_duration = 0.065
	var target_force = push_force * 6
	var physics_delta = 1.0 / Engine.physics_ticks_per_second

	tween.tween_method(
		func(t: float):
			apply_central_force(push_direction * t * physics_delta * Engine.physics_ticks_per_second),
		0.0,
		target_force,
		tween_duration
	)

func create_raycast():
	var mouse_pos = get_global_mouse_position()
	var character_pos = global_position
	var direction = (-(character_pos - mouse_pos)).normalized()

	debug_ray_start = character_pos
	debug_ray_end = character_pos + direction * raycast_distance

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(character_pos, character_pos + direction * raycast_distance)
	query.exclude = [self]

	var result = space_state.intersect_ray(query)

	if result:
		push_away_from_mouse()
		print("Hit: ", result.collider.name)
		print("Hit position: ", result.position)
		print("Hit normal: ", result.normal)
		debug_ray_end = result.position
	else:
		print("No hit")

	show_debug_ray = true
	queue_redraw()

	get_tree().create_timer(0.5).timeout.connect(func():
		show_debug_ray = false
		queue_redraw()
	)

	return result

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("danger") and is_grounded == false:
		gravity_scale = fall_gravity

func _on_floor_check_body_entered(body: Node2D) -> void:
	if body.is_in_group("floor") or body is StaticBody2D:
		is_grounded = true
		print("Touching ground")

func _on_floor_check_body_exited(body: Node2D) -> void:
	if body.is_in_group("floor") or body is StaticBody2D:
		is_grounded = false
		print("Left ground")
