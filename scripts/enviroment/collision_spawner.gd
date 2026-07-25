extends Node2D

@export var player: Node2D

@export var troposphere_obstacle_scenes: Array[PackedScene]
@export var stratosphere_obstacle_scenes: Array[PackedScene]
@export var mesosphere_obstacle_scenes: Array[PackedScene]
@export var termosphere_obstacle_scenes: Array[PackedScene]
@export var exosphere_obstacle_scenes: Array[PackedScene]

# Default distance used for regular obstacle spawning
@export var spawn_distance_y := 250.0

# Random vertical variation for regular obstacles
@export var spawn_random_height := 150.0

# Extra distance used when spawning the space station
# This gives enough time for the player to approach it naturally
@export var space_station_spawn_distance_y := 2000.0

@onready var spawn_timer = $SpawnTimer


func start() -> void:
	print("Environment Manager ready")
	
	spawn_timer.timeout.connect(spawn_obstacle)
	spawn_timer.start()

func stop() -> void:
	spawn_timer.stop()



func spawn_obstacle():
	var obstacle_scene: PackedScene
	
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

	# Add the obstacle to the scene tree before setting its global position
	add_child(obstacle)



	# Default spawn distance for normal obstacles
	var current_spawn_distance = spawn_distance_y


	# Check if the selected obstacle is the space station
	# The space station spawns much higher to avoid appearing suddenly on screen
	if obstacle_scene.resource_path.contains("SpaceStation"):
		current_spawn_distance = space_station_spawn_distance_y



	# Calculate the spawn height relative to the player's position
	var spawn_y = player.global_position.y - current_spawn_distance



	# Apply random height variation only to normal obstacles
	# The space station should have a predictable spawn position
	if current_spawn_distance == spawn_distance_y:
		spawn_y += randf_range(-spawn_random_height, spawn_random_height)



	var side = randi() % 2



	# Set the obstacle position and movement direction
	if side == 0:
		# Spawn on the left side and move towards the right
		obstacle.global_position = Vector2(
			player.global_position.x - 150,
			spawn_y
		)
		
		obstacle.setup(Vector2.RIGHT, player)

	else:
		# Spawn on the right side and move towards the left
		obstacle.global_position = Vector2(
			player.global_position.x + 150,
			spawn_y
		)
		
		obstacle.setup(Vector2.LEFT, player)
		
	print("Spawned " + obstacle.name)

func clear_obstacles() -> void:
	for obstacle in get_children():
		if obstacle != spawn_timer:
			obstacle.queue_free()
