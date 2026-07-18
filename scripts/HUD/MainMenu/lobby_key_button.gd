extends TextureButton

# Final position where the button should appear.
@export var target_position: Vector2

# Offset used so the button starts below its target position.
@export var start_offset := Vector2(0, 300)


# Stores the original button scale.
var original_scale: Vector2

# Prevents the button from being pressed multiple times.
var used := false


func _ready() -> void:

	# Hide the button until the appear animation is played.
	visible = false

	original_scale = scale

	# Display the current lobby key.
	$Label.text = CurrentLobby.lobbyKey

	# Center the pivot so scale animations look natural.
	pivot_offset = size / 2

	pressed.connect(_on_pressed)


# ==================================================
# APPEAR ANIMATION
# Slides the button into view with a small pop effect.
# ==================================================

func appear():

	visible = true

	# Start below the target position.
	position = target_position + start_offset

	scale = Vector2(0.8, 0.8)

	var tween = create_tween()

	tween.set_parallel(true)

	# Move the button upward.
	tween.tween_property(
		self,
		"position",
		target_position,
		0.8
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Small pop animation after reaching the target.
	tween.chain().tween_property(
		self,
		"scale",
		Vector2(1.15, 1.15),
		0.12
	).set_trans(Tween.TRANS_BACK)

	tween.tween_property(
		self,
		"scale",
		original_scale,
		0.1
	)


# ==================================================
# BUTTON PRESS
# Plays a click animation and copies the lobby key.
# ==================================================

func _on_pressed() -> void:

	# Ignore presses while the animation is playing.
	if used:
		return

	used = true

	# Play the button click sound.
	AudioManager.play_ui_sound("button")

	# Click animation.
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
		original_scale,
		0.15
	)

	await tween.finished

	# Copy the lobby key to the clipboard.
	DisplayServer.clipboard_set($Label.text)

	used = false
