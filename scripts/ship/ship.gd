extends CharacterBody2D
class_name Ship

# Base ship controller.
# Handles common ship properties and movement.
# This script does not know who controls the ship.
# It can be used by player-controlled ships, AI ships, or network ships.


@export var speed := 150.0
# Movement speed of the ship.


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
	
