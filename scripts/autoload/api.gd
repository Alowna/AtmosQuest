extends Node

# Autoload: Api
# Handles HTTP requests to the backend API endpoints.

func get_game_state(game_key: String) -> Dictionary:
	var url: String = "http://" + Env.api_base_url + "/get_game_state/" + game_key
	
	# Create a HTTPRequest node dynamically for this request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_GET,
		""
	)
	
	if error != OK:
		push_error("API: Request initiation failed for " + url)
		http_request.queue_free()
		return {}
	
	# Wait for the server response asynchronously
	var result = await http_request.request_completed
	
	# Failsafe: ensure node is still in tree if scene changes during wait
	if not is_inside_tree():
		http_request.queue_free()
		return {}
	
	# result Array format: [result, response_code, headers, body]
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]
	
	# Clean up the dynamic HTTPRequest node after execution completes
	http_request.queue_free()
	
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		
		# Verify that JSON parsing succeeded and returned a valid Dictionary
		if typeof(response_data) == TYPE_DICTIONARY:
			return response_data
		else:
			push_error("API: Invalid JSON format received from server.")
			return {}
	else:
		push_error("API: Error fetching game state. Server returned status: " + str(response_code))
		return {}
		
func send_game_action(payload: Dictionary) -> void:
	var url: String = "http://" + Env.api_base_url + "/game_action"
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	
	if error != OK:
		push_error("API: Action request initiation failed for " + url)
		http_request.queue_free()
		return
	
	# Wait for request completion and auto-free the request node
	await http_request.request_completed
	if is_instance_valid(http_request):
		http_request.queue_free()

# ==================================================
# LOBBY ENDPOINTS
# ==================================================

# Fetches the current state of a lobby. Returns a special flag if not found (404).
func get_lobby(lobby_key: String) -> Dictionary:
	var url: String = "http://" + Env.api_base_url + "/get_lobby/" + lobby_key
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_GET,
		""
	)
	
	if error != OK:
		push_error("API: Lobby request initiation failed for " + url)
		http_request.queue_free()
		return {}
	
	var result = await http_request.request_completed
	
	if not is_inside_tree():
		http_request.queue_free()
		return {}
		
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]
	
	http_request.queue_free()
	
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if typeof(response_data) == TYPE_DICTIONARY:
			return response_data
		else:
			push_error("API: Invalid JSON format received from server.")
			return {}
	elif response_code == 404:
		# Special case: The lobby was likely destroyed or converted into a match.
		return {"_is_404": true}
	else:
		push_error("API: Error fetching lobby. Server returned status: " + str(response_code))
		return {}
		
# ==================================================
# LEAVE LOBBY ENDPOINT
# Notifies the server that a player is leaving the lobby.
# ==================================================

func leave_lobby(lobby_key: String, player_id: int) -> bool:
	var url: String = "http://" + Env.api_base_url + "/leave_lobby?lobbyKey=" + lobby_key + "&playerId=" + str(player_id)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		""
	)
	
	if error != OK:
		push_error("API: Leave lobby request initiation failed for " + url)
		http_request.queue_free()
		return false
	
	var result = await http_request.request_completed
	
	if not is_inside_tree():
		http_request.queue_free()
		return false
		
	var response_code: int = result[1]
	http_request.queue_free()
	
	if response_code == 200:
		return true
	else:
		push_error("API: Failed to leave lobby. Server returned status: " + str(response_code))
		return false
	
# ==================================================
# LEAVE SERVER ENDPOINT
# Removes a player from the online server list.
# ==================================================

func leave_server(player_id: int) -> bool:
	var url: String = "http://" + Env.api_base_url + "/leave_server?id=" + str(player_id)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		""
	)
	
	if error != OK:
		push_error("API: Leave server request initiation failed for " + url)
		http_request.queue_free()
		return false
	
	var result = await http_request.request_completed
	
	if not is_inside_tree():
		http_request.queue_free()
		return false
		
	var response_code: int = result[1]
	http_request.queue_free()
	
	# Accept successful deletion responses (200 = OK, 204 = No Content).
	if response_code == 200 or response_code == 204:
		return true
	else:
		push_error("API: Failed to leave server. Server returned status: " + str(response_code))
		return false


# ==================================================
# JOIN LOBBY ENDPOINT
# Requests to join an existing lobby using a specific key.
# ==================================================

func join_lobby(lobby_key: String, player_id: int) -> Dictionary:
	var url: String = "http://" + Env.api_base_url + "/join_lobby?lobbyKey=" + lobby_key + "&playerId=" + str(player_id)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		""
	)
	
	if error != OK:
		push_error("API: Join lobby request initiation failed for " + url)
		http_request.queue_free()
		return {}
	
	var result = await http_request.request_completed
	
	if not is_inside_tree():
		http_request.queue_free()
		return {}
		
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]
	http_request.queue_free()
	
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if typeof(response_data) == TYPE_DICTIONARY:
			return response_data
		else:
			push_error("API: Invalid JSON format received from server.")
			return {}
	else:
		push_error("API: Failed to join lobby. Server returned status: " + str(response_code))
		return {}


# ==================================================
# CREATE LOBBY ENDPOINT
# Requests the server to generate a new lobby room.
# ==================================================

func create_lobby(owner_id: int) -> Dictionary:
	var url: String = "http://" + Env.api_base_url + "/create_lobby?ownerId=" + str(owner_id)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		""
	)
	
	if error != OK:
		push_error("API: Create lobby request initiation failed for " + url)
		http_request.queue_free()
		return {}
	
	var result = await http_request.request_completed
	
	if not is_inside_tree():
		http_request.queue_free()
		return {}
		
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]
	http_request.queue_free()
	
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if typeof(response_data) == TYPE_DICTIONARY:
			return response_data
		else:
			push_error("API: Invalid JSON format received from server.")
			return {}
	else:
		push_error("API: Failed to create lobby. Server returned status: " + str(response_code))
		return {}
	
	
# ==================================================
# LEAVE_GAME ENDPOINT
# Requests the server player leave mid game
# ==================================================

func leave_game(game_key: String, player_id: int) -> bool:
	var url: String = "http://" + Env.api_base_url + "/leave_game?gameKey=" + game_key + "&playerId=" + str(player_id)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		""
	)
	
	if error != OK:
		push_error("API: Leave game request initiation failed for " + url)
		http_request.queue_free()
		return false
	
	var result = await http_request.request_completed
	
	if not is_inside_tree():
		http_request.queue_free()
		return false
		
	var response_code: int = result[1]
	http_request.queue_free()
	
	if response_code == 200 or response_code == 204:
		return true
		
	push_error("API: Failed to leave game. Server status: " + str(response_code))
	return false
