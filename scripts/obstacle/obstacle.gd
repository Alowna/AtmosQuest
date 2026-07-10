extends CharacterBody2D
class_name Obstacle


# Movement speed of the obstacle.

func move_obstacle(direction: Vector2, speed):
	# Creates the movement velocity based on the given direction.
	# Any ship can use this function by providing a movement direction.
	velocity = direction * speed
	# Applies the velocity and moves the CharacterBody2D.
	move_and_slide()

#Physics for testing
func _physics_process(delta):
	var direction = Vector2.RIGHT
	var speed = 50.0
	move_obstacle(direction, speed)
