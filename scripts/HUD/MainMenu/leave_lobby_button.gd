extends TextureButton

# The scene that will be loaded after this button animation finishes
@export_file("*.tscn") var target_scene: String

# Optional audio player used for the button click sound
@export var click_sound: AudioStreamPlayer


var original_scale: Vector2


# Prevents the button from being pressed multiple times while transitioning
var used := false

# Reference the HTTPRequest node
@onready var http_request: HTTPRequest = $HTTPRequest

func _ready():
	# Store the original scale
	original_scale = scale

	# Creates a pixel-perfect click area based on the button texture transparency
	create_click_mask()

	# Makes the scale animation happen from the center of the button
	pivot_offset = size / 2

	# Connects the button press event to our custom function
	pressed.connect(_on_pressed)
	http_request.request_completed.connect(_on_request_completed)

func create_click_mask():
	# Only create the mask if the button has a normal texture assigned
	if texture_normal:
		var bitmap := BitMap.new()

		# Uses the texture alpha values:
		# - Visible pixels become clickable
		# - Transparent pixels become ignored
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Applies the generated pixel-perfect click mask to the button
		texture_click_mask = bitmap


func _on_pressed():
	# Ignore additional clicks if the button was already activated
	if used:
		return

	used = true

	# Play the assigned click sound, if one exists
	if click_sound:
		AudioManager.play_ui_sound("button")
	
	# --- API CALL START ---

	var url = "http://" + Env.api_base_url \
		+ "/leave_lobby?lobbyKey=" + CurrentLobby.lobbyKey \
		+ "&playerId=" + str(PlayerConfig.online_id)

	print("Leaving lobby: ", url)

	var headers = ["Content-Type: application/json"]

	# Initiate the HTTP POST request to the server
	http_request.request(url, headers, HTTPClient.METHOD_POST)

# --- API CALL END ---
	
	# Creates the press animation:
	# The button shrinks slightly and then returns to its original size
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

	# Wait until the button animation finishes
	await tween.finished



func _on_request_completed(_result, response_code, _headers, _body):
	if response_code == 200:
		
		print("Player successfully left the lobby!")
		
		PlayerConfig.online_id = 0
		CurrentLobby.clear()

		if target_scene:
			get_tree().change_scene_to_file(target_scene)

	else:
		used = false
		push_error("Failed to leave lobby. Status: " + str(response_code))
		

func appear():
	# Make the button visible
	visible = true

	# Start almost invisible
	scale = Vector2.ONE * 0.1

	# Create the appearance animation
	var tween = create_tween()

	# Grow past the final size to create a "pop" effect
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE * 1.5,
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Return smoothly to the original size
	tween.tween_property(
		self,
		"scale",
		original_scale,
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
