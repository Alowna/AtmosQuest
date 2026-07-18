extends Ship
class_name PlayerShip

# Player ship controller.
# Handles movement, rotation, UI updates,
# rocket stage separation and skin loading.

# Stores the previous altitude to calculate speed.
var last_altitude_km = 0.0

# Current ship speed in kilometers per second.
var speed_kms = 0.0


# UI labels shown during gameplay.
@export var altitude_label = Label
@export var atmosphere_label = Label
@export var speed_label = Label


# Current altitude in kilometers.
var altitude_km = 0.0


# Rotation speed while the player is touching the screen.
@export var rotation_speed := 1.5


# True while the left side of the screen is held.
var turn_left := false

# True while the right side of the screen is held.
var turn_right := false


# ==================================================
# DETACHABLE ROCKET PARTS
# Assigned from the Inspector.
# ==================================================

@export var propeller: Node2D
@export var right_wing: Node2D
@export var left_wing: Node2D
@export var coffer: Node2D


# Prevent the same stage from being detached twice.
var propeller_detached := false
var right_wing_detached := false
var left_wing_detached := false
var coffer_detached := false
