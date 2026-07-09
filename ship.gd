extends CharacterBody2D
# The player ship controller.
# Handles rotation, movement, and mobile touch controls.


@export var speed := 150.0
# Movement speed of the ship.

@export var rotation_speed := 1.5
# How fast the ship rotates when the player touches the screen.


var turn_left := false
# Stores if the player is currently holding the left side of the screen.

var turn_right := false
# Stores if the player is currently holding the right side of the screen.



func _input(event):
	# Checks if the input event is a screen touch.
	if event is InputEventScreenTouch:

		# Gets half of the screen width.
		# Used to determine if the player touched the left or right side.
		var screen_half = get_viewport().get_visible_rect().size.x / 2


		# When the player touches the screen.
		if event.pressed:

			# Touching the left side rotates the ship left.
			turn_left = event.position.x < screen_half


			# Touching the right side rotates the ship right.
			turn_right = event.position.x >= screen_half


		# When the player releases the screen.
		else:

			# Stop rotating.
			turn_left = false
			turn_right = false



func _physics_process(delta):
	# Rotate the ship to the left.
	if turn_left:
		rotation -= rotation_speed * delta


	# Rotate the ship to the right.
	if turn_right:
		rotation += rotation_speed * delta


	# Limit the ship rotation between -30 and +30 degrees.
	# Prevents the ship from turning too far.
	rotation = clamp(rotation, -PI / 8, PI / 8)


	# Creates a movement direction based on the ship's rotation.
	# Vector2.UP means the ship's front is pointing upward.
	velocity = Vector2.UP.rotated(rotation) * speed


	# Applies the velocity and moves the CharacterBody2D.
	move_and_slide()
