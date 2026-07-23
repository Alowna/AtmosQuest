extends TextureButton

# Scene loaded after joining the lobby successfully.
@export_file("*.tscn") var target_scene: String

# Prevents multiple join requests from being sent simultaneously.
var is_processing_request := false

# Reference to the text input where the player types the lobby key.
@onready var lobby_input: LineEdit = $LobbyInput

# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	# Create a pixel-perfect click area.
	create_click_mask()

	# Center the pivot for scale animations.
	pivot_offset = size / 2.0

	# Connect button signal.
	pressed.connect(_on_pressed)


# ==================================================
# CLICK MASK
# Creates a clickable area based on the button texture.
# ==================================================

func create_click_mask() -> void:
	if texture_normal:
		var bitmap := BitMap.new()

		# Use the texture transparency to define which pixels can be clicked.
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Apply the generated click mask.
		texture_click_mask = bitmap


# ==================================================
# BUTTON PRESS & NETWORK REQUEST
# ==================================================

func _on_pressed() -> void:
	# Ignore additional presses while processing.
	if is_processing_request:
		return

	is_processing_request = true

	# Play the button click sound.
	AudioManager.play_ui_sound("button")

	# Play the button press animation immediately.
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.12)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

	# Read the lobby key entered by the player, stripping accidental spaces.
	var target_lobby_key: String = lobby_input.text.strip_edges()

	if target_lobby_key.is_empty():
		push_warning("JoinLobbyButton: Lobby key is empty.")
		is_processing_request = false
		return

	# ==================================================
	# SERVER REQUEST
	# Send the request to the server via Api autoload.
	# ==================================================
	
	print("Attempting to join lobby: ", target_lobby_key)
	var response_data: Dictionary = await Api.join_lobby(target_lobby_key, PlayerConfig.online_id)

	# Wait until the visual animation finishes before transitioning.
	if tween.is_running():
		await tween.finished

	# ==================================================
	# SERVER RESPONSE HANDLING
	# ==================================================

	if not response_data.is_empty():
		print("Successfully joined the lobby!")

		# Populate the CurrentLobby autoload cleanly using its built-in method.
		CurrentLobby.update_from_dict(response_data)

		# Enter the lobby scene.
		if not target_scene.is_empty():
			get_tree().change_scene_to_file(target_scene)
		else:
			push_error("JoinLobbyButton: Target scene is not assigned.")
	else:
		# Allow the player to try again.
		is_processing_request = false
		push_error("JoinLobbyButton: Failed to execute join sequence.")
