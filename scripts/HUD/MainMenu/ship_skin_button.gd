extends TextureButton


# Reference to the ship preview image
@onready var ship_example: Sprite2D = $ShipExample

# Reference to the button animation player
@onready var button_animation: AnimationPlayer = $AnimationPlayer

# Prevents the button from being pressed multiple times
var used := false

# Ordered list of available ship skins
var skin_names := ["Classic", "Dark", "Banana", "LM"]

# Index of the currently selected skin
var current_skin_index := 0

# Stores the default playback speed of the AnimationPlayer
var default_animation_speed: float = 1.0

# Scale used during the preview pop animation
const POP_SCALE := Vector2(1.12, 1.12)

# Duration of the pop expansion
const POP_GROW_TIME := 0.08

# Duration of the pop return animation
const POP_SHRINK_TIME := 0.15


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
	AudioManager.play_ui_sound("button")

	# Temporarily speeds up the button idle animation
	button_animation.speed_scale = default_animation_speed * 2.0

	# Plays a pop animation on the ship preview
	play_preview_pop()

	# Keeps the animation accelerated for a short moment
	await get_tree().create_timer(0.2).timeout

	# Restores the original animation speed
	button_animation.speed_scale = default_animation_speed

	# Selects and applies the next skin
	select_next_skin()

	# Allows the button to be pressed again
	used = false


func play_preview_pop() -> void:
	# Resets the preview scale before starting the animation
	ship_example.scale = Vector2.ONE

	# Creates a tween for the pop animation
	var tween := create_tween()

	# Slightly enlarges the preview
	tween.tween_property(
		ship_example,
		"scale",
		POP_SCALE,
		POP_GROW_TIME
	)

	# Smoothly returns to the original size
	tween.tween_property(
		ship_example,
		"scale",
		Vector2.ONE,
		POP_SHRINK_TIME
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func update_skin_preview() -> void:
	# Retrieves the currently selected skin
	var skin: Dictionary = skins[skin_names[current_skin_index]]

	# Updates the preview image
	ship_example.texture = load(skin["example"])


func apply_skin_to_player_config() -> void:
	# Retrieves the currently selected skin
	var skin: Dictionary = skins[skin_names[current_skin_index]]

	# Applies every ship part to the player configuration
	PlayerConfig.ship_skin["body"] = load(skin["body"])
	PlayerConfig.ship_skin["propeller"] = load(skin["propeller"])
	PlayerConfig.ship_skin["left_wing"] = load(skin["left_wing"])
	PlayerConfig.ship_skin["right_wing"] = load(skin["right_wing"])
	PlayerConfig.ship_skin["coffer"] = load(skin["coffer"])


func select_next_skin() -> void:
	# Advances to the next skin, looping back to the beginning
	current_skin_index = (current_skin_index + 1) % skin_names.size()

	# Updates the preview image
	update_skin_preview()

	# Applies the selected skin
	apply_skin_to_player_config()


# Dictionary containing every available ship skin and its assets
var skins: Dictionary = {
	"Classic":
	{
		"example": "res://assets/ships/ClassicShip/ClassicShipExample.png",
		"body": "res://assets/ships/ClassicShip/ClassicShipFinal.png",
		"propeller": "res://assets/ships/ClassicShip/ClassicShipPropeller.png",
		"coffer": "res://assets/ships/ClassicShip/ClassicShipCoffer.png",
		"right_wing": "res://assets/ships/ClassicShip/ClassicShipRightWing.png",
		"left_wing": "res://assets/ships/ClassicShip/ClassicShipLeftWing.png"
	},
	"Dark":
	{
		"example": "res://assets/ships/DarkShip/DarkShipExample.png",
		"body": "res://assets/ships/DarkShip/DarkShipFinal.png",
		"propeller": "res://assets/ships/DarkShip/DarkShipPropeller.png",
		"coffer": "res://assets/ships/DarkShip/DarkShipCoffer.png",
		"right_wing": "res://assets/ships/DarkShip/DarkShipRightWing.png",
		"left_wing": "res://assets/ships/DarkShip/DarkShipLeftWing.png"
	},
	"Banana":
	{
		"example": "res://assets/ships/BananaShip/BananaShipExample.png",
		"body": "res://assets/ships/BananaShip/BananaShipFinal.png",
		"propeller": "res://assets/ships/BananaShip/BananaShipPropeller.png",
		"coffer": "res://assets/ships/BananaShip/BananaShipCoffer.png",
		"right_wing": "res://assets/ships/BananaShip/BananaShipRightWing.png",
		"left_wing": "res://assets/ships/BananaShip/BananaShipLeftWing.png"
	},
	"LM":
	{
		"example": "res://assets/ships/LMShip/LMShipExample.png",
		"body": "res://assets/ships/LMShip/LMShipFinal.png",
		"propeller": "res://assets/ships/LMShip/LMShipPropeller.png",
		"coffer": "res://assets/ships/LMShip/LMShipCoffer.png",
		"right_wing": "res://assets/ships/LMShip/LMShipRightWing.png",
		"left_wing": "res://assets/ships/LMShip/LMShipLeftWing.png"
	}
}
