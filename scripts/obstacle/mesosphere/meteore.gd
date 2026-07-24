extends Obstacle

func _ready():
	obstacle_name = "Meteoro"
	z_index = 2
	speed = 150.0
	
	# Set a 5-degree downward trajectory angle
	drop_angle_degrees = 5
	
