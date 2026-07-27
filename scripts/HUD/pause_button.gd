extends TextureButton

@onready var AreYouSureBox = get_parent().get_node("../AreYouSureBox")

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	AreYouSureBox.start()
