extends Node

# Stores the selected ship skin.
# This data survives when changing scenes.

var ship_skin = {
	"id": 0,
	"body": preload("res://assets/ships/ClassicShip/ClassicShipFinal.png"),
	"propeller": preload("res://assets/ships/ClassicShip/ClassicShipPropeller.png"),
	"left_wing": preload("res://assets/ships/ClassicShip/ClassicShipLeftWing.png"),
	"right_wing": preload("res://assets/ships/ClassicShip/ClassicShipRightWing.png"),
	"coffer": preload("res://assets/ships/ClassicShip/ClassicShipCoffer.png")
}

var pilot_skin = {
	"skin": preload("res://assets/ships/pilots/orange.png"),
	"id": 0
} 

var username = "Tester"

var online_id: int = 0
