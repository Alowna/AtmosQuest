extends Node2D

# Node references within CanvasLayer
@onready var hull_hud = $CanvasLayer/Hull
@onready var end_result_hud = $CanvasLayer/EndResultsHud

var game_ended = false

func _ready() -> void:
	AudioManager.play_music("gameSong")
	
	# Set initial visibility states for gameplay
	hull_hud.visible = true
	end_result_hud.visible = false

func _process(delta):
	if PlayerConfig.finished and not game_ended:
		game_ended = true
		finish_game()
# Call this method when the game ends (e.g., player dies or beats stage)
func finish_game() -> void:
	# Hide gameplay HUD and show end results container
	hull_hud.visible = false
	end_result_hud.visible = true
	
	# Start the end sequence transition
	end_result_hud.start_results_sequence()
