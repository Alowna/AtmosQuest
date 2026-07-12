extends Ship

# Player ship controller.
# Handles player input, rotation, and mobile touch controls.
# This script only exists for the ship controlled by the local player.

var last_altitude_km = 0.0
var speed_kms = 0.0

@export var altitude_label = Label
@export var atmosphere_label = Label
@export var speed_label = Label
var altitude_km = 0.0

@export var rotation_speed := 1.5
# How fast the ship rotates when the player touches the screen.


var turn_left := false
# Stores if the player is currently holding the left side of the screen.


var turn_right := false
# Stores if the player is currently holding the right side of the screen.


# Detachable rocket parts
# These references are assigned from the Inspector.
@export var propeller: Node2D
@export var right_wing: Node2D
@export var left_wing: Node2D
@export var coffer: Node2D


# Prevents the same part from being detached multiple times.
var propeller_detached := false
var right_wing_detached := false
var left_wing_detached := false
var coffer_detached := false



func _ready():
	# Adds this ship to the player group.
	# Other systems can find the local player using this group.
	add_to_group("player")
	last_altitude_km = get_altitude()



func _input(event):
	# Checks if the input event is a screen touch.
	if event is InputEventScreenTouch:

		# Gets half of the screen width.
		# Used to determine if the player touched the left or right side.
		var screen_half = get_viewport().get_visible_rect().size.x / 2


		# When the player touches the screen.
		if event.pressed:

			# Touching the left side rotates the ship left.
			turn_left = event.position.x < screen_half


			# Touching the right side rotates the ship right.
			turn_right = event.position.x >= screen_half


		# When the player releases the screen.
		else:

			# Stop rotating.
			turn_left = false
			turn_right = false



func _physics_process(delta):
	# Rotate the ship to the left.
	if turn_left:
		rotation -= rotation_speed * delta


	# Rotate the ship to the right.
	if turn_right:
		rotation += rotation_speed * delta


	# Limit the ship rotation between -30 and +30 degrees.
	# Prevents the ship from turning too far.
	rotation = clamp(rotation, -PI / 8, PI / 8)


	# Creates a movement direction based on the ship's rotation.
	# Vector2.UP means the ship's front is pointing upward.
	var direction = Vector2.UP.rotated(rotation)


	# Sends the movement direction to the base ship controller.
	move_ship(direction)

func _process(delta):
	altitude_km = get_altitude()
	
	# Checks if any rocket parts should be detached
	# based on the current atmospheric layer.
	check_detach_events()

	altitude_label.text = format_altitude(altitude_km)


	# Calcula distância percorrida desde o último frame
	var altitude_difference = altitude_km - last_altitude_km


	# Converte km/frame para km/h
	speed_kms = altitude_difference / delta


	# Evita valores negativos quando a nave gira ou desce
	speed_kms = max(speed_kms, 0)


	speed_label.text = format_speed(speed_kms)


	last_altitude_km = altitude_km


	if altitude_km < 12:
		atmosphere_label.text = "Troposfera"
	elif altitude_km < 50:
		atmosphere_label.text = "Estratosfera"
	elif altitude_km < 80:
		atmosphere_label.text = "Mesosfera"
	elif altitude_km < 700:
		atmosphere_label.text = "Termosfera"
	else:
		atmosphere_label.text = "Exosfera"
	
func get_speed_from_altitude(altitude):
	if altitude < 12:
		# Inside the troposphere: keep the initial speed
		return 60
	
	elif altitude < 50:
		# Gradual acceleration through the stratosphere
		return lerp(60.0, 130.0, (altitude - 12.0) / (50.0 - 12.0))
	
	else:
		# Continuous acceleration afterwards
		return lerp(130.0, 200.0, clamp((altitude - 50.0) / (700.0 - 50.0), 0.0, 1.0))
	
	
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
		return lerp(700.0, 190000.0, (ship_y - 6996.0) / (9989.0 - 6996.0))

func format_speed(speed_kms):
	speed_kms = snapped(speed_kms, 0.1)

	if speed_kms < 1:
		return str(int(speed_kms * 1000)) + " m/s"
	
	elif speed_kms < 1000:
		return str(speed_kms).trim_suffix(".0") + " km/s"
	
	elif speed_kms < 299792:
		var mm_s = snapped(speed_kms / 1000.0, 0.1)
		return str(mm_s).trim_suffix(".0") + " Mm/s"
	
	else:
		var light_speed = speed_kms / 299792.458
		return str(snapped(light_speed * 100.0, 0.1)).trim_suffix(".0") + "%c"

func format_altitude(altitude):
	if altitude < 1000:
		return str(int(round(altitude))) + " km"
	
	elif altitude < 1000000:
		var megameters = altitude / 1000.0
		return str(snapped(megameters, 0.1)).trim_suffix(".0") + " Mm"
	
	else:
		var gigameters = altitude / 1000000.0
		return str(snapped(gigameters, 0.1)).trim_suffix(".0") + " Gm"
		
func check_detach_events():

	# ==========================================
	# STRATOSPHERE ENTRY (12 km)
	# Detach the main propeller/booster section.
	# ==========================================
	if altitude_km >= 12 and not propeller_detached:

		propeller_detached = true

		if propeller:
			propeller.detach()



	# ==========================================
	# MESOSPHERE ENTRY (50 km)
	# Detach the left and right wings.
	# ==========================================
	if altitude_km >= 50 and not right_wing_detached:

		right_wing_detached = true

		if right_wing:
			right_wing.detach()
	if altitude_km >= 55 and not left_wing_detached:

		left_wing_detached = true

		if left_wing:
			left_wing.detach()



	# ==========================================
	# EXOSPHERE ENTRY (700 km)
	# Detach the final compartment/payload cover.
	# ==========================================
	if altitude_km >= 700 and not coffer_detached:

		coffer_detached = true

		if coffer:
			coffer.detach()
