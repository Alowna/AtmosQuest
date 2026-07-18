extends TextureButton

# Prevents the button from being spammed while the network request is processing
var used := false

# Reference to the HTTPRequest node (Must be a child of this button in the scene tree)
@onready var http_request: HTTPRequest = $HTTPRequest

func _ready():
	# Creates a pixel-perfect click area based on the button texture transparency
	create_click_mask()

	# Connect the button press event and the HTTP response to our custom functions
	pressed.connect(_on_pressed)
	http_request.request_completed.connect(_on_request_completed)


func create_click_mask():
	# Only create the mask if the button has a normal texture assigned
	if texture_normal:
		var bitmap := BitMap.new()

		# Uses the texture alpha values:
		# - Visible pixels become clickable
		# - Transparent pixels become ignored
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Applies the generated pixel-perfect click mask to the button
		texture_click_mask = bitmap


func _on_pressed():
	# Ignore additional clicks if the button was already activated
	if used: return

	# Only the lobby owner is authorized to start the match
	if CurrentLobby.owner_id != PlayerConfig.online_id:
		push_warning("Only the lobby owner can start the game!")
		return

	used = true

	# Play the UI click sound
	AudioManager.play_ui_sound("button")
	
	# --- API CALL START ---
	# The FastAPI backend expects the lobbyKey as a query parameter
	var url = "http://" + Env.api_base_url + "/create_game?lobbyKey=" + CurrentLobby.lobbyKey
	print("Connecting to start game route: ", url)
	
	var headers = ["Content-Type: application/json"]

	# Initiate the HTTP POST request to tell the server to create the game
	# Empty body because the required data is in the URL query string
	http_request.request(url, headers, HTTPClient.METHOD_POST, "")
	# --- API CALL END ---
	
	# Create a quick press animation: shrinks slightly, then bounces back
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.12)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.15)
	
	await tween.finished


func _on_request_completed(_result, response_code, _headers, body):
	# Check if the server successfully created the game
	if response_code == 200:
		print("Server received the start command! Waiting for Lobby synchronization...")
		
		# CRITICAL CHANGE: We DO NOT transition the scene here anymore.
		# We just disable the button visually. The lobby script's polling loop
		# will detect the game creation and pull everyone (including the owner)
		# into the gameplay scene at the exact same time.
		disabled = true 
	else:
		# Allow the user to try again if an error occurred (e.g., 400 or 500)
		used = false
		push_error("Failed to start game. Status: " + str(response_code))
		
		var error_response = JSON.parse_string(body.get_string_from_utf8())
		if error_response and error_response.has("detail"):
			print("Error detail: ", error_response["detail"])
