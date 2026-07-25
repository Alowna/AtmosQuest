extends Control

# Reference to the AnimatedSprite2D displaying connection status.
@onready var OnlineCheck: AnimatedSprite2D = $OnlineCheck
@onready var Username: LineEdit = $UsernameEditField/LineEdit

var firstHealthCheck: bool = true
var health_check_running: bool = false


func _ready() -> void:
	get_tree().paused = false
	
	_update_username()
	_update_visual_status()
	
	_check_server_once()
	
	print("Menu ready")


func _process(_delta: float) -> void:
	_update_username()
	_update_visual_status()


func _update_username() -> void:
	PlayerConfig.username = Username.text


func _check_server_once() -> void:
	if health_check_running or not firstHealthCheck:
		return
	
	health_check_running = true
	firstHealthCheck = false
	
	PlayerConfig.connected = false
	OnlineCheck.play("check")
	
	var online: bool = await Api.check_connection()
	
	PlayerConfig.connected = online
	
	health_check_running = false
	
	_update_visual_status()


func _update_visual_status() -> void:
	if health_check_running:
		if OnlineCheck.animation != "check":
			OnlineCheck.play("check")
		return
	
	if PlayerConfig.connected:
		if OnlineCheck.animation != "online":
			OnlineCheck.play("online")
	else:
		if OnlineCheck.animation != "offline":
			OnlineCheck.play("offline")
