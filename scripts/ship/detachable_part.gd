extends Node2D
class_name DetachablePart

# How strongly the part is pushed away when detached.
@export var separation_force := 2.0

# Rotation speed after separation.
@export var spin_speed := 0.0

# Downward falling speed.
@export var fall_speed := 10.0


var detached := false
var velocity := Vector2.ZERO


func detach():

	# Prevents the same part from being detached twice.
	if detached:
		return

	detached = true


	# Save the current world position and rotation.
	var current_transform = global_transform


	# Remove this part from the ship hierarchy.
	# After this, it no longer follows the rocket.
	reparent(get_tree().current_scene)


	# Restore its exact position after leaving the ship.
	global_transform = current_transform


	# Give the part a separation impulse.
	velocity = Vector2(
		randf_range(-separation_force, separation_force),
		fall_speed
	)



func _process(delta):

	# Only move after separation.
	if detached:

		# Falling movement.
		position += velocity * delta

		# Spinning effect while falling.
		rotation += spin_speed * delta
