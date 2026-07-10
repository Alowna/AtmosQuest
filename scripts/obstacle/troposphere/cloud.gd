extends Obstacle
class_name Cloud


@export var cloud_textures: Array[Texture2D]

@onready var sprite = $Sprite2D


func _ready():
	z_index = 2
	# Applies cloud speed
	speed = 80.0
	# Selects a random cloud texture.
	var random_cloud = cloud_textures.pick_random()
	#print(random_cloud)

	# Applies the selected texture.
	sprite.texture = random_cloud
	

	
