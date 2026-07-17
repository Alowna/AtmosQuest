extends TextureButton


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
var pilot_skins: Array = []


func _ready():
	# Creates a pixel-perfect clickable area based on the button texture
	create_click_mask()
	pilot_skins = SkinManager.pilot_skins.keys()
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

	AudioManager.play_ui_sound("button")

	# Temporarily speeds up button animation
	button_animation.speed_scale = default_animation_speed * 2.0

	# Keeps animation accelerated briefly
	await get_tree().create_timer(0.2).timeout

	# Restores animation speed
	button_animation.speed_scale = default_animation_speed

	# Selects and applies next skin
	select_next_skin()

	# Allows button to be pressed again
	used = false


func update_skin_preview() -> void:
	var skin_name = pilot_skins[current_skin_index]

	var selected_skin: Dictionary = SkinManager.pilot_skins[skin_name]

	pilot_example.texture = selected_skin["texture"]


func apply_skin_to_player_config() -> void:
	var skin_name = pilot_skins[current_skin_index]

	var selected_skin: Dictionary = SkinManager.pilot_skins[skin_name]

	PlayerConfig.pilot_skin["skin"] = selected_skin["texture"]
	PlayerConfig.pilot_skin["id"] = selected_skin["id"]


func select_next_skin() -> void:
	# Moves to next skin and loops back at the end
	current_skin_index = (current_skin_index + 1) % pilot_skins.size()

	# Updates preview
	update_skin_preview()

	# Saves selection globally
	apply_skin_to_player_config()
