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
