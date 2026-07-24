extends Node2D

@export var player: Node2D

@export var troposphere_obstacle_scenes: Array[PackedScene]
@export var stratosphere_obstacle_scenes: Array[PackedScene]
@export var mesosphere_obstacle_scenes: Array[PackedScene]
@export var termosphere_obstacle_scenes: Array[PackedScene]
@export var exosphere_obstacle_scenes: Array[PackedScene]

@export var spawn_distance_y := 250.0
@export var spawn_random_height := 150.0

@onready var spawn_timer = $SpawnTimer

func _ready():
	print("Environment Manager ready")
	spawn_timer.timeout.connect(spawn_obstacle)
	spawn_timer.start()

func spawn_obstacle():
	var obstacle_scene
	
	# Select the appropriate obstacle pool based on the player's altitude
	if PlayerConfig.altitude < 12:
		obstacle_scene = troposphere_obstacle_scenes.pick_random()
	elif PlayerConfig.altitude < 50:
		obstacle_scene = stratosphere_obstacle_scenes.pick_random()
	elif PlayerConfig.altitude < 80:
		obstacle_scene = mesosphere_obstacle_scenes.pick_random()
	elif PlayerConfig.altitude < 700:
		obstacle_scene = termosphere_obstacle_scenes.pick_random()
	else:
		obstacle_scene = exosphere_obstacle_scenes.pick_random()

	var obstacle = obstacle_scene.instantiate()

	# 1. First, add the obstacle to the scene tree
	add_child(obstacle)

	var spawn_y = player.global_position.y - spawn_distance_y
	spawn_y += randf_range(-spawn_random_height, spawn_random_height)

	var side = randi() % 2

	# 2. Then, set its initial global position and initialize base direction
	if side == 0:
		# Left side spawn (moves toward the right)
		obstacle.global_position = Vector2(
			player.global_position.x - 150,
			spawn_y
		)
		obstacle.setup(Vector2.RIGHT, player)
	else:
		# Right side spawn (moves toward the left)
		obstacle.global_position = Vector2(
			player.global_position.x + 150,
			spawn_y
		)
		obstacle.setup(Vector2.LEFT, player)
	
	print("Spawned " + obstacle.name)
