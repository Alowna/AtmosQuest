extends Node2D

@onready var hull_hud = $CanvasLayer/Hull
@onready var end_result_hud = $CanvasLayer/EndResultsHud
@onready var question = $CanvasLayer/Question
@onready var question_manager = $CanvasLayer/Question/QuestionScreen/QuestionManager
@onready var PlayerShip = $PlayerShip
@onready var PlayerCamera = $PlayerShip/Camera2D
@onready var CollisionSpawner = $CollisionSpawner
var game_ended = false


func _ready() -> void:
	AudioManager.play_music("gameSong")
	
	#Start collision spawner
	CollisionSpawner.start()
	
	# Set initial visibility states for gameplay
	hull_hud.visible = true
	end_result_hud.visible = false

	# Listen for atmosphere layer changes
	PlayerConfig.atmos_layer_changed.connect(_on_atmos_layer_changed)



func _process(delta):

	if PlayerConfig.finished and not game_ended:
		game_ended = true
		finish_game()



func _on_atmos_layer_changed(layer: int):
	PlayerConfig.collisionDeathObject = "Transição de Camadas"
	# Pause the game while the question is active
	get_tree().paused = true
	
	if is_instance_valid(question_manager):
		
		# Connect signal to wait for the answer
		if not question_manager.question_finished.is_connected(_on_question_finished):
			question_manager.question_finished.connect(_on_question_finished)

		# Start the question
		question.start()



func _on_question_finished(is_correct: bool):

	if question_manager.question_finished.is_connected(_on_question_finished):
		question_manager.question_finished.disconnect(_on_question_finished)

@onready var LeftOrbit = $CanvasLayer/LeftOrbit

func finish_game() -> void:
	# Hide gameplay HUD and show the end results screen
	#PlayerConfig.speed = 0
	# Stop collision spawner and clear obstacles
	#CollisionSpawner.clear_obstacles()
	await AudioManager.stop_all_game_sounds()
	CollisionSpawner.clear_obstacles()
	CollisionSpawner.stop()
	
	get_tree().paused = true
	

	hull_hud.visible = false
	
	
	if PlayerConfig.isAlive:
		AudioManager.play_music("happyEnding")
		await zoom_into_player_ship()
		await LeftOrbit.start()
	else:
		AudioManager.play_music("sadEnding")

	end_result_hud.visible = true
	
	# Keep the final camera position after the transition
	var camera_position = PlayerCamera.global_position

	PlayerCamera.top_level = true
	PlayerCamera.global_position = camera_position
	PlayerCamera.enabled = true
	
	# Start the end sequence transition
	end_result_hud.start_results_sequence()
	
	
func zoom_into_player_ship() -> void:
	# Enable camera and focus on the ship
	PlayerCamera.enabled = true
	PlayerCamera.zoom = Vector2.ONE
	
	var camera_tween = create_tween()
	camera_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	camera_tween.tween_property(
		PlayerCamera,
		"zoom",
		Vector2(8, 8),
		0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await camera_tween.finished
	
	
	# Detach camera from the ship and keep its current position
	PlayerCamera.top_level = true
	PlayerCamera.global_position = PlayerShip.global_position
	PlayerCamera.position_smoothing_enabled = false
	
	
	# Rotate ship 30 degrees to the right and fly away
	var ship_tween = create_tween()
	ship_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	ship_tween.parallel().tween_property(
		PlayerShip,
		"rotation",
		deg_to_rad(30),
		0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	ship_tween.parallel().tween_property(
		PlayerShip,
		"position",
		PlayerShip.position + Vector2(1000, -300),
		2.0
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	AudioManager.play_game_sound("swoosh")
	await ship_tween.finished
