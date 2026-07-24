extends TextureButton

@onready var line_edit = $"../LobbyInput"

func _ready():
	pressed.connect(_on_texture_button_pressed)

func _on_texture_button_pressed():
	line_edit.text = DisplayServer.clipboard_get()
	line_edit.caret_column = line_edit.text.length()
