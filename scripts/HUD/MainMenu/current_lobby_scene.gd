extends Control

# Track finished entrance animations
var entrance_over: int = 0

# UI References
@onready var lobby_key_button: TextureButton = $LobbyKeyButton
@onready var back_button: TextureButton = $BackButton

# --- POLLING SYSTEM ---
var poll_timer := 0.0
var poll_delay := 1.0 # Polling interval in seconds
var http_request: HTTPRequest

# Game transition reference
@export_file("*.tscn") var target_scene: String 


func _ready() -> void:
	# Hide UI elements initially for the entrance animation sequence
	lobby_key_button.visible = false
	back_button.visible = false
	
	# Connect view entry animations
	$Base.animation_finished.connect(_on_entrance_animation_finished)
	$Skies.animation_finished.connect(_on_entrance_animation_finished)
	
	# Initialize network node programmatically to bypass scene dependencies
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_lobby_poll_completed)


func _on_entrance_animation_finished() -> void:
	entrance_over += 1
	
	# Present interactive elements once both baseline animations end
	if entrance_over >= 2:
		lobby_key_button.appear()
		back_button.appear()


func _process(delta: float) -> void:
	# Halt polling operations if the user is outside a room structure or the match began
	if CurrentLobby.lobbyKey.is_empty() or CurrentGame.has_started: 
		return
		
	poll_timer += delta
	if poll_timer >= poll_delay:
		poll_timer = 0.0
		_poll_lobby_state()


func _poll_lobby_state() -> void:
	# Only deploy a network request if the execution frame is cleared
	if http_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		var url := "http://" + Env.api_base_url + "/get_lobby/" + CurrentLobby.lobbyKey
		http_request.request(url)


func _on_lobby_poll_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var response: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		if not response: 
			return
		
		# SCENARIO 1: Server response indicates a match instance has been prepared
		if response.has("gameKey") and response["gameKey"] != "":
			_transition_everyone(str(response["gameKey"]))
			
		# SCENARIO 2: Server natively returns the full game map structure instead of a lobby
		elif response.has("key") and response.has("players") and response.has("events"):
			CurrentGame.update_from_dict(response)
			_transition_everyone(str(response["key"]))
			
		# SCENARIO 3: Regular execution state. Update information registers.
		else:
			CurrentLobby.update_from_dict(response)
			
			# CRITICAL FIX: If your scene contains a LobbyManager child instance, 
			# forcefully tell it to refresh its graphics since the dataset just changed.
			if has_node("LobbyManager"):
				get_node("LobbyManager").update_lobby_ships(CurrentLobby.players)
			
	elif response_code == 404:
		# SCENARIO 4: Room fallback trigger. Clean transition using legacy identification keys.
		_transition_everyone(CurrentLobby.lobbyKey)


func _transition_everyone(g_key: String) -> void:
	print("GLOBAL SIGNAL RECEIVED! Pulling everyone into game: ", g_key)
	
	var url := "http://" + Env.api_base_url + "/get_game_state/" + g_key
	var fetch_request := HTTPRequest.new()
	add_child(fetch_request)
	
	fetch_request.request_completed.connect(func(_res: int, code: int, _hdr: PackedStringArray, bdy: PackedByteArray) -> void:
		if code == 200:
			var game_data: Dictionary = JSON.parse_string(bdy.get_string_from_utf8())
			if game_data:
				# Store current structural simulation attributes
				CurrentGame.update_from_dict(game_data)
				CurrentLobby.clear() 
				
				if not target_scene.is_empty():
					get_tree().change_scene_to_file(target_scene)
				else:
					push_error("WARNING: Missing target_scene inside the Lobby Scene configuration.")
		fetch_request.queue_free() # Clean up the temporary node
	)
	
	fetch_request.request(url)
