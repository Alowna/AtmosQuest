extends Node2D

@export var player: Node2D
@export var obstacle_scenes: Array[PackedScene]

@export var spawn_distance_y := 250.0
@export var spawn_random_height := 150.0

@onready var spawn_timer = $SpawnTimer

func _ready():
	print("Environment Manager ready")
	spawn_timer.timeout.connect(spawn_obstacle)
	spawn_timer.start()

func spawn_obstacle():
	var obstacle_scene = obstacle_scenes.pick_random()
	var obstacle = obstacle_scene.instantiate()

	# 1. PRIMEIRO nós adicionamos à cena
	add_child(obstacle)

	var spawn_y = player.global_position.y - spawn_distance_y
	spawn_y += randf_range(-spawn_random_height, spawn_random_height)

	var side = randi() % 2

	# 2. DEPOIS alteramos a global_position
	if side == 0:
		# Spawn da esquerda
		obstacle.global_position = Vector2(
			player.global_position.x - 150,
			spawn_y
		)
		obstacle.setup(Vector2.RIGHT, player)
	else:
		# Spawn da direita
		obstacle.global_position = Vector2(
			player.global_position.x + 150,
			spawn_y
		)
		obstacle.setup(Vector2.LEFT, player)
	

	print("Player:", player.global_position)
	print("Obstacle:", obstacle.global_position)
	print("Spawned " + obstacle.name)
