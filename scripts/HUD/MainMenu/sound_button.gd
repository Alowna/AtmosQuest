extends TextureButton


func _ready():
	await get_tree().process_frame

	create_click_mask()

	if texture_normal:
		pivot_offset = texture_normal.get_size() / 2

	pressed.connect(_on_pressed)


func create_click_mask():
	if texture_normal:
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(texture_normal.get_image())
		texture_click_mask = bitmap


func _on_pressed():
	# Click sound
	AudioManager.play_ui_sound("button")

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
		Vector2.ONE,
		0.1
	)

	# turn music on and off
	AudioManager.toggle_music()
