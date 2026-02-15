extends RigidBody2D

# Adjust this value to control the push strength
@export var push_force: float = 200.0
# Maximum speed the character can reach
@export var max_speed: float = 700
# Raycast distance
@export var raycast_distance: float = 150.0
var fall_gravity: float = 2000
# Debug variables
var debug_ray_start: Vector2
var debug_ray_end: Vector2
var show_debug_ray: bool = false
var tumbling = false
var is_grounded = null

func _physics_process(delta):
	# Cap the speed
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func _draw():
	if show_debug_ray:
		# Draw the raycast line in red
		draw_line(debug_ray_start - global_position, debug_ray_end - global_position, Color.RED, 2.0)
		# Draw a circle at the end point
		draw_circle(debug_ray_end - global_position, 5.0, Color.YELLOW)

func _input(event):
	# Check if left mouse button is clicked
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			create_raycast()
			
func push_away_from_mouse():
	# Get mouse position in world coordinates
	var mouse_pos = get_global_mouse_position()
	
	# Get character position
	var character_pos = global_position
	
	# Calculate direction from mouse to character (away from mouse)
	var push_direction = (character_pos - mouse_pos).normalized()
	
	# Apply impulse in that direction
	apply_central_impulse(push_direction * push_force)

func create_raycast():
	var mouse_pos = get_global_mouse_position()
	var character_pos = global_position
	var direction = (-(character_pos - mouse_pos)).normalized()
	
	# Store debug ray info
	debug_ray_start = character_pos
	debug_ray_end = character_pos + direction * raycast_distance
	
	# Create a raycast query
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(character_pos, character_pos + direction * raycast_distance)
	query.exclude = [self]  # Don't hit ourselves
	
	var result = space_state.intersect_ray(query)
	
	if result:
		push_away_from_mouse()
		print("Hit: ", result.collider.name)
		print("Hit position: ", result.position)
		print("Hit normal: ", result.normal)
		# Update ray end to hit position
		debug_ray_end = result.position
	else:
		print("No hit")
	
	# Enable debug drawing and trigger redraw
	show_debug_ray = true
	queue_redraw()
	
	# Optional: Hide the ray after a short delay
	get_tree().create_timer(0.5).timeout.connect(func(): 
		show_debug_ray = false
		queue_redraw()
	)
	
	return result


func _on_hurtbox_area_entered(area: Area2D) -> void: # Add danger group to objects and give them hitbox area
	if area.is_in_group("danger") and is_grounded == false:
		gravity_scale = fall_gravity
		#play tumbling animation

func _on_floor_check_body_entered(body: Node2D) -> void:
	if body.is_in_group("floor") or body is StaticBody2D:
		is_grounded = true
		print("Touching ground")


func _on_floor_check_body_exited(body: Node2D) -> void:
	if body.is_in_group("floor") or body is StaticBody2D:
		is_grounded = false
		print("Left ground")
