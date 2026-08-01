extends TextureButton

# The scene that will be loaded after this button animation and network request finish.

@onready var DefineCharacterScreen = $"../DefineCharacterScreenMP"



# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	# Creates a pixel-perfect click area based on the button texture transparency.
	create_click_mask()

	# Makes the scale animation happen from the center of the button.
	pivot_offset = size / 2.0

	# Connects the button press event.
	pressed.connect(_on_pressed)


# ==================================================
# CLICK MASK
# ==================================================

func create_click_mask() -> void:
	# Only create the mask if the button has a normal texture assigned.
	if texture_normal:
		var bitmap := BitMap.new()

		# Uses the texture alpha values:
		# - Visible pixels become clickable
		# - Transparent pixels become ignored
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Applies the generated pixel-perfect click mask to the button.
		texture_click_mask = bitmap


# ==================================================
# BUTTON PRESS & NETWORK REQUEST
# ==================================================

func _on_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

	if tween.is_running():
		await tween.finished
	# Ignore additional clicks if the button was already activated.
	var online: bool = await Api.check_connection()
	if online:
		DefineCharacterScreen.visible=true

	# Play click sound.
	AudioManager.play_ui_sound("UIClick3")
	
	
