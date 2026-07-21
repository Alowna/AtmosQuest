extends Control

# Node references
@onready var hull_transition = $EndResultsHullTransition
@onready var hud_end_static = $HudEndStatic
@onready var ending_status_label = $HudEndStatic/EndingStatus
@onready var hud_end_static_result = $HudEndStaticResults

# New reference for the Continue button inside HudEndStatic
@onready var continue_button_static = $HudEndStatic/ContinueButton

# Reference for the final results label
@onready var game_results_label = $HudEndStaticResults/ScrollContainer/gameResults

func _ready() -> void:
	# Ensure all transition elements are initially hidden
	hull_transition.visible = false
	hud_end_static.visible = false
	hud_end_static_result.visible = false
	
	# Connect the pressed signal from the Continue button
	continue_button_static.pressed.connect(_on_continue_button_static_pressed)

# Public method to trigger the sequence from game.gd
func start_results_sequence() -> void:
	hull_transition.visible = true
	hull_transition.play("EndTransition")
	
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static.visible = true
	
	update_final_status()

func update_final_status() -> void:
	if PlayerConfig.isAlive:
		ending_status_label.text = "Você \nSaiu de orbita!"
	else:
		ending_status_label.text = "Você \nExplodiu"

# Function called when the first Continue button is pressed
func _on_continue_button_static_pressed() -> void:
	hud_end_static.visible = false
	
	# Generate the massive results text before showing the screen
	generate_results_text()
	
	hull_transition.visible = true
	hull_transition.play("ResultsTransition")
	
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static_result.visible = true

# ==========================================
# TEXT GENERATION LOGIC
# ==========================================

func generate_results_text() -> void:
	# Array to hold all the lines of text
	var text_lines: Array = []
	
	# Username and Online ID
	text_lines.append(PlayerConfig.username + " " + str(PlayerConfig.online_id))
	
	# Alive or Dead status
	if PlayerConfig.isAlive:
		text_lines.append("Saiu de orbita!")
	else:
		text_lines.append("Explodiu!")
		
	# Atmosphere Layer
	var layer_name = get_atmosphere_name(PlayerConfig.atmosLayer)
	text_lines.append("Foi até a %s!" % layer_name)
	
	# General Stats
	if PlayerConfig.isAlive:
		text_lines.append("Concluiu com %d vidas!" % PlayerConfig.lives)
	text_lines.append("Sua altitude máxima foi %d!" % PlayerConfig.maxAltitude % " km")
	text_lines.append("Pontuou %d pontos!" % PlayerConfig.points)
	
	# Encounters & Collisions
	# Using correctAnswers as the encounter count, as requested
	text_lines.append("Teve %d encontros!" % PlayerConfig.collisions) 
	
	# Q&A Stats
	text_lines.append("Acertou %d perguntas!" % PlayerConfig.correctAnswers)
	text_lines.append("Errou %d perguntas!" % PlayerConfig.wrongAnswers)
	
	# Death Object (Only add this line if player died AND object is known)
	if not PlayerConfig.isAlive and PlayerConfig.collisionDeathObject != "Unknown":
		text_lines.append("Colidiu com: %s" % PlayerConfig.collisionDeathObject)
	
	# Join all lines in the array with a line break (\n) and assign to the label
	game_results_label.text = "\n".join(text_lines)

# Helper function to convert the integer layer into a String
func get_atmosphere_name(layer_index: int) -> String:
	# WARNING: Adjust these integer numbers based on how your game counts layers!
	match layer_index:
		0: return "Troposfera"
		1: return "Estratosfera"
		2: return "Mesosfera"
		3: return "Termosfera"
		4: return "Exosfera"
		_: return "camada desconhecida"
