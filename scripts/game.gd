extends Node2D

@onready var hull_hud = $CanvasLayer/Hull
@onready var end_result_hud = $CanvasLayer/EndResultsHud
@onready var question = $CanvasLayer/Question
@onready var question_manager = $CanvasLayer/Question/QuestionScreen/QuestionManager
@onready var PlayerShip = $PlayerShip
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



func finish_game() -> void:
	# Hide gameplay HUD and show the end results screen
	#PlayerConfig.speed = 0
	# Stop collision spawner and clear obstacles
	#CollisionSpawner.clear_obstacles()
	CollisionSpawner.stop()
	get_tree().paused = true
	
	hull_hud.visible = false
	end_result_hud.visible = true

	
	# Start the end sequence transition
	end_result_hud.start_results_sequence()
