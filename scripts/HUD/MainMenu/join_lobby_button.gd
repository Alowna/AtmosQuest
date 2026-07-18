extends TextureButton

# Scene loaded after joining the lobby successfully.
@export_file("*.tscn") var target_scene: String

# Prevents multiple join requests from being sent.
var is_processing_request := false

# HTTP request used to join the lobby.
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
# Sends a request to join the selected lobby.
# ==================================================

func _on_pressed() -> void:

	# Ignore additional presses while processing.
	if is_processing_request:
		return

	is_processing_request = true

	# Play the button click sound.
	AudioManager.play_ui_sound("button")

	# Read the lobby key entered by the player.
	var target_lobby_key: String = $LobbyInput.text

	# Build the join lobby request.
	var url := "http://" + Env.api_base_url + "/join_lobby" + \
		"?lobbyKey=" + target_lobby_key + \
		"&playerId=" + str(PlayerConfig.online_id)

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
# Handle the result of the join lobby request.
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

			# Store the joined lobby key.
			CurrentLobby.lobbyKey = response_data.get("lobbyKey", "")

			# Store the lobby owner's ID.
			if response_data.has("ownerId"):
				CurrentLobby.owner_id = int(response_data["ownerId"])

			# Cache the current lobby players.
			if response_data.has("players"):
				CurrentLobby.players = response_data["players"]

			# Enter the lobby scene.
			if not target_scene.is_empty():
				get_tree().change_scene_to_file(target_scene)

	else:

		# Allow the player to try again.
		is_processing_request = false

		push_error(
			"Error joining lobby. Server returned status: "
			+ str(response_code)
		)
