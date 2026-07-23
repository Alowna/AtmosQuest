extends TextureButton

# Scene that will be loaded after the button finishes its animation and network request.
@export_file("*.tscn") var target_scene: String


# Stores the default button size. Used to restore the scale after animations.
var original_scale: Vector2

# Prevents multiple requests while the button is processing.
var used := false

# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	# Save the original button scale.
	original_scale = scale

	# Creates a pixel-perfect click area based on the texture transparency.
	create_click_mask()

	# Makes scale animations happen from the center of the button.
	pivot_offset = size / 2

	# Connect button events.
	pressed.connect(_on_pressed)


# ==================================================
# CLICK MASK
# ==================================================

func create_click_mask() -> void:
	# Only create a click mask if the button has a normal texture.
	if texture_normal:
		var bitmap := BitMap.new()

		# Uses the texture alpha values:
		# Visible pixels become clickable.
		# Transparent pixels are ignored.
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Apply the generated pixel-perfect click area.
		texture_click_mask = bitmap


# ==================================================
# BUTTON PRESS & NETWORK REQUEST
# ==================================================

func _on_pressed() -> void:
	# Ignore clicks while a request is already being processed.
	if used:
		return

	used = true

	#Play sound
	AudioManager.play_ui_sound("button")

	# ==================================================
	# BUTTON ANIMATION
	# Creates a small press effect immediately.
	# ==================================================
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

	# ==================================================
	# SERVER REQUEST
	# Removes this player from the online server list via Api autoload.
	# ==================================================
	print("Attempting to remove player from server...")
	var success: bool = await Api.leave_server(PlayerConfig.online_id)

	# Wait until the visual animation finishes before destroying the scene.
	if tween.is_running():
		await tween.finished

	# ==================================================
	# SERVER RESPONSE HANDLING
	# ==================================================
	if success:
		print("Player successfully deleted from server!")

		# Clear local player information.
		# Removes stored identity and lobby data.
		PlayerConfig.clear()
		CurrentLobby.clear()

		# Return to the target scene.
		if not target_scene.is_empty():
			get_tree().change_scene_to_file(target_scene)
		else:
			push_error("LeaveServerButton: Target scene is not assigned.")
	else:
		# Allow trying again if the request failed.
		used = false
		push_error("LeaveServerButton: Failed to execute leave server sequence.")


# ==================================================
# APPEAR ANIMATION
# ==================================================

func appear() -> void:
	# Makes the button visible.
	visible = true

	# Starts very small for the pop-in effect.
	scale = Vector2.ONE * 0.1

	# Creates the appearance animation.
	var tween := create_tween()

	# Grow beyond the final size to create a bounce effect.
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE * 1.5,
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Return to the original button size.
	tween.tween_property(
		self,
		"scale",
		original_scale,
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
