extends TextureButton

# Stores the original button scale.
var original_scale: Vector2

func _ready():
	await get_tree().process_frame
	original_scale = scale

	create_click_mask()

	pressed.connect(_on_pressed)


func create_click_mask():
	if texture_normal:
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(texture_normal.get_image())
		texture_click_mask = bitmap


func _on_pressed():
	# Click sound
	AudioManager.play_ui_sound("UIClick1")

	# Animation
	var tween := create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2(1.15, 1.15),
		0.1
	)

	tween.tween_property(
		self,
		"scale",
		original_scale,
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

	# turn music on and off
	AudioManager.toggle_music()



func appear() -> void:
	# Show the button.
	visible = true

	# Start almost invisible.
	scale = Vector2.ONE * 0.1

	# Create the appearance animation.
	var tween := create_tween()

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
