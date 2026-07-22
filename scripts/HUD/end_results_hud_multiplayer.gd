extends Control

# ==================================================
# UI NODE REFERENCES
# ==================================================

@onready var hull_transition = $EndResultsHullTransition
@onready var hud_end_static = $HudEndStatic
@onready var ending_status_label = $HudEndStatic/EndingStatus
@onready var hud_end_static_results= $HudEndStaticResults

# ==================================================
# INTERACTABLE ELEMENTS & LABELS REFERENCES
# ==================================================

@onready var continue_button_static= $HudEndStatic/ContinueButton
@onready var continue_button_status= $HudEndStatic/ContinueButton/ButtonStatus
@onready var leave_button= $HudEndStaticResults/LeaveButton
@onready var game_results_label= $HudEndStaticResults/ScrollContainer/gameResults

# ==================================================
# MULTIPLAYER & NETWORKING REFERENCES
# ==================================================

@onready var http_request: HTTPRequest = $HTTPRequest

# Prevents multiple HTTP requests from stacking or overlapping.
var is_processing_request := false
# Timer used to periodically poll the server for the game state.
var polling_timer: Timer
# Cache to store the final list of players retrieved from the server.
var cached_players_list: Array = []

# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	# Sets the initial state of the UI components. 
	hull_transition.visible = false
	hud_end_static.visible = false
	hud_end_static_results.visible = false
	
	# Ensures the button is locked from the very beginning
	continue_button_static.disabled = true
	continue_button_status.text = "Esperando\njogadores..."
	
	# Bind button and HTTP signals to their respective handlers
	continue_button_static.pressed.connect(_on_continue_button_static_pressed)
	leave_button.pressed.connect(_on_leave_button_pressed)
	http_request.request_completed.connect(_on_request_completed)
	
	# Setup the polling timer dynamically
	_setup_polling_timer()


# Creates and configures the Timer node responsible for server polling.
func _setup_polling_timer() -> void:
	polling_timer = Timer.new()
	polling_timer.wait_time = 2.0 # Polls the server every 2 seconds
	polling_timer.one_shot = false
	polling_timer.timeout.connect(_on_polling_timeout)
	add_child(polling_timer)


# ==================================================
# SEQUENCE TRIGGERS
# ==================================================

# Triggers the initial end-game sequence. 
func start_results_sequence() -> void:
	hull_transition.visible = true
	hull_transition.play("EndTransition")
	
	# Pause execution until the sprite animation finishes
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static.visible = true
	
	update_final_status()
	
	# Immediately start polling the server to check other players' status
	polling_timer.start()
	_on_polling_timeout()


# Updates the main status label based on the local player's survival state.
func update_final_status() -> void:
	if PlayerConfig.isAlive:
		ending_status_label.text = "Você \nSaiu de orbita!"
	else:
		ending_status_label.text = "Você \nExplodiu"


# ==================================================
# SERVER POLLING & GAME STATE LOGIC
# ==================================================

# Called every time the polling_timer reaches its wait_time.
func _on_polling_timeout() -> void:
	if is_processing_request:
		return
		
	is_processing_request = true
	
	# Fetch the current state using the existing route
	var url: String = "http://" + Env.api_base_url + "/get_game_state/" + CurrentGame.game_key
	
	http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_GET,
		""
	)


# Handles the result of the get_game_state request.
func _on_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	
	is_processing_request = false
	
	if response_code == 200:
		var response_data: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		
		if response_data and response_data.has("players"):
			var players_list: Array = response_data.get("players", [])
			var all_players_done := true
			
			# Cache the players list so we can build the leaderboard later
			cached_players_list = players_list
			
			# Check the status of every player in the lobby
			for p in players_list:
				var p_is_alive: bool = p.get("isAlive", true)
				var p_finished: bool = p.get("finished", false)
				
				# If someone is alive AND hasn't finished, the game is still running
				if p_is_alive and not p_finished:
					all_players_done = false
					break
			
			# If everyone is done, UNLOCK the button and stop polling
			if all_players_done:
				polling_timer.stop()
				continue_button_static.disabled = false
				continue_button_status.text = "Continuar"
	else:
		push_error("Error fetching game state. Server returned status: " + str(response_code))


# ==================================================
# BUTTON HANDLERS
# ==================================================

# Handler for the Continue button. Now it only works when enabled by the polling logic.
func _on_continue_button_static_pressed() -> void:
	# Prevent double clicks
	continue_button_static.disabled = true 
	_transition_to_final_results()


# Handler for the Leave button on the detailed statistics screen.
func _on_leave_button_pressed() -> void:
	PlayerConfig.clear()
	CurrentGame.clear()
	CurrentLobby.clear()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ==================================================
# SCREEN TRANSITIONS & DATA COMPILATION
# ==================================================

# Executes the visual transition to the final statistics screen.
func _transition_to_final_results() -> void:
	hud_end_static.visible = false
	
	# Compile the statistics text prior to rendering the final screen
	generate_results_text()
	
	hull_transition.visible = true
	hull_transition.play("ResultsTransition")
	
	await hull_transition.animation_finished
	
	hull_transition.visible = false
	hud_end_static_results.visible = true


# Compiles match performance data from all players fetched from the server
# and formats it into a leaderboard ordered by highest score.
func generate_results_text() -> void:
	var text_lines: Array = []
	var separator: String = "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
	
	# Cria uma cópia profunda (deep copy) da lista cacheada para poder injetar dados locais
	var sorted_players: Array = []
	for p in cached_players_list:
		sorted_players.append(p.duplicate())
	
	# ==================================================
	# INJEÇÃO DE DADOS DO PLAYERCONFIG LOCAL
	# ==================================================
	# Varre a lista copiada e, ao achar o ID do jogador local, sobrescreve 
	# os dados recebidos do servidor com a verdade contida no PlayerConfig.
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
	
	# Sort players descending by points (highest score first)
	sorted_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("points", 0) > b.get("points", 0)
	)
	
	text_lines.append("=== RANKING FINAL DA PARTIDA ===")
	text_lines.append(separator)
	
	# Iterate through each player to render their position and statistics
	for i in range(sorted_players.size()):
		var p: Dictionary = sorted_players[i]
		var position: int = i + 1
		
		# Extract player data from API dictionary with fallbacks
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
		
		# Format position line
		text_lines.append("#%d - %s (ID: %d)" % [position, p_name, p_id])
		
		# Survival status
		if p_alive:
			text_lines.append("Status: Saiu de órbita!")
		else:
			text_lines.append("Status: Explodiu!")
			
		# Atmosphere layer
		var layer_name: String = get_atmosphere_name(p_layer)
		text_lines.append("Camada: %s" % layer_name)
		
		# Stats
		if p_alive:
			text_lines.append("Vidas restantes: %d" % p_lives)
			
		text_lines.append("Altitude máxima: %d km" % p_max_alt)
		text_lines.append("Pontuação: %d pontos" % p_points)
		text_lines.append("Encontros na trajetória: %d" % p_correct)
		text_lines.append("Colisões totais: %d" % p_collisions)
		text_lines.append("Acertos: %d | Erros: %d" % [p_correct, p_wrong])
		
		# Death cause (if applicable)
		if not p_alive and p_death_obj != "Unknown" and p_death_obj != "":
			text_lines.append("Causa da morte: %s" % p_death_obj)
			
		# Add separator after every player
		text_lines.append(separator)
	
	# Assign the formatted text to the ScrollContainer label
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
