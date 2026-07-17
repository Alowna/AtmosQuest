extends TextureButton

# Optional audio player used for the button click sound
@export var click_sound: AudioStreamPlayer

# Reference to the ship preview image
@onready var pilot_example: Sprite2D = $PilotExample

# Reference to the button animation player
@onready var button_animation: AnimationPlayer = $AnimationPlayer

# Prevents the button from being pressed multiple times
var used := false

# Ordered list of available ship skins
var skin_names := ["orange", "mixed", "black", "whitegrey", "banana"]

# Index of the currently selected skin
var current_skin_index := 0

# Stores the default playback speed of the AnimationPlayer
var default_animation_speed: float = 1.0



func _ready():
	# Creates a pixel-perfect clickable area based on the button texture
	create_click_mask()

	# Displays the initial skin preview
	update_skin_preview()

	# Applies the initial skin to the player configuration
	apply_skin_to_player_config()

	# Makes any scaling animation happen from the center of the button
	pivot_offset = size / 2

	# Stores the original animation playback speed
	default_animation_speed = button_animation.speed_scale

	# Connects the pressed signal to the custom handler
	pressed.connect(_on_pressed)


func create_click_mask():
	# Creates a click mask only if a normal texture is assigned
	if texture_normal:
		var bitmap := BitMap.new()

		# Uses the texture alpha channel so only visible pixels are clickable
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Applies the generated click mask
		texture_click_mask = bitmap


func _on_pressed():
	# Ignores additional presses while the button is busy
	if used:
		return

	used = true

	# Plays the click sound if one is assigned
	if click_sound:
		click_sound.play()

	# Temporarily speeds up the button idle animation
	button_animation.speed_scale = default_animation_speed * 2.0

	# Keeps the animation accelerated for a short moment
	await get_tree().create_timer(0.2).timeout

	# Restores the original animation speed
	button_animation.speed_scale = default_animation_speed

	# Waits until the click sound finishes playing
	if click_sound:
		await click_sound.finished

	# Selects and applies the next skin
	select_next_skin()

	# Allows the button to be pressed again
	used = false


func update_skin_preview() -> void:
	# Gets the currently selected skin texture
	var skin_texture: Texture2D = skins[skin_names[current_skin_index]]

	# Updates the preview image
	pilot_example.texture = skin_texture


func apply_skin_to_player_config() -> void:
	# Gets the currently selected skin texture
	var skin_texture: Texture2D = skins[skin_names[current_skin_index]]

	# Saves the selected pilot skin globally
	PlayerConfig.pilot_skin = skin_texture


func select_next_skin() -> void:
	# Advances to the next skin, looping back to the beginning
	current_skin_index = (current_skin_index + 1) % skin_names.size()

	# Updates the preview image
	update_skin_preview()

	# Applies the selected skin
	apply_skin_to_player_config()


# Dictionary containing every available player skin asset
var skins: Dictionary[String, Texture2D] = {
	"orange": preload("res://assets/ships/pilots/orange.png"),
	"mixed": preload("res://assets/ships/pilots/mixed.png"),
	"black": preload("res://assets/ships/pilots/black.png"),
	"whitegrey": preload("res://assets/ships/pilots/whitegrey.png"),
	"banana": preload("res://assets/ships/pilots/banana.png")
}
