extends Control

var entrance_over = 0

@onready var lobbyKeyButton = $LobbyKeyButton
@onready var backButton = $BackButton


func _ready():
	lobbyKeyButton.visible = false
	backButton.visible = false
	
	$Base.animation_finished.connect(_entrance_over)
	$Skies.animation_finished.connect(_entrance_over)


func _entrance_over():
	entrance_over += 1
	
	if entrance_over >= 2:
		lobbyKeyButton.appear()
		backButton.appear()
