extends Node2D

# ==================================================
# SCENE NODE REFERENCES
# ==================================================

# Reference to the local player's ship.
@onready var local_player = $PlayerShip

# Rival ship slots placed in the scene.
@onready var rival_1 = $RivalShip1
@onready var rival_2 = $RivalShip2

# CanvasLayer HUD references.
@onready var hull_hud = $CanvasLayer/Hull
@onready var end_result_hud = $CanvasLayer/EndResultsHud

# ==================================================
# POLLING & RIVAL VARIABLES
# ==================================================

# Interval in seconds between server polls.
var poll_delay := 0.1
var poll_timer := 0.0

# Prevents concurrent polling requests if a network request takes longer than poll_delay.
var is_fetching_state := false

# Stores the available rival slots and maps online player IDs to them.
var rival_slots: Array = []
var id_to_rival_node: Dictionary = {}

# Tracks whether the local gameplay session has finished.
var local_game_ended := false

# Movement speeds for rival death transitions.
var death_rise_speed := 500.0
var death_decline_speed := 20.0

# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	AudioManager.play_music("gameSong")
	
	# Set initial UI visibility states for gameplay.
	hull_hud.visible = true
	end_result_hud.visible = false

	# Register all available rival slots.
	rival_slots = [rival_1, rival_2]

	# Assign nearest lobby players to rival slots.
	_assign_closest_lobby_rivals()


func _process(delta: float) -> void:
	poll_timer += delta

	# Poll the server at fixed intervals.
	if poll_timer >= poll_delay:
		poll_timer = 0.0
		_send_local_altitude()
		_fetch_game_state()

	# Interpolate rival positions every frame.
	_update_rival_positions(delta)
	
	# Check if local player finished the game.
	if PlayerConfig.finished and not local_game_ended:
		local_game_ended = true
		finish_local_game()

# ==================================================
# NETWORK OUTBOUND
# ==================================================

# Sends the local player's updated metrics and state to the server via API.
func _send_local_altitude() -> void:
	if not CurrentGame.is_active():
		return

	# Build payload from local PlayerConfig state.
	var payload: Dictionary = {
		"gameKey": CurrentGame.game_key,
		"playerId": PlayerConfig.online_id,
		"action": "altitude",
		"atmosLayer": PlayerConfig.atmosLayer,
		"altitude": int(PlayerConfig.altitude),
		"isAlive": PlayerConfig.isAlive,
		"lives": PlayerConfig.lives,
		"points": PlayerConfig.points,
		"collisions": PlayerConfig.collisions,
		"correctAnswers": PlayerConfig.correctAnswers,
		"wrongAnswers": PlayerConfig.wrongAnswers,
		"collisionObject": PlayerConfig.collisionDeathObject
	}

	# Send request through the Api autoload.
	Api.send_game_action(payload)


# Sends the final finish action to unlock the lobby for remaining players.
func _send_local_finish() -> void:
	if not CurrentGame.is_active():
		return

	var payload: Dictionary = {
		"gameKey": CurrentGame.game_key,
		"playerId": PlayerConfig.online_id,
		"action": "finish"
	}

	# Send finish request through Api autoload.
	Api.send_game_action(payload)

# ==================================================
# NETWORK INBOUND
# ==================================================

# Retrieves the latest game state from the API and updates CurrentGame.
func _fetch_game_state() -> void:
	if not CurrentGame.is_active() or is_fetching_state:
		return

	is_fetching_state = true
	
	# Fetch game state from Api autoload and await response.
	var response_data: Dictionary = await Api.get_game_state(CurrentGame.game_key)
	
	is_fetching_state = false

	# Update central CurrentGame data if payload is valid.
	if not response_data.is_empty():
		CurrentGame.update_from_dict(response_data)

# ==================================================
# RIVAL SLOT MANAGEMENT
# ==================================================

# Binds closest online players to rival visual nodes based on online IDs.
func _assign_closest_lobby_rivals() -> void:
	var local_id: int = PlayerConfig.online_id
	var other_players: Array = []

	# Filter out local player from CurrentGame player list.
	for p in CurrentGame.players:
		if p.get("id", -1) != local_id:
			other_players.append(p)

	# Prioritize players with IDs closest to local player ID.
	other_players.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return abs(a.get("id", 0) - local_id) < abs(b.get("id", 0) - local_id)
	)

	# Hide all rival slots prior to assignment.
	rival_1.visible = false
	rival_2.visible = false

	for i in range(rival_slots.size()):
		var slot_node = rival_slots[i]

		if i < other_players.size():
			var player_data: Dictionary = other_players[i]
			var r_id: int = player_data.get("id", 0)

			slot_node.remote_player_id = r_id
			slot_node.visible = true

			# Apply rival skin configuration if function exists.
			if slot_node.has_method("_apply_rival_skins"):
				slot_node._apply_rival_skins()

			id_to_rival_node[r_id] = slot_node
			print("Slot ", i + 1, " bound to player ID: ", r_id)
		else:
			# Free unused rival slot instances.
			slot_node.queue_free()

# ==================================================
# RIVAL MOVEMENT
# ==================================================

# Keeps rivals synchronized relative to local player altitude and death status.
func _update_rival_positions(delta: float) -> void:
	for r_id in id_to_rival_node:
		var rival_node = id_to_rival_node[r_id]

		if is_instance_valid(rival_node):
			# If local player dies, rival advances upward.
			if not PlayerConfig.isAlive and not rival_node.kaboom_done:
				rival_node.global_position.y = move_toward(
					rival_node.global_position.y,
					rival_node.global_position.y - 1000,
					death_rise_speed * delta
				)
			else:
				# Keep rival aligned with local player position or handle rival death.
				if rival_node.kaboom_done:
					rival_node.global_position.y = move_toward(
						rival_node.global_position.y,
						rival_node.global_position.y + 1000,
						death_decline_speed * delta
					)
				else:
					rival_node.global_position.y = local_player.global_position.y - 10.0

# ==================================================
# GAME OVER ROUTINES
# ==================================================

# Handles end of local gameplay session and triggers results presentation.
func finish_local_game() -> void:
	# Hide gameplay HUD and display results container.
	hull_hud.visible = false
	end_result_hud.visible = true
	
	# Start end sequence animation / polling transition.
	end_result_hud.start_results_sequence()
	
	# Notify server of local completion status.
	_send_local_finish()
