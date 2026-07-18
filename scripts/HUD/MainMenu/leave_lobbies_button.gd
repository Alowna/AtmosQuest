extends TextureButton

# Scene that will be loaded after the button finishes its animation.
@export_file("*.tscn") var target_scene: String

# Optional audio player reference for the button click sound.
@export var click_sound: AudioStreamPlayer


# Stores the default button size.
# Used to restore the scale after animations.
var original_scale: Vector2


# Prevents multiple requests while the button is processing.
var used := false


# HTTPRequest node used to communicate with the server.
@onready var http_request: HTTPRequest = $HTTPRequest


func _ready():

	# Save the original button scale.
	original_scale = scale

	# Creates a pixel-perfect click area based on the texture transparency.
	create_click_mask()

	# Makes scale animations happen from the center of the button.
	pivot_offset = size / 2

	# Connect button events.
	pressed.connect(_on_pressed)
	http_request.request_completed.connect(_on_request_completed)



func create_click_mask():

	# Only create a click mask if the button has a normal texture.
	if texture_normal:

		var bitmap := BitMap.new()

		# Uses the texture alpha values:
		# Visible pixels become clickable.
		# Transparent pixels are ignored.
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Apply the generated pixel-perfect click area.
		texture_click_mask = bitmap



func _on_pressed():

	# Ignore clicks while a request is already being processed.
	if used:
		return

	used = true


	# Play button sound.
	if click_sound:

		AudioManager.play_ui_sound("button")


	# ==================================================
	# SERVER REQUEST
	# Removes this player from the online server list.
	# ==================================================

	# The server receives the player ID through the query parameter.
	var url = "http://" + Env.api_base_url + "/leave_server?id=" + str(PlayerConfig.online_id)

	print("Attempting to remove player from server: ", url)


	# Request headers.
	# The request body is empty because the ID is already in the URL.
	var headers = ["Content-Type: application/json"]


	# Sends the request to the server.
	http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		""
	)



	# ==================================================
	# BUTTON ANIMATION
	# Creates a small press effect.
	# ==================================================

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



func _on_request_completed(_result, response_code, _headers, _body):

	# Accept successful deletion responses.
	# 200 = OK
	# 204 = No Content
	if response_code == 200 or response_code == 204:

		print("Player successfully deleted from server!")


		# Clear local player information.
		# Removes stored identity and lobby data.
		PlayerConfig.clear()
		CurrentLobby.clear()


		# Return to the target scene.
		if target_scene:

			get_tree().change_scene_to_file(target_scene)


	else:

		# Allow trying again if the request failed.
		used = false

		push_error(
			"Failed to delete player. Status: "
			+ str(response_code)
		)



func appear():

	# Makes the button visible.
	visible = true


	# Starts very small for the pop-in effect.
	scale = Vector2.ONE * 0.1


	# Creates the appearance animation.
	var tween = create_tween()


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
