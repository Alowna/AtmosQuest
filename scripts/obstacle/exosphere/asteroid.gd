extends Obstacle
class_name Asteroid


@export var asteroid_textures: Array[Texture2D]

@onready var sprite = $Sprite2D


func _ready():
	obstacle_name = "Asteroide"
	z_index = 2
	# Applies asteroid speed
	speed = 160.0
	# Selects a random asteroid texture.
	var random_asteroid = asteroid_textures.pick_random()
	#print(random_asteroid)

	# Applies the selected texture.
	sprite.texture = random_asteroid
	

	
