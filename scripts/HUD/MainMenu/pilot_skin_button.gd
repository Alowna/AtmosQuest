extends TextureButton

# Optional audio player used for the button click sound
@export var click_sound: AudioStreamPlayer

# Reference to the ship preview image
@onready var pilot_example: Sprite2D = $PilotExample

# Reference to the button animation player
@onready var button_animation: AnimationPlayer = $AnimationPlayer

# Prevents the button from being pressed multiple times
var used := false

# Currently selected pilot skin index
var current_skin_index := 0

# Stores the default playback speed of the AnimationPlayer
var default_animation_speed: float = 1.0


# Ordered list of available pilot skins
var pilot_skins := [
	{
		"id": 0,
		"name": "orange",
		"texture": preload("res://assets/ships/pilots/orange.png")
	},
	{
		"id": 1,
		"name": "mixed",
		"texture": preload("res://assets/ships/pilots/mixed.png")
	},
	{
		"id": 2,
		"name": "black",
		"texture": preload("res://assets/ships/pilots/black.png")
	},
	{
		"id": 3,
		"name": "whitegrey",
		"texture": preload("res://assets/ships/pilots/whitegrey.png")
	},
	{
		"id": 4,
		"name": "banana",
		"texture": preload("res://assets/ships/pilots/banana.png")
	}
]


func _ready():
	# Creates a pixel-perfect clickable area based on the button texture
	create_click_mask()

	# Displays the initial skin preview
	update_skin_preview()

	# Applies the initial skin to the player configuration
	apply_skin_to_player_config()

	# Makes scaling animation happen from the center of the button
	pivot_offset = size / 2

	# Stores the original animation playback speed
	default_animation_speed = button_animation.speed_scale

	# Connects the pressed signal
	pressed.connect(_on_pressed)


func create_click_mask():
	# Creates a click mask only if a normal texture is assigned
	if texture_normal:
		var bitmap := BitMap.new()

		# Uses texture alpha so only visible pixels are clickable
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Applies generated click mask
		texture_click_mask = bitmap


func _on_pressed():
	# Ignores additional presses while busy
	if used:
		return

	used = true

	# Plays click sound
	if click_sound:
		click_sound.play()

	# Temporarily speeds up button animation
	button_animation.speed_scale = default_animation_speed * 2.0

	# Keeps animation accelerated briefly
	await get_tree().create_timer(0.2).timeout

	# Restores animation speed
	button_animation.speed_scale = default_animation_speed

	# Waits for click sound to finish
	if click_sound:
		await click_sound.finished

	# Selects and applies next skin
	select_next_skin()

	# Allows button to be pressed again
	used = false


func update_skin_preview() -> void:
	# Gets the selected pilot skin
	var selected_skin = pilot_skins[current_skin_index]

	# Updates preview sprite
	pilot_example.texture = selected_skin["texture"]


func apply_skin_to_player_config() -> void:
	# Gets the selected pilot skin
	var selected_skin = pilot_skins[current_skin_index]

	# Saves selected pilot skin globally
	PlayerConfig.pilot_skin["skin"] = selected_skin["texture"]
	PlayerConfig.pilot_skin["id"] = selected_skin["id"]


func select_next_skin() -> void:
	# Moves to next skin and loops back at the end
	current_skin_index = (current_skin_index + 1) % pilot_skins.size()

	# Updates preview
	update_skin_preview()

	# Saves selection globally
	apply_skin_to_player_config()
