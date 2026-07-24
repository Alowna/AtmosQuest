extends Control

# ==================================================
# UI NODE REFERENCES
# ==================================================

@onready var hull_transition = $EndResultsHullTransition
@onready var hud_end_static = $HudEndStatic
@onready var ending_status_label = $HudEndStatic/EndingStatus
@onready var hud_end_static_results = $HudEndStaticResults

# ==================================================
# INTERACTABLE ELEMENTS & LABELS REFERENCES
# ==================================================

@onready var continue_button_static = $HudEndStatic/ContinueButton
@onready var continue_button_status = $HudEndStatic/ContinueButton/ButtonStatus
@onready var leave_button = $HudEndStaticResults/LeaveButton


@onready var game_results_label = $HudEndStaticResults/ScrollContainer/gameResults

# ==================================================
# MULTIPLAYER & NETWORKING VARIABLES
# ==================================================

# Prevents multiple HTTP requests from stacking or overlapping.
var is_processing_request := false
# Timer used to periodically poll the server for the global game state.
var polling_timer: Timer

# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	# Sets the initial visibility state of all UI components.
	hull_transition.visible = false
	hud_end_static.visible = false
	hud_end_static_results.visible = false
	
	# Ensures the continue button is locked upon entering the results sequence.
	continue_button_static.disabled = true
	continue_button_status.text = "Esperando\njogadores..."
	
	# Bind button signals to their respective event handlers.
	continue_button_static.pressed.connect(_on_continue_button_static_pressed)
	leave_button.pressed.connect(_on_leave_button_pressed)
	
	# Setup the server polling timer dynamically.
	_setup_polling_timer()


# Creates and configures the Timer node responsible for server polling.
func _setup_polling_timer() -> void:
	polling_timer = Timer.new()
	polling_timer.wait_time = 2.0 # Polls the server every 2 seconds.
	polling_timer.one_shot = false
	polling_timer.timeout.connect(_on_polling_timeout)
	add_child(polling_timer)


# Called automatically when the node is removed from the scene tree.
func _exit_tree() -> void:
	# Failsafe to ensure the timer is stopped and cleaned up when exiting.
	if polling_timer and not polling_timer.is_stopped():
		polling_timer.stop()


# ==================================================
# SEQUENCE TRIGGERS
# ==================================================

# Triggers the initial end-game transition sequence.
func start_results_sequence() -> void:
	hull_transition.visible = true
	hull_transition.play("EndTransition")
	
	# Pause execution until the hull transition animation finishes.
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static.visible = true
	
	update_final_status()
	
	# Immediately start polling the server to monitor other players' status.
	polling_timer.start()
	_on_polling_timeout()


# Updates the primary status label based on the local player's survival state.
func update_final_status() -> void:
	if PlayerConfig.isAlive:
		ending_status_label.text = "Você \nSaiu de orbita!"
	else:
		ending_status_label.text = "Você \nExplodiu"


# ==================================================
# SERVER POLLING & GAME STATE LOGIC
# ==================================================

# Called every time the polling_timer reaches its timeout interval.
func _on_polling_timeout() -> void:
	if is_processing_request:
		return
		
	is_processing_request = true
	
	# Pause the timer during request processing to prevent overlapping ticks.
	polling_timer.stop()
	
	# Fetch the current match state via the Api Autoload.
	var response_data: Dictionary = await Api.get_game_state(CurrentGame.game_key)
	
	is_processing_request = false
	
	# Validate network response.
	if not response_data.is_empty():
		# Pass the raw dictionary to CurrentGame Autoload to update global state.
		CurrentGame.update_from_dict(response_data)
		
		var all_players_done := true
		
		# Check the completion status of every registered player.
		for p in CurrentGame.players:
			var p_is_alive: bool = p.get("isAlive", true)
			var p_finished: bool = p.get("finished", false)
			
			# If any player is alive AND has not finished, the game is still running.
			if p_is_alive and not p_finished:
				all_players_done = false
				break
		
		if all_players_done:
			# EVERYONE HAS FINISHED: Stop timer and unlock the continue button.
			continue_button_static.disabled = false
			continue_button_status.text = "Continuar"
		else:
			# GAME STILL RUNNING: Resume timer for the next check cycle.
			polling_timer.start()
	else:
		push_error("EndResultsHud: Failed to fetch game state or empty payload received.")
		# Restart timer on error to attempt a retry in 2 seconds.
		polling_timer.start()


# ==================================================
# BUTTON HANDLERS
# ==================================================

# Handler for the Continue button. Unlocked only when all players finish the match.
func _on_continue_button_static_pressed() -> void:
	# Prevent double clicks.
	continue_button_static.disabled = true
	_transition_to_final_results()


# Handler for the Leave button on the detailed statistics leaderboard.
func _on_leave_button_pressed() -> void:
	PlayerConfig.clear()
	CurrentGame.clear()
	CurrentLobby.clear()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ==================================================
# SCREEN TRANSITIONS & DATA COMPILATION
# ==================================================

# Executes the visual transition to the final leaderboard statistics screen.
func _transition_to_final_results() -> void:
	# Failsafe: Stop server polling immediately upon entering final screen.
	if polling_timer and not polling_timer.is_stopped():
		polling_timer.stop()
		
	hud_end_static.visible = false
	
	# Compile and instantiate the dynamic leaderboard elements.
	generate_results_text()
	
	hull_transition.visible = true
	hull_transition.play("ResultsTransition")
	
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static_results.visible = true


