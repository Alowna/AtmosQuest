extends Node2D

# Reference to the local player's ship.
@onready var local_player = $PlayerShip

# Rival ship slots already placed in the scene.
@onready var rival_1: PlayerShip = $RivalShip1
@onready var rival_2: PlayerShip = $RivalShip2


# How often the game polls the server.
var poll_delay := 0.1
var poll_timer := 0.0


# Stores the rival slots and
# maps online player IDs to them.
var rival_slots: Array = []
var id_to_rival_node: Dictionary = {}


# HTTP request used for polling.
var http_request: HTTPRequest


func _ready():

	# Create the polling request.
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_game_state_received)

	# Register all available rival slots.
	rival_slots = [rival_1, rival_2]

	# Assign the closest players to the rival slots.
	_assign_closest_lobby_rivals()


func _process(delta):

	poll_timer += delta

	# Poll the server at a fixed interval.
	if poll_timer >= poll_delay:

		poll_timer = 0.0

		_send_local_altitude()
		_fetch_game_state()

	# Update rival positions every frame.
	_update_rival_positions()


# ==================================================
# NETWORK OUTBOUND
# Sends the local player's altitude.
# ==================================================

func _send_local_altitude():

	if not CurrentGame.is_active():
		return

	var url = "http://" + Env.api_base_url + "/game_action"

	var headers = [
		"Content-Type: application/json"
	]

	var payload = {
		"gameKey": CurrentGame.game_key,
		"playerId": PlayerConfig.online_id,
		"action": "altitude",

		# Send altitude in kilometers.
		"altitude": int(local_player.altitude_km)
	}

	# Create a temporary request.
	var sender = HTTPRequest.new()

	add_child(sender)

	sender.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)

	sender.request_completed.connect(
		func(_a, _b, _c, _d):
			sender.queue_free()
	)


# ==================================================
# NETWORK INBOUND
# Retrieves the latest game state.
# ==================================================

func _fetch_game_state():

	if not CurrentGame.is_active():
		return

	var url = "http://" + Env.api_base_url + "/get_game_state/" + CurrentGame.game_key

	# Don't start another request while one is active.
	if http_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		http_request.request(url)


func _on_game_state_received(_result, response_code, _headers, body):

	if response_code != 200:
		return

	var response = JSON.parse_string(body.get_string_from_utf8())

	if not response:
		return

	# Update the current game data.
	CurrentGame.update_from_dict(response)


# ==================================================
# RIVAL SLOT MANAGEMENT
# Assigns online players to the rival slots.
# ==================================================

func _assign_closest_lobby_rivals():

	var local_id = PlayerConfig.online_id

	var other_players = []

	# Ignore the local player.
	for p in CurrentGame.players:

		if p["id"] != local_id:
			other_players.append(p)

	# Prioritize players with IDs closest to ours.
	other_players.sort_custom(
		func(a, b):
			return abs(a["id"] - local_id) < abs(b["id"] - local_id)
	)

	# Hide every rival until assigned.
	rival_1.visible = false
	rival_2.visible = false

	for i in range(rival_slots.size()):

		var slot_node = rival_slots[i]

		if i < other_players.size():

			var player_data = other_players[i]
			var r_id = player_data["id"]

			slot_node.remote_player_id = r_id
			slot_node.visible = true

			# Apply the rival's selected skin.
			if slot_node.has_method("_apply_rival_skins"):
				slot_node._apply_rival_skins()

			id_to_rival_node[r_id] = slot_node

			print("Slot ", i + 1, " bound to player ID: ", r_id)

		else:

			# Remove unused rival slots.
			slot_node.queue_free()


# ==================================================
# RIVAL MOVEMENT
# Keeps rivals aligned with the local player's height.
# ==================================================

func _update_rival_positions():

	for r_id in id_to_rival_node:

		var rival_node = id_to_rival_node[r_id]

		if is_instance_valid(rival_node):

			rival_node.global_position.y = local_player.global_position.y
