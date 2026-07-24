extends LineEdit

# Default text color.
var normal_color := Color(0.0, 0.7647, 0.4157)


func _ready() -> void:
	# Apply the default color.
	add_theme_color_override("font_placeholder_color", normal_color)
	placeholder_text = "Código"
		# Reset color when the player focuses the field again.
	focus_entered.connect(_on_focus_entered)

	# Reset color when the player types something.
	text_changed.connect(_on_text_changed)


# Called when the player clicks the input field.
func _on_focus_entered() -> void:
	add_theme_color_override("font_placeholder_color", normal_color)
	placeholder_text = "Código"


# Called whenever the text is modified.
func _on_text_changed(_new_text: String) -> void:
	add_theme_color_override("font_placeholder_color", normal_color)
	placeholder_text = "Código"
