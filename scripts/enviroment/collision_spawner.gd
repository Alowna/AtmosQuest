extends Node2D


@export var player: Node2D


@export var troposphere_obstacle_scenes: Array[PackedScene]
@export var stratosphere_obstacle_scenes: Array[PackedScene]
@export var mesosphere_obstacle_scenes: Array[PackedScene]
@export var termosphere_obstacle_scenes: Array[PackedScene]
@export var exosphere_obstacle_scenes: Array[PackedScene]

# Special one-time object.
@export var space_station_scene: PackedScene



# Default distance used for regular obstacle spawning.
@export var spawn_distance_y := 250.0


# Random vertical variation for regular obstacles.
@export var spawn_random_height := 150.0


# Distance used when spawning the space station.
# The station appears above the player.
@export var space_station_spawn_distance_y := 400.0



# Prevents multiple space stations from appearing.
var space_station_spawned: bool = false


@onready var spawn_timer = $SpawnTimer



# ==================================================
# ATMOSPHERE PIXEL LIMITS
# These values match the PlayerShip altitude system.
# ==================================================

const TROPOSPHERE_LIMIT := 515.0
const STRATOSPHERE_LIMIT := 2140.0
const MESOSPHERE_LIMIT := 3217.0
const THERMOSPHERE_LIMIT := 6996.0



# ==================================================
# START / STOP
# ==================================================

func start() -> void:

	print("Environment Manager ready")

	update_spawn_rate()

	spawn_timer.timeout.connect(spawn_obstacle)
	spawn_timer.start()



func stop() -> void:

	spawn_timer.stop()



# ==================================================
# SPAWN RATE CONTROL
# Updates obstacle spawn frequency based on player
# altitude.
# ==================================================

func update_spawn_rate() -> void:

	if PlayerConfig.altitude < 12:

		spawn_timer.wait_time = 1.8


	elif PlayerConfig.altitude < 50:

		spawn_timer.wait_time = 2.5


	elif PlayerConfig.altitude < 80:

		spawn_timer.wait_time = 3


	elif PlayerConfig.altitude < 700:

		spawn_timer.wait_time = 1.5


	else:

		spawn_timer.wait_time = 12.0



# ==================================================
# OBSTACLE SPAWN
# Creates obstacles based on their real world
# position instead of player altitude.
# ==================================================

func spawn_obstacle():

	update_spawn_rate()



	# Spawn the space station only once.
	if PlayerConfig.altitude >= 700 and not space_station_spawned:

		spawn_space_station()

		return



	# Calculate regular obstacle position.
	var spawn_y = player.global_position.y - spawn_distance_y



	# Apply random variation before selecting the layer.
	# This keeps obstacles inside the correct atmosphere.
	spawn_y += randf_range(
		-spawn_random_height,
		spawn_random_height
	)



	# Select obstacle pool based on actual world position.
	var obstacle_pool = get_obstacle_pool_from_position(spawn_y)
	
	#only allows spawns in limit of  layer
	if PlayerConfig.atmosLayer == 0 and -(spawn_y+100) > TROPOSPHERE_LIMIT:
		return
	if PlayerConfig.atmosLayer == 1 and -(spawn_y+100) > STRATOSPHERE_LIMIT:
		return
	if PlayerConfig.atmosLayer == 2 and -(spawn_y+100) > MESOSPHERE_LIMIT:
		return
	if PlayerConfig.atmosLayer == 3 and -(spawn_y+100) > THERMOSPHERE_LIMIT:
		return

	var obstacle_scene: PackedScene = obstacle_pool.pick_random()



	var obstacle = obstacle_scene.instantiate()


	add_child(obstacle)



	# Spawn on either side of the player.
	var side = randi() % 2


	if side == 0:

		obstacle.global_position = Vector2(
			player.global_position.x - 150,
			spawn_y
		)

		obstacle.setup(Vector2.RIGHT, player)



	else:

		obstacle.global_position = Vector2(
			player.global_position.x + 150,
			spawn_y
		)

		obstacle.setup(Vector2.LEFT, player)



	print(
		"Spawned ",
		obstacle.name,
		" | Spawn world Y: ",
		-spawn_y,
		" | Player altitude: ",
		PlayerConfig.altitude
	)



# ==================================================
# SPACE STATION SPAWN
# Creates the space station only once.
# ==================================================

func spawn_space_station():

	if space_station_scene == null:

		push_warning("Space Station scene not assigned.")

		return



	space_station_spawned = true



	var station = space_station_scene.instantiate()


	add_child(station)



	# Spawn directly above the player.
	station.global_position = Vector2(
		player.global_position.x,
		player.global_position.y - space_station_spawn_distance_y
	)


	station.setup(Vector2.LEFT, player)



	print(
		"Spawned Space Station | World Y: ",
		station.global_position.y
	)



# ==================================================
# OBSTACLE LAYER SELECTION
# Selects obstacle pool based on actual world pixels.
# ==================================================

func get_obstacle_pool_from_position(world_y: float) -> Array[PackedScene]:

	var height = -world_y


	if height <= TROPOSPHERE_LIMIT:

		return troposphere_obstacle_scenes


	elif height <= STRATOSPHERE_LIMIT:

		return stratosphere_obstacle_scenes


	elif height <= MESOSPHERE_LIMIT:

		return mesosphere_obstacle_scenes


	elif height <= THERMOSPHERE_LIMIT:

		return termosphere_obstacle_scenes


	else:

		return exosphere_obstacle_scenes





# ==================================================
# CLEANUP
# Removes all active obstacles.
# ==================================================

func clear_obstacles() -> void:

	for obstacle in get_children():

		if obstacle != spawn_timer:

			obstacle.queue_free()
