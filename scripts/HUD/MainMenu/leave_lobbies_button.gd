extends TextureButton

# The scene that will be loaded after this button animation finishes
@export_file("*.tscn") var target_scene: String

# Optional audio player used for the button click sound
@export var click_sound: AudioStreamPlayer


# Prevents the button from being pressed multiple times while transitioning
var used := false

# Reference the HTTPRequest node
@onready var http_request: HTTPRequest = $HTTPRequest

func _ready():
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
	
	var url = "http://" + Env.api_base_url + "/leave_server?id=" + str(PlayerConfig.online_id)
	print("Disconnecting from: ", url)
	
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
	# Check if the server responded with a successful status code
	if response_code == 200:
		print("Player successfully left the server!")
		
		# Change scene ONLY if the request was successful
		if target_scene:
			get_tree().change_scene_to_file(target_scene)
			
	else:
		# If an error occurs, print to console and allow the user to try again
		used = false
		push_error("Failed to exit player. Status: " + str(response_code))
