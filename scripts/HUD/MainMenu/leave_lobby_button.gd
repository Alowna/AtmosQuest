extends TextureButton

# Scene loaded after leaving the lobby successfully.
@export_file("*.tscn") var target_scene: String

# Optional sound played when the button is pressed.
@export var click_sound: AudioStreamPlayer

# Stores the original button scale.
var original_scale: Vector2

# Prevents the button from being pressed multiple times.
var used := false

# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	# Store the original button scale.
	original_scale = scale

	# Create a pixel-perfect click area.
	create_click_mask()

	# Center the pivot for scale animations.
	pivot_offset = size / 2

	# Connect button signal.
	pressed.connect(_on_pressed)


# ==================================================
# CLICK MASK
# Creates a clickable area based on the button texture.
# ==================================================

func create_click_mask() -> void:
	# Only generate the mask if a texture is assigned.
	if texture_normal:
		var bitmap := BitMap.new()

		# Use the texture transparency to define which pixels can be clicked.
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Apply the generated click mask.
		texture_click_mask = bitmap


# ==================================================
# BUTTON PRESS & NETWORK REQUEST
# Plays the animation and requests to leave the lobby.
# ==================================================

func _on_pressed() -> void:
	# Ignore additional presses while processing.
	if used:
		return

	used = true

	# Play the button click sound.
	if click_sound:
		AudioManager.play_ui_sound("button")

	# Create and play the button press animation immediately.
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.12)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.15)

	# ==================================================
	# LEAVE LOBBY REQUEST
	# Notify the server that this player is leaving via Api autoload.
	# ==================================================
	
	print("Requesting to leave lobby...")
	var success: bool = await Api.leave_lobby(CurrentLobby.lobbyKey, PlayerConfig.online_id)

	# Ensure the visual animation finishes before we delete the scene or reset.
	if tween.is_running():
		await tween.finished

	# ==================================================
	# SERVER RESPONSE HANDLING
	# ==================================================
	
	if success:
		print("Player successfully left the lobby!")

		# Reset local lobby data.
		PlayerConfig.online_id = 0
		CurrentLobby.clear()

		# Return to the target scene.
		if not target_scene.is_empty():
			get_tree().change_scene_to_file(target_scene)
		else:
			push_error("LeaveButton: Target scene is not assigned.")
	else:
		# Allow the player to try again if the network request failed.
		used = false
		push_error("LeaveButton: Failed to execute leave lobby sequence.")


# ==================================================
# APPEAR ANIMATION
# Makes the button pop into view.
# ==================================================

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
		Vector2.ONE * 1.5,
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Return to the original size.
	tween.tween_property(
		self,
		"scale",
		original_scale,
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
