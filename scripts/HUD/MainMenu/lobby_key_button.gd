extends TextureButton

@export var target_position: Vector2
@export var start_offset := Vector2(0, 300) # Starts 300 pixels below the target

var original_scale: Vector2
var used := false

func _ready() -> void:
	visible = false
	original_scale = scale

	$Label.text = CurrentLobby.lobbyKey

	pivot_offset = size / 2
	pressed.connect(_on_pressed)


func appear():
	visible = true

	# Start below the screen
	position = target_position + start_offset
	scale = Vector2(0.8, 0.8)

	var tween = create_tween()
	tween.set_parallel(true)

	# Move upward to the target position
	tween.tween_property(
		self,
		"position",
		target_position,
		0.8
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Small pop animation after reaching the position
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


func _on_pressed() -> void:
	if used:
		return

	used = true

	# Play click sound
	AudioManager.play_ui_sound("button")

	# Click animation
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

	# Copy lobby key to clipboard
	DisplayServer.clipboard_set($Label.text)

	used = false
