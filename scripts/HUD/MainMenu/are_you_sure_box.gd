extends Control

@onready var BackToMenu: Button = $BackToMenu
@onready var ContinueGame: Button = $ContinueGame

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	BackToMenu.pressed.connect(_on_back_to_menu_pressed)
	ContinueGame.pressed.connect(_on_continue_game_pressed)

func start() -> void:
	visible = true
	get_tree().paused = true

func _on_back_to_menu_pressed() -> void:
	PlayerConfig.clear()
	CurrentGame.clear()
	AudioManager.stop_all_game_sounds()
	
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_continue_game_pressed() -> void:
	get_tree().paused = false
	visible = false
