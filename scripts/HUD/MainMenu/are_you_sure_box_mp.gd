extends Control

@onready var BackToMenu: Button = $BackToMenu
@onready var ContinueGame: Button = $ContinueGame

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	BackToMenu.pressed.connect(_on_back_to_menu_pressed)
	ContinueGame.pressed.connect(_on_continue_game_pressed)

func start() -> void:
	visible = true
	PlayerConfig.controls_locked = true

func _on_back_to_menu_pressed() -> void:
	await Api.leave_game(CurrentGame.game_key, PlayerConfig.online_id)
	PlayerConfig.clear()
	CurrentGame.clear()
	AudioManager.stop_all_game_sounds()
	
	get_tree().paused = false
	
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_continue_game_pressed() -> void:
	PlayerConfig.controls_locked = false
	visible = false
