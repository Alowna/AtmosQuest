extends TextureButton

# Audio player that will be toggled when the button is pressed.
# Assign your autoplay music player in the Inspector.
@export var background_music: AudioStreamPlayer


func _ready():
	# Wait one frame to ensure the control has its final size.
	await get_tree().process_frame

	# Create a pixel-perfect click area based on the button texture transparency.
	create_click_mask()

	# Set the pivot to the center of the texture so the animation scales correctly.
	if texture_normal:
		pivot_offset = texture_normal.get_size() / 2

	# Connect the button press signal.
	pressed.connect(_on_pressed)


func create_click_mask():
	# Only create the mask if a normal texture is assigned.
	if texture_normal:
		var bitmap := BitMap.new()

		# Generate a click mask using the texture's alpha channel.
		# Opaque pixels are clickable, transparent pixels are ignored.
		bitmap.create_from_image_alpha(texture_normal.get_image())

		# Apply the generated click mask.
		texture_click_mask = bitmap


func _on_pressed():
	# Create the button animation.
	var tween := create_tween()

	# Scale the button up slightly.
	tween.tween_property(
		self,
		"scale",
		Vector2(1.15, 1.15),
		0.1
	)

	# Return the button to its original size.
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.1
	)

	# Toggle the assigned background music.
	if background_music:
		if background_music.playing:
			background_music.stop()
		else:
			background_music.play()
