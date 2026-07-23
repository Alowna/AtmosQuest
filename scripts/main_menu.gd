extends Control

# Reference to the AnimatedSprite2D displaying connection status.
@onready var OnlineCheck: AnimatedSprite2D = $OnlineCheck
@onready var Username: LineEdit = $UsernameEditField/LineEdit


func _ready() -> void:
	_update_visual_status()


func _process(_delta: float) -> void:
	# Reads the global boolean maintained by PlayerConfig in the background
	_update_username()
	_update_visual_status()

func _update_username() -> void:
	PlayerConfig.username = Username.text

func _update_visual_status() -> void:
	if PlayerConfig.connected:
		if OnlineCheck.animation != "online":
			OnlineCheck.play("online")
	else:
		if OnlineCheck.animation != "offline":
			OnlineCheck.play("offline")
