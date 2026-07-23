extends Control

# ==================================================
# VARIABLES & REFERENCES
# ==================================================

# Track finished entrance animations.
var entrance_over: int = 0

# UI References.
@onready var lobby_key_button: TextureButton = $LobbyKeyButton
@onready var back_button: TextureButton = $BackButton

# --- POLLING SYSTEM ---
var poll_timer := 0.0
var poll_delay := 1.0 # Polling interval in seconds.

# Prevents concurrent polling requests if network is slow.
var is_fetching_state := false

# Game transition reference.
@export_file("*.tscn") var target_scene: String 

# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	# Hide UI elements initially for the entrance animation sequence.
	lobby_key_button.visible = false
	back_button.visible = false
	
	# Connect view entry animations.
	$Base.animation_finished.connect(_on_entrance_animation_finished)
	$Skies.animation_finished.connect(_on_entrance_animation_finished)


# Presents interactive elements once both baseline animations end.
func _on_entrance_animation_finished() -> void:
	entrance_over += 1
	
	if entrance_over >= 2:
		lobby_key_button.appear()
		back_button.appear()


# ==================================================
# POLLING LOGIC
# ==================================================

func _process(delta: float) -> void:
	# Halt polling operations if the user is outside a room, the match began, or a request is active.
	if CurrentLobby.lobbyKey.is_empty() or CurrentGame.has_started or is_fetching_state: 
		return
		
	poll_timer += delta
	if poll_timer >= poll_delay:
		poll_timer = 0.0
		_poll_lobby_state()


# Fetches the current lobby state via the Api autoload.
func _poll_lobby_state() -> void:
	is_fetching_state = true
	
	# Fetch lobby data via Api.
	var response: Dictionary = await Api.get_lobby(CurrentLobby.lobbyKey)
	
	is_fetching_state = false
	
	# Handle empty responses or errors gracefully.
	if response.is_empty():
		return
		
	# SCENARIO 4: Room fallback trigger (API returned a 404). Clean transition using legacy keys.
	if response.has("_is_404"):
		_transition_everyone(CurrentLobby.lobbyKey)
		return
		
	# SCENARIO 1: Server response indicates a match instance has been prepared.
	if response.has("gameKey") and response["gameKey"] != "":
		_transition_everyone(str(response["gameKey"]))
		
	# SCENARIO 2: Server natively returns the full game map structure instead of a lobby.
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


# ==================================================
# SCENE TRANSITION
# ==================================================

# Prepares the client to enter the game state by fetching match info and swapping scenes.
func _transition_everyone(g_key: String) -> void:
	print("GLOBAL SIGNAL RECEIVED! Pulling everyone into game: ", g_key)
	
	# Fetch the target game state using the existing Api autoload method!
	var game_data: Dictionary = await Api.get_game_state(g_key)
	
	if not game_data.is_empty():
		# Store current structural simulation attributes.
		CurrentGame.update_from_dict(game_data)
		CurrentLobby.clear() 
		
		# Execute visual transition.
		if not target_scene.is_empty():
			get_tree().change_scene_to_file(target_scene)
		else:
			push_error("WARNING: Missing target_scene inside the Lobby Scene configuration.")
