extends Obstacle


#Plane physics
func _physics_process(delta):
	var direction = Vector2.RIGHT
	# Movement direction of the plane.
	var speed := 70.0
	# Movement speed of the plane.
	
	move_obstacle(direction, speed)
