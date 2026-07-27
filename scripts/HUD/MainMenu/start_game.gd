extends TextureButton

# Prevents the button from being spammed while the network request is processing.
var used := false

# ==================================================
# INITIALIZATION
# ==================================================
# Stores the original button scale.
var original_scale: Vector2

func _ready() -> void:
	# Creates a pixel-perfect click area based on the button texture transparency.
	create_click_mask()
	original_scale = scale

	# Connect the button press event.
	pressed.connect(_on_pressed)


# ==================================================
# CLICK MASK
# ==================================================

func create_click_mask() -> void:
	# Only create the mask if the button has a normal texture assigned.
	if texture_normal:
		var bitmap := BitMap.new()

		# Uses the texture alpha values:
		# - Visible pixels become clickable
		# - Transparent pixels become ignored
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Applies the generated pixel-perfect click mask to the button.
		texture_click_mask = bitmap


# ==================================================
# BUTTON PRESS & NETWORK REQUEST
# ==================================================

func _on_pressed() -> void:
	# Ignore additional clicks if the button was already activated.
	if used: 
		return

	# Only the lobby owner is authorized to start the match.
	if CurrentLobby.owner_id != PlayerConfig.online_id:
		push_warning("StartGameButton: Only the lobby owner can start the game!")
		return

	used = true

	# Play the UI click sound.
	AudioManager.play_ui_sound("UIClick2")
	
	# Create a quick press animation immediately: shrinks slightly, then bounces back.
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.65, 0.65), 0.12)
	tween.tween_property(
		self,
		"scale",
		original_scale,
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
	# ==================================================
	# API CALL
	# ==================================================
	
	print("Connecting to start game route for lobby: ", CurrentLobby.lobbyKey)
	var success: bool = await Api.create_game(CurrentLobby.lobbyKey)
	
	# Wait until the visual animation finishes before reacting.
	if tween.is_running():
		await tween.finished

	# ==================================================
	# SERVER RESPONSE HANDLING
	# ==================================================
	
	if success:
		print("Server received the start command! Waiting for Lobby synchronization...")
		
		# CRITICAL LOGIC: We DO NOT transition the scene here anymore.
		# We just disable the button visually. The lobby script's polling loop
		# will detect the game creation and pull everyone (including the owner)
		# into the gameplay scene at the exact same time.
		disabled = true 
	else:
		# Allow the user to try again if an error occurred (e.g., 400 or 500).
		used = false
		push_error("StartGameButton: Failed to tell the server to start the game.")




func appear() -> void:
	# Show the button.
	visible = true

	# Start almost invisible.
	scale = Vector2.ONE * 0.1

	# Create the appearance animation.
	var tween := create_tween()

	# Grow past the final size for a pop effect.
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE * 1.2,
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Return to the original size.
	tween.tween_property(
		self,
		"scale",
		original_scale,
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
