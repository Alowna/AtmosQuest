extends Control

# UI Node References
@onready var hull_transition = $EndResultsHullTransition
@onready var hud_end_static = $HudEndStatic
@onready var ending_status_label = $HudEndStatic/EndingStatus
@onready var hud_end_static_results = $HudEndStaticResults

# Interactable Elements References
@onready var continue_button_static = $HudEndStatic/ContinueButton
@onready var leave_button = $HudEndStaticResults/LeaveButton

# Data Display References
@onready var game_results_label = $HudEndStaticResults/ScrollContainer/gameResults

func _ready() -> void:
	# Sets the initial state of the UI components. 
	# Only the transition elements will be shown initially when triggered.
	hull_transition.visible = false
	hud_end_static.visible = false
	hud_end_static_results.visible = false
	
	# Bind button signals to their respective handlers
	continue_button_static.pressed.connect(_on_continue_button_static_pressed)
	leave_button.pressed.connect(_on_leave_button_pressed)

# Triggers the initial end-game sequence. 
# Designed to be called externally (e.g., from game.gd) when the match concludes.
func start_results_sequence() -> void:
	hull_transition.visible = true
	hull_transition.play("EndTransition")
	
	# Pause execution until the sprite animation finishes
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static.visible = true
	
	update_final_status()

# Updates the main status label based on the player's survival state.
func update_final_status() -> void:
	if PlayerConfig.isAlive:
		ending_status_label.text = "Você \nSaiu de orbita!"
	else:
		ending_status_label.text = "Você \nExplodiu"

# Handler for the Continue button on the first results screen.
# Transitions the UI to the detailed statistics panel.
func _on_continue_button_static_pressed() -> void:
	hud_end_static.visible = false
	
	# Compile the statistics text prior to rendering the final screen
	generate_results_text()
	
	hull_transition.visible = true
	hull_transition.play("ResultsTransition")
	
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static_results.visible = true

# Handler for the Leave button on the detailed statistics screen.
# Returns the player to the main menu.
func _on_leave_button_pressed() -> void:
	PlayerConfig.clear()
	CurrentGame.clear()
	CurrentLobby.clear()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ==========================================
# DATA COMPILATION LOGIC
# ==========================================

# Compiles player performance data from the PlayerConfig singleton 
# and formats it into a single multiline string for the results label.
func generate_results_text() -> void:
	var text_lines: Array = []
	
	# Player Identification
	text_lines.append(PlayerConfig.username)
	
	# Survival Status
	if PlayerConfig.isAlive:
		text_lines.append("Saiu de orbita!")
	else:
		text_lines.append("Explodiu!")
		
	# Reached Atmosphere Layer
	var layer_name = get_atmosphere_name(PlayerConfig.atmosLayer)
	text_lines.append("Foi até a %s!" % layer_name)
	
	# General Gameplay Statistics
	if PlayerConfig.isAlive:
		text_lines.append("Concluiu com %d vidas!" % PlayerConfig.lives)
		
	text_lines.append("Sua altitude máxima foi %d km!" % PlayerConfig.maxAltitude)
	text_lines.append("Pontuou %d pontos!" % PlayerConfig.points)
	
	# Encounters & Collisions
	# Using correctAnswers as successful encounters to avoid damage logic
	text_lines.append("Teve %d encontros na trajetória!" % PlayerConfig.correctAnswers) 
	text_lines.append("Teve %d colisões!" % PlayerConfig.collisions)
	
	# Q&A Accuracy Statistics
	text_lines.append("Acertou %d perguntas!" % PlayerConfig.correctAnswers)
	text_lines.append("Errou %d perguntas!" % PlayerConfig.wrongAnswers)
	
	# Cause of Death (Appended conditionally)
	if not PlayerConfig.isAlive and PlayerConfig.collisionDeathObject != "Unknown":
		text_lines.append("Colidiu com: %s" % PlayerConfig.collisionDeathObject)
	
	# Join the compiled array with line breaks and assign to the UI label
	game_results_label.text = "\n".join(text_lines)

# Helper function to map the atmosphere layer index to its corresponding name.
func get_atmosphere_name(layer_index: int) -> String:
	match layer_index:
		0: return "Troposfera"
		1: return "Estratosfera"
		2: return "Mesosfera"
		3: return "Termosfera"
		4: return "Exosfera"
		_: return "camada desconhecida"
