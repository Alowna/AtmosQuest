extends Ship
class_name PlayerShip

# Player ship controller.
# Handles movement, rotation, UI updates,
# rocket stage separation and skin loading.

# Stores the previous altitude to calculate speed.
var last_altitude_km = 0.0

# UI labels shown during gameplay.
@export var altitude_label = Label
@export var atmosphere_label = Label
@export var lives_label = Label

# Rotation speed while the player is touching the screen.
@export var rotation_speed := 1.5

# Warning animation shown before entering a new atmospheric layer.
@onready var WarningAnimation: AnimatedSprite2D = $WarningAnimation

@onready var camera: Camera2D = $Camera2D


# True while the left side of the screen is held.
var turn_left := false

# True while the right side of the screen is held.
var turn_right := false

# Tracks whether the warning is currently visible.
var warning_showing := false


func _ready():
	super._ready()
	

	CollisionPolygon.disabled = false
	# Adds this ship to the player group.
	add_to_group("player")

	last_altitude_km = get_altitude()

	apply_skin()

	# Start with the warning hidden.
	WarningAnimation.visible = false
	camera.shake(3.5, 12.0)
	rotation_speed = 0.5
	await get_tree().create_timer(3.0).timeout
	
	
	rotation_speed = 1.5


func _input(event):
	# Checks if the input event is a screen touch.
	if event is InputEventScreenTouch:

		# Gets half of the screen width.
		var screen_half = get_viewport().get_visible_rect().size.x / 2

		if event.pressed:
			# Rotate left when touching the left half.
			turn_left = event.position.x < screen_half

			# Rotate right when touching the right half.
			turn_right = event.position.x >= screen_half

		else:
			# Stop rotating.
			turn_left = false
			turn_right = false


func _physics_process(delta):
	
	super._physics_process(delta)
	
	if PlayerConfig.controls_locked:
		return
	# Rotate the ship left.
	if turn_left:
		rotation -= rotation_speed * delta

	# Rotate the ship right.
	if turn_right:
		rotation += rotation_speed * delta

	# Clamp ship rotation.
	rotation = clamp(rotation, -PI / 8, PI / 8)

	# Move the ship in its forward direction.
	var direction = Vector2.UP.rotated(rotation)
	move_ship(direction)


func _process(delta):
	super._process(delta)
	
	if not PlayerConfig.isAlive:
		CollisionPolygon.disabled = true
		
	PlayerConfig.altitude = get_altitude()

	if -position.y >= 9800.0:
		if PlayerConfig.altitude>190000:
			PlayerConfig.altitude = 190000
			PlayerConfig.maxAltitude = 190000
			
		PlayerConfig.finished = true

	altitude_label.text = format_altitude(PlayerConfig.altitude)

	lives_label.text = str(PlayerConfig.lives) + " Vidas"

	last_altitude_km = PlayerConfig.altitude

	# Update the current atmospheric layer.
	if PlayerConfig.altitude < 12:
		atmosphere_label.text = "Troposfera"
		PlayerConfig.atmosLayer = 0

	elif PlayerConfig.altitude < 50:
		atmosphere_label.text = "Estratosfera"
		PlayerConfig.atmosLayer = 1

	elif PlayerConfig.altitude < 80:
		atmosphere_label.text = "Mesosfera"
		PlayerConfig.atmosLayer = 2

	elif PlayerConfig.altitude < 700:
		atmosphere_label.text = "Termosfera"
		PlayerConfig.atmosLayer = 3

	else:
		atmosphere_label.text = "Exosfera"
		PlayerConfig.atmosLayer = 4

	# Update the warning state after the atmosphere layer is known.
	Warning()


func get_altitude():
	var ship_y = -position.y

	if ship_y <= 515:
		return lerp(0.0, 12.0, ship_y / 515.0)
	elif ship_y <= 2140:
		return lerp(12.0, 50.0, (ship_y - 515.0) / (2140.0 - 515.0))
	elif ship_y <= 3217:
		return lerp(50.0, 80.0, (ship_y - 2140.0) / (3217.0 - 2140.0))
	elif ship_y <= 6996:
		return lerp(80.0, 700.0, (ship_y - 3217.0) / (6996.0 - 3217.0))
	else:
		return lerp(700.0, 190000.0, (ship_y - 6996.0) / (9800.0 - 6996.0))


func format_altitude(altitude):
	if altitude < 1000:
		return str(int(round(altitude))) + " km"

	elif altitude < 1000000:
		var megameters = altitude / 1000.0
		return str(int(round(megameters))) + " Mm"

	else:
		var gigameters = altitude / 1000000.0
		return str(int(round(gigameters))) + " Gm"


func apply_skin():

	$ShipFinal.texture = PlayerConfig.ship_skin["body"]

	$Pilot.texture = PlayerConfig.pilot_skin["skin"]

	$Propeller/ShipPropeller.texture = PlayerConfig.ship_skin["propeller"]

	$RightWing/ShipRightWing.texture = PlayerConfig.ship_skin["right_wing"]

	$LeftWing/ShipLeftWing.texture = PlayerConfig.ship_skin["left_wing"]

	$Coffer/ShipCoffer.texture = PlayerConfig.ship_skin["coffer"]


# Controls the warning animation.
# The warning appears shortly before entering the next atmospheric layer.
func Warning() -> void:
	
	WarningAnimation.global_rotation = 0
	var should_show := false

	match PlayerConfig.atmosLayer:
		# Troposphere -> warning after 7 km.
		0:
			should_show = PlayerConfig.altitude >= 7.0

		# Stratosphere -> warning after 44 km.
		1:
			should_show = PlayerConfig.altitude >= 44.0

		# Mesosphere -> warning after 74 km.
		2:
			should_show = PlayerConfig.altitude >= 74.0

		# Thermosphere -> warning after 650 km.
		3:
			should_show = PlayerConfig.altitude >= 650.0

		# No warning in the exosphere.
		4:
			should_show = false

	# Nothing changed.
	if should_show == warning_showing:
		return

	warning_showing = should_show

	if should_show:
		AudioManager.play_game_sound("Warning")
		WarningAnimation.visible = true
		WarningAnimation.play("Spawn")
		await WarningAnimation.animation_finished

		# Make sure another state change didn't happen while waiting.
		if warning_showing:
			WarningAnimation.play("Loop")

	else:
		WarningAnimation.play("Despawn")
		await WarningAnimation.animation_finished

		# Hide only if the warning wasn't shown again meanwhile.
		if !warning_showing:
			WarningAnimation.visible = false
