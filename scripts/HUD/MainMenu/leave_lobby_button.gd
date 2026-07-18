extends TextureButton

# Scene loaded after leaving the lobby successfully.
@export_file("*.tscn") var target_scene: String

# Optional sound played when the button is pressed.
@export var click_sound: AudioStreamPlayer


# Stores the original button scale.
var original_scale: Vector2


# Prevents the button from being pressed multiple times.
var used := false

# HTTP request used to notify the server.
@onready var http_request: HTTPRequest = $HTTPRequest


func _ready():

	# Store the original button scale.
	original_scale = scale

	# Create a pixel-perfect click area.
	create_click_mask()

	# Center the pivot for scale animations.
	pivot_offset = size / 2

	# Connect button and HTTP request signals.
	pressed.connect(_on_pressed)
	http_request.request_completed.connect(_on_request_completed)


# ==================================================
# CLICK MASK
# Creates a clickable area based on the button texture.
# ==================================================

func create_click_mask():

	# Only generate the mask if a texture is assigned.
	if texture_normal:

		var bitmap := BitMap.new()

		# Use the texture transparency to define
		# which pixels can be clicked.
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Apply the generated click mask.
		texture_click_mask = bitmap


# ==================================================
# BUTTON PRESS
# Plays the animation and requests to leave the lobby.
# ==================================================

func _on_pressed():

	# Ignore additional presses while processing.
	if used:
		return

	used = true

	# Play the button click sound.
	if click_sound:
		AudioManager.play_ui_sound("button")

	# ==================================================
	# LEAVE LOBBY REQUEST
	# Notify the server that this player is leaving.
	# ==================================================

	var url = "http://" + Env.api_base_url \
		+ "/leave_lobby?lobbyKey=" + CurrentLobby.lobbyKey \
		+ "&playerId=" + str(PlayerConfig.online_id)

	print("Leaving lobby: ", url)

	var headers = ["Content-Type: application/json"]

	# Send the request to the server.
	http_request.request(url, headers, HTTPClient.METHOD_POST)

	# Create the button press animation.
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
		Vector2(1, 1),
		0.15
	)

	# Wait until the animation finishes.
	await tween.finished


# ==================================================
# SERVER RESPONSE
# Handle the result of the leave lobby request.
# ==================================================

func _on_request_completed(_result, response_code, _headers, _body):

	if response_code == 200:

		print("Player successfully left the lobby!")

		# Reset local lobby data.
		PlayerConfig.online_id = 0
		CurrentLobby.clear()

		# Return to the target scene.
		if target_scene:
			get_tree().change_scene_to_file(target_scene)

	else:

		# Allow the player to try again.
		used = false

		push_error("Failed to leave lobby. Status: " + str(response_code))


# ==================================================
# APPEAR ANIMATION
# Makes the button pop into view.
# ==================================================

func appear():

	# Show the button.
	visible = true

	# Start almost invisible.
	scale = Vector2.ONE * 0.1

	# Create the appearance animation.
	var tween = create_tween()

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
