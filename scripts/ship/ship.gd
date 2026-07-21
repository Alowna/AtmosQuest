extends CharacterBody2D
class_name Ship

# Base ship controller.
# Handles common ship properties and movement.
# This script does not know who controls the ship.
# It can be used by player-controlled ships, AI ships, or network ships.

# Prevent the same stage from being detached twice.
var propeller_detached := false
var right_wing_detached := false
var left_wing_detached := false
var coffer_detached := false

# ==================================================
# DETACHABLE ROCKET PARTS
# ==================================================

@onready var propeller = $Propeller
@onready var right_wing = $RightWing
@onready var left_wing = $LeftWing
@onready var coffer = $Coffer

var currentAtmosLayer := -1

# Kaboom
@onready var ShipDeath = $ShipDeath

@onready var ShipFinal = $ShipFinal
@onready var Pilot = $Pilot
@onready var CollisionPolygon = $CollisionPolygon2D
@onready var Fire = $Fire
var kaboom_done = false

var speed
# Movement speed of the ship.

func _ready():
	PlayerConfig.speed = 80
	ShipDeath.visible = false 
	speed = PlayerConfig.speed

func move_ship(direction: Vector2):
	# Creates the movement velocity based on the given direction.
	# Any ship can use this function by providing a movement direction.
	velocity = direction * speed


	# Applies the velocity and moves the CharacterBody2D.
	move_and_slide()

#Physics for testing
func _physics_process(_delta):
	var direction = Vector2.UP
	move_ship(direction)
	
func _process(_delta):
	speed = PlayerConfig.speed
	# Checks if any rocket parts should be detached
	# based on the current atmospheric layer.
	check_detach_events()
	
	if PlayerConfig.atmosLayer != currentAtmosLayer:
		currentAtmosLayer = PlayerConfig.atmosLayer
		Fire.enableFire(currentAtmosLayer)
	
	if not kaboom_done and not PlayerConfig.isAlive:
		kaboom()
	
func check_detach_events():

	# ==========================================
	# STRATOSPHERE ENTRY (12 km)
	# Detach the main propeller/booster section.
	# ==========================================
	if PlayerConfig.altitude >= 12 and not propeller_detached:

		propeller_detached = true

		if propeller:
			propeller.detach(false)



	# ==========================================
	# MESOSPHERE ENTRY (50 km)
	# Detach the left and right wings.
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
	# Detach the final compartment/payload cover.
	# ==========================================
	if PlayerConfig.altitude >= 700 and not coffer_detached:

		coffer_detached = true

		if coffer:
			coffer.detach(false)

func kaboom():
	PlayerConfig.speed = 0
	#make kaboom only once
	kaboom_done = true
	#detach true means kaboom
	if not propeller_detached:
		propeller.detach(true)
	if not right_wing_detached:
		right_wing.detach(true)
	if not left_wing_detached:
		left_wing.detach(true)
	if not coffer_detached:
		coffer.detach(true)
	Pilot.visible = false
	ShipFinal.visible = false
	Fire.visible = false
	
	CollisionPolygon.disabled
	ShipDeath.visible = true

	AudioManager.play_game_sound("explosion")
	AudioManager.toggle_music()
	ShipDeath.play("Kaboom")
	await ShipDeath.animation_finished
	ShipDeath.visible = false
	PlayerConfig.finished = true
	PlayerConfig.maxAltitude = PlayerConfig.altitude