# Compiles performance metrics from all players and instantiates a UI leaderboard
# ordered descending by highest total score.
func generate_results_text() -> void:
	# 1. CLEANUP: Remove old preview nodes or previous player entries
	for child in game_results_label.get_children():
		child.queue_free()
		
	var separator: String = "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
	
	# 2. PRE-LOAD TROPHY TEXTURES
	var gold_tex = load("res://assets/props/GoldTrophy.png")
	var silver_tex = load("res://assets/props/SilverTrophy.png")
	var bronze_tex = load("res://assets/props/BronzeTrophy.png")
	
	# 3. CLONE PLAYER DATA
	var sorted_players: Array = []
	for p in CurrentGame.players:
		sorted_players.append(p.duplicate())
	
	# 4. INJECT LOCAL PLAYERCONFIG TRUTH
	# Overwrite local player's dictionary entries with local client data.
	for i in range(sorted_players.size()):
		if int(sorted_players[i].get("id", 0)) == PlayerConfig.online_id:
			sorted_players[i]["isAlive"] = PlayerConfig.isAlive
			sorted_players[i]["atmosLayer"] = PlayerConfig.atmosLayer
			sorted_players[i]["lives"] = PlayerConfig.lives
			sorted_players[i]["maxAltitude"] = PlayerConfig.maxAltitude
			sorted_players[i]["points"] = PlayerConfig.points
			sorted_players[i]["collisions"] = PlayerConfig.collisions
			sorted_players[i]["correctAnswers"] = PlayerConfig.correctAnswers
			sorted_players[i]["wrongAnswers"] = PlayerConfig.wrongAnswers
			sorted_players[i]["collisionDeathObject"] = PlayerConfig.collisionDeathObject
			break
	
	# Sort players in descending order based on total score.
	sorted_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("points", 0) > b.get("points", 0)
	)
	
	# 5. RENDER LEADERBOARD HEADER
	_add_simple_label("=== RANKING FINAL DA PARTIDA ===")
	_add_simple_label(separator)
	
	# 6. RENDER EACH PLAYER ENTRY
	for i in range(sorted_players.size()):
		var p: Dictionary = sorted_players[i]
		var position: int = i + 1
		
		# Safely extract dictionary attributes with default fallbacks
		var p_name: String = p.get("username", "Jogador")
		var p_id: int = int(p.get("id", 0))
		var p_alive: bool = p.get("isAlive", false)
		var p_layer: int = int(p.get("atmosLayer", 0))
		var p_lives: int = int(p.get("lives", 0))
		var p_max_alt: int = int(p.get("maxAltitude", 0))
		var p_points: int = int(p.get("points", 0))
		var p_collisions: int = int(p.get("collisions", 0))
		var p_correct: int = int(p.get("correctAnswers", 0))
		var p_wrong: int = int(p.get("wrongAnswers", 0))
		var p_death_obj: String = p.get("collisionDeathObject", "Unknown")
		
		# -- DYNAMIC HBOX CONTAINER FOR NAME & TROPHY ICON --
		var header_hbox := HBoxContainer.new()
		

		
		# Assign Trophy Texture based on final rank position
		var trophy_texture: Texture2D = null
		if position == 1:
			trophy_texture = gold_tex
		elif position == 2:
			trophy_texture = silver_tex
		elif position == 3:
			trophy_texture = bronze_tex
		elif position >3:
			# Position Prefix Label (#1 - )
			var pos_label := Label.new()
			pos_label.text = "#%d - " % position
			header_hbox.add_child(pos_label)
			
		# Instantiate Trophy TextureRect if player placed in top 3
		if trophy_texture:
			var trophy_rect := TextureRect.new()
			trophy_rect.texture = trophy_texture
			trophy_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			trophy_rect.custom_minimum_size = Vector2(24, 24) # Adjust icon dimensions if needed
			trophy_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			header_hbox.add_child(trophy_rect)
			
		# Username 
		var name_label := Label.new()
		name_label.text = " %s " % [p_name]
		header_hbox.add_child(name_label)
		
		# Add the main header row to the parent VBoxContainer
		game_results_label.add_child(header_hbox)
		
		# -- RENDER INDIVIDUAL STATISTIC LINES --
		if p_alive:
			_add_simple_label("Status: Saiu de órbita!")
		else:
			_add_simple_label("Status: Explodiu!")
			
		var layer_name: String = get_atmosphere_name(p_layer)
		_add_simple_label("Camada: %s" % layer_name)
		
		if p_alive:
			_add_simple_label("Vidas restantes: %d" % p_lives)
			
		_add_simple_label("Altitude máxima: %d km" % p_max_alt)
		_add_simple_label("Pontuação: %d pontos" % p_points)
		_add_simple_label("Encontros na trajetória: %d" % p_correct)
		_add_simple_label("Colisões totais: %d" % p_collisions)
		_add_simple_label("Acertos: %d | Erros: %d" % [p_correct, p_wrong])
		
		if not p_alive and p_death_obj != "Unknown" and p_death_obj != "":
			_add_simple_label("Causa da morte: %s" % p_death_obj)
			
		_add_simple_label(separator)


# Helper function to dynamically instantiate text labels inside the VBoxContainer.
func _add_simple_label(text_content: String) -> void:
	var label := Label.new()
	label.text = text_content
	game_results_label.add_child(label)


# Helper function mapping atmospheric layer indices to their localized names.
func get_atmosphere_name(layer_index: int) -> String:
	match layer_index:
		0: return "Troposfera"
		1: return "Estratosfera"
		2: return "Mesosfera"
		3: return "Termosfera"
		4: return "Exosfera"
		_: return "camada desconhecida"
