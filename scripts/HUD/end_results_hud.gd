extends Control

# ==================================================
# UI NODE REFERENCES
# ==================================================

@onready var hull_transition = $EndResultsHullTransition
@onready var hud_end_static = $HudEndStatic
@onready var ending_status_label = $HudEndStatic/EndingStatus
@onready var hud_end_static_results = $HudEndStaticResults

# ==================================================
# INTERACTABLE ELEMENTS REFERENCES
# ==================================================

@onready var continue_button_static = $HudEndStatic/ContinueButton
@onready var leave_button = $HudEndStaticResults/LeaveButton

# NOTE: This node (gameResults) MUST be a VBoxContainer inside a ScrollContainer in your scene tree!
@onready var game_results_label = $HudEndStaticResults/ScrollContainer/gameResults

# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	# Sets the initial state of the UI components.
	# Only the transition elements will be shown initially when triggered.
	hull_transition.visible = false
	hud_end_static.visible = false
	hud_end_static_results.visible = false
	
	# Bind button signals to their respective event handlers.
	continue_button_static.pressed.connect(_on_continue_button_static_pressed)
	leave_button.pressed.connect(_on_leave_button_pressed)


# ==================================================
# SEQUENCE TRIGGERS
# ==================================================

# Triggers the initial end-game sequence.
# Designed to be called externally (e.g., from main game scene) when the match concludes.
func start_results_sequence() -> void:
	hull_transition.visible = true
	hull_transition.play("EndTransition")
	
	# Pause execution until the sprite animation finishes.
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static.visible = true
	
	update_final_status()


# Updates the main status label based on the local player's survival state.
func update_final_status() -> void:
	if PlayerConfig.isAlive:
		ending_status_label.text = "Você \nSaiu de orbita!"
	else:
		ending_status_label.text = "Você \nExplodiu"


# ==================================================
# BUTTON HANDLERS
# ==================================================

# Handler for the Continue button on the first results screen.
# Transitions the UI to the detailed statistics panel.
func _on_continue_button_static_pressed() -> void:
	hud_end_static.visible = false
	
	# Compile and instantiate UI labels prior to rendering the final screen.
	generate_results_text()
	
	hull_transition.visible = true
	hull_transition.play("ResultsTransition")
	
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static_results.visible = true


# Handler for the Leave button on the detailed statistics screen.
# Returns the player to the main menu and clears local data.
func _on_leave_button_pressed() -> void:
	PlayerConfig.clear()
	CurrentGame.clear()
	CurrentLobby.clear()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ==================================================
# DATA COMPILATION LOGIC (VBOXCONTAINER)
# ==================================================

# Compiles player performance data from PlayerConfig
# and dynamically instantiates Label nodes inside the VBoxContainer.
func generate_results_text() -> void:
	# 1. CLEANUP: Remove any existing child nodes from previous runs or editor previews
	for child in game_results_label.get_children():
		child.queue_free()
		
	# 2. PLAYER IDENTIFICATION
	_add_simple_label(PlayerConfig.username)
	
	# 3. SURVIVAL STATUS
	if PlayerConfig.isAlive:
		_add_simple_label("Saiu de orbita!")
	else:
		_add_simple_label("Explodiu!")
		
	# 4. REACHED ATMOSPHERE LAYER
	var layer_name: String = get_atmosphere_name(PlayerConfig.atmosLayer)
	_add_simple_label("Foi até a %s!" % layer_name)
	
	# 5. GENERAL GAMEPLAY STATISTICS
	if PlayerConfig.isAlive:
		_add_simple_label("Concluiu com %d vidas!" % PlayerConfig.lives)
		
	_add_simple_label("Sua altitude máxima foi %d km!" % PlayerConfig.maxAltitude)
	_add_simple_label("Pontuou %d pontos!" % PlayerConfig.points)
	
	# 6. ENCOUNTERS & COLLISIONS
	_add_simple_label("Teve %d encontros na trajetória!" % PlayerConfig.correctAnswers)
	_add_simple_label("Teve %d colisões!" % PlayerConfig.collisions)
	
	# 7. Q&A ACCURACY STATISTICS
	_add_simple_label("Acertou %d perguntas!" % PlayerConfig.correctAnswers)
	_add_simple_label("Errou %d perguntas!" % PlayerConfig.wrongAnswers)
	
	# 8. CAUSE OF DEATH (Appended conditionally)
	if not PlayerConfig.isAlive and PlayerConfig.collisionDeathObject != "Unknown" and PlayerConfig.collisionDeathObject != "":
		_add_simple_label("Colidiu com: %s" % PlayerConfig.collisionDeathObject)


# Helper function to dynamically instantiate text labels inside the VBoxContainer.
func _add_simple_label(text_content: String) -> void:
	var label = Label.new()
	label.text = text_content
	game_results_label.add_child(label)


# Helper function to map the atmosphere layer index to its corresponding name.
func get_atmosphere_name(layer_index: int) -> String:
	match layer_index:
		0: return "Troposfera"
		1: return "Estratosfera"
		2: return "Mesosfera"
		3: return "Termosfera"
		4: return "Exosfera"
		_: return "camada desconhecida"
