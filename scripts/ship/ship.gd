extends CharacterBody2D
class_name Ship

# Base ship controller.
# Handles common ship properties and movement.
# This script does not know who controls the ship.
# It can be used by player-controlled ships, AI ships, or network ships.

# ==================================================
# DETACHABLE ROCKET PARTS STATE
# ==================================================

# Prevent the same stage from being detached twice.
var propeller_detached := false
var right_wing_detached := false
var left_wing_detached := false
var coffer_detached := false


# ==================================================
# DETACHABLE ROCKET PARTS REFERENCES
# ==================================================

@onready var propeller = $Propeller
@onready var right_wing = $RightWing
@onready var left_wing = $LeftWing
@onready var coffer = $Coffer


# Stores the last atmospheric layer used for fire effects.
var currentAtmosLayer := -1


# ==================================================
# SHIP EFFECTS REFERENCES
# ==================================================

@onready var ShipDeath = $ShipDeath
@onready var ShipFinal = $ShipFinal
@onready var Pilot = $Pilot
@onready var CollisionPolygon = $CollisionPolygon2D
@onready var Fire = $Fire


var kaboom_done := false


# ==================================================
# MOVEMENT
# ==================================================

# Current movement speed of the ship.
var speed: float = 5.0

func _ready():

	ShipDeath.visible = false

	# Initial slow launch speed.
	PlayerConfig.speed = 5
	speed = 5

	CollisionPolygon.scale = Vector2(1, 1.26)

	# Handles launch sound and fuel sound.
	await start_launch_sequence()



# ==================================================
# LAUNCH AUDIO SEQUENCE
# ==================================================

func start_launch_sequence():

	# Play the initial rocket launch sound.
	var rocketLaunchSound = AudioManager.play_game_sound("rocketLaunch")
	AudioManager.play_game_sound("fuelBurning")
	await rocketLaunchSound.finished

	# Fuel burning is a loop sound.
	# It will keep playing while the rocket flies.
	#AudioManager.play_game_sound("fuelBurning")



# ==================================================
# SPEED CONTROL
# ==================================================

func update_ship_speed():

	# Minimum and maximum possible speeds.
	var min_speed := 5.0
	var max_speed := 120.0


	# Altitude range used for acceleration.
	var start_altitude := 0.0
	var max_altitude := 700.0


	# Convert altitude into a value between 0 and 1.
	var progress = clamp(
		(PlayerConfig.altitude - start_altitude) /
		(max_altitude - start_altitude),
		0.0,
		1.0
	)


	# Makes acceleration smoother.
	# Lower values = slower beginning acceleration.
	progress = pow(progress, 0.2)


	# Calculate current speed.
	speed = lerp(min_speed, max_speed, progress)


	# Store the value globally if other systems need it.
	PlayerConfig.speed = speed



# ==================================================
# MOVEMENT
# ==================================================

func move_ship(direction: Vector2):

	# Creates the movement velocity based on direction.
	velocity = direction * speed


	# Applies movement to CharacterBody2D.
	move_and_slide()



# Physics movement.
func _physics_process(_delta):

	# Update speed according to current altitude.
	update_ship_speed()


	# Temporary automatic upward movement.
	# Any controller can replace this later.
	var direction = Vector2.UP

	move_ship(direction)



# ==================================================
# GENERAL UPDATE
# ==================================================

func _process(_delta):

	# Check if rocket parts should detach.
	check_detach_events()


	# Update fire effect when entering another atmosphere layer.
	if PlayerConfig.atmosLayer != currentAtmosLayer:

		currentAtmosLayer = PlayerConfig.atmosLayer

		Fire.enableFire(currentAtmosLayer)


	# Trigger explosion if the ship is destroyed.
	if not kaboom_done and not PlayerConfig.isAlive:

		kaboom()



# ==================================================
# ROCKET STAGE DETACH SYSTEM
# ==================================================

func check_detach_events():


	# ==========================================
	# STRATOSPHERE ENTRY (12 km)
	# Detach main propeller/booster section.
	# ==========================================

	if PlayerConfig.altitude >= 12 and not propeller_detached:

		propeller_detached = true

		if propeller:

			propeller.detach(false)



	# ==========================================
	# MESOSPHERE ENTRY (50-55 km)
	# Detach rocket wings.
	# ==========================================

	if PlayerConfig.altitude >= 50 and not right_wing_detached:

		right_wing_detached = true

		if right_wing:

			right_wing.detach(false)



	if PlayerConfig.altitude >= 55 and not left_wing_detached:

		left_wing_detached = true

		if left_wing:

			left_wing.detach(false)



	# ==========================================
	# EXOSPHERE ENTRY (700 km)
	# Detach final compartment/payload cover.
	# ==========================================

	if PlayerConfig.altitude >= 700 and not coffer_detached:

		CollisionPolygon.scale = Vector2(1, 1)

		coffer_detached = true

		if coffer:

			coffer.detach(false)



# ==================================================
# SHIP DESTRUCTION
# ==================================================

func kaboom():

	# Stop movement.
	PlayerConfig.speed = 0
	speed = 0

	
	# Prevent multiple explosions.
	kaboom_done = true


	# Detach all remaining parts with explosion effect.
	if not propeller_detached and propeller:

		propeller.detach(true)


	if not right_wing_detached and right_wing:

		right_wing.detach(true)


	if not left_wing_detached and left_wing:

		left_wing.detach(true)


	if not coffer_detached and coffer:

		coffer.detach(true)



	# Hide normal ship components.
	Pilot.visible = false
	ShipFinal.visible = false
	Fire.visible = false


	# Disable collision after destruction.
	CollisionPolygon.disabled = true


	# Show explosion animation.
	ShipDeath.visible = true


	AudioManager.toggle_music()

	ShipDeath.play("Kaboom")

	AudioManager.play_game_sound("explosion")


	await ShipDeath.animation_finished


	hide_after_animation()


	PlayerConfig.finished = true

	PlayerConfig.maxAltitude = PlayerConfig.altitude



func hide_after_animation() -> void:

	ShipDeath.visible = false
