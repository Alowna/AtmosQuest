extends Node2D
class_name LobbyShip


# UI and visual references
@onready var username_label = $Username
@onready var ship_visual = $ShipVisual
@onready var pilot_visual = $PilotVisual


# Player data
var player_id: int = -1


# Original position where the ship should stay
var spawn_position: Vector2


# Tween reference for the floating idle animation
var idle_tween: Tween



func _ready():

	# Save the original position from the scene
	spawn_position = position

	# Hide the ship until a player is assigned
	visible = false





func assign_player(player):

	# Store player id
	player_id = int(player.id)


	# Update username
	username_label.text = player.username


	# Load player ship skin
	var ship_skin = SkinManager.get_ship_skin_by_id(
		player.rocketSkin
	)


	# Load player pilot skin
	var pilot_skin = SkinManager.get_pilot_skin_by_id(
		player.pilotSkin
	)


	# Apply visuals
	ship_visual.texture = load(ship_skin["example"])
	pilot_visual.texture = pilot_skin["texture"]


	# Show ship
	visible = true


	# Play entrance animation
	enter_animation()





func enter_animation():

	# Stop previous idle animation if it exists
	if idle_tween:
		idle_tween.kill()


	# Start below the screen
	position = spawn_position + Vector2(0, 300)


	var tween = create_tween()


	# Move smoothly into the lobby position
	tween.tween_property(
		self,
		"position",
		spawn_position,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


	# After entering, start floating animation
	tween.finished.connect(idle_animation)





func idle_animation():

	# Prevent multiple idle animations
	if idle_tween:
		idle_tween.kill()


	idle_tween = create_tween()


	# Repeat forever
	idle_tween.set_loops()


	# Move slightly down
	idle_tween.tween_property(
		self,
		"position:y",
		spawn_position.y + 3,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


	# Move slightly up
	idle_tween.tween_property(
		self,
		"position:y",
		spawn_position.y - 3,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)





func leave_animation():

	# Stop floating animation
	if idle_tween:
		idle_tween.kill()


	var tween = create_tween()


	# Move the ship outside the screen
	tween.tween_property(
		self,
		"position:y",
		spawn_position.y - 500,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


	# Clear player data after leaving animation finishes
	tween.finished.connect(clear_slot)





func clear_slot():

	# Reset player data
	player_id = -1


	# Clear UI
	username_label.text = ""


	# Remove visuals
	ship_visual.texture = null
	pilot_visual.texture = null


	# Reset position
	position = spawn_position


	# Hide ship
	visible = false
