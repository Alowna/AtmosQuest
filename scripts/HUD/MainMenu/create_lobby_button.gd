extends TextureButton

# Scene loaded after creating the lobby successfully.
@export_file("*.tscn") var target_scene: String

# Prevents multiple create lobby requests from being sent.
var is_processing_request := false

# HTTP request used to create the lobby.
@onready var http_request: HTTPRequest = $HTTPRequest


func _ready() -> void:

	# Create a pixel-perfect click area.
	create_click_mask()

	# Center the pivot for scale animations.
	pivot_offset = size / 2.0

	# Connect button and HTTP request signals.
	pressed.connect(_on_pressed)
	http_request.request_completed.connect(_on_request_completed)


# ==================================================
# CLICK MASK
# Creates a clickable area based on the button texture.
# ==================================================

func create_click_mask() -> void:

	if texture_normal:

		var bitmap := BitMap.new()

		# Use the texture transparency to define
		# which pixels can be clicked.
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Apply the generated click mask.
		texture_click_mask = bitmap


# ==================================================
# BUTTON PRESS
# Sends a request to create a new lobby.
# ==================================================

func _on_pressed() -> void:

	# Ignore additional presses while processing.
	if is_processing_request:
		return

	is_processing_request = true

	# Play the button click sound.
	AudioManager.play_ui_sound("button")

	# Build the create lobby request.
	var url := "http://" + Env.api_base_url + "/create_lobby?ownerId=" + str(PlayerConfig.online_id)

	# Send the request to the server.
	http_request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		""
	)

	# Play the button press animation.
	var tween := create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2(0.85, 0.85),
		0.12
	)

	tween.tween_property(
		self,
		"scale",
		Vector2(1.0, 1.0),
		0.15
	)

	# Wait until the animation finishes.
	await tween.finished


# ==================================================
# SERVER RESPONSE
# Handle the result of the create lobby request.
# ==================================================

func _on_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	if response_code == 200:

		var response_data: Dictionary = JSON.parse_string(
			body.get_string_from_utf8()
		)

		if response_data:

			# Store the new lobby information.
			CurrentLobby.lobbyKey = response_data.get("lobbyKey", "")
			CurrentLobby.owner_id = int(response_data.get("ownerId", 0))

			# Cache the players currently in the lobby.
			if response_data.has("lobbyPlayers"):
				CurrentLobby.players = response_data["lobbyPlayers"]

				print("Players in lobby: ", CurrentLobby.players)

			# Enter the lobby scene.
			if not target_scene.is_empty():
				get_tree().change_scene_to_file(target_scene)

	else:

		# Allow the player to try again.
		is_processing_request = false

		push_error(
			"Failed to create lobby. Server returned status: "
			+ str(response_code)
		)
