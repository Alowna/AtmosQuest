extends Node2D
# Dictionary containing every available ship skin and its assets
var ship_skins: Dictionary = {
	"Classic":
	{
		"id": 0,
		"example": "res://assets/ships/ClassicShip/ClassicShipExample.png",
		"body": "res://assets/ships/ClassicShip/ClassicShipFinal.png",
		"propeller": "res://assets/ships/ClassicShip/ClassicShipPropeller.png",
		"coffer": "res://assets/ships/ClassicShip/ClassicShipCoffer.png",
		"right_wing": "res://assets/ships/ClassicShip/ClassicShipRightWing.png",
		"left_wing": "res://assets/ships/ClassicShip/ClassicShipLeftWing.png"
	},
	"Dark":
	{
		"id": 1,
		"example": "res://assets/ships/DarkShip/DarkShipExample.png",
		"body": "res://assets/ships/DarkShip/DarkShipFinal.png",
		"propeller": "res://assets/ships/DarkShip/DarkShipPropeller.png",
		"coffer": "res://assets/ships/DarkShip/DarkShipCoffer.png",
		"right_wing": "res://assets/ships/DarkShip/DarkShipRightWing.png",
		"left_wing": "res://assets/ships/DarkShip/DarkShipLeftWing.png"
	},
	"Banana":
	{
		"id": 2,
		"example": "res://assets/ships/BananaShip/BananaShipExample.png",
		"body": "res://assets/ships/BananaShip/BananaShipFinal.png",
		"propeller": "res://assets/ships/BananaShip/BananaShipPropeller.png",
		"coffer": "res://assets/ships/BananaShip/BananaShipCoffer.png",
		"right_wing": "res://assets/ships/BananaShip/BananaShipRightWing.png",
		"left_wing": "res://assets/ships/BananaShip/BananaShipLeftWing.png"
	},
	"LM":
	{
		"id": 3,
		"example": "res://assets/ships/LMShip/LMShipExample.png",
		"body": "res://assets/ships/LMShip/LMShipFinal.png",
		"propeller": "res://assets/ships/LMShip/LMShipPropeller.png",
		"coffer": "res://assets/ships/LMShip/LMShipCoffer.png",
		"right_wing": "res://assets/ships/LMShip/LMShipRightWing.png",
		"left_wing": "res://assets/ships/LMShip/LMShipLeftWing.png"
	}
}

# Dictionary containing every available pilot skin and its assets
var pilot_skins : Dictionary = {
	"orange":
	{
		"id": 0,
		"texture": preload("res://assets/ships/pilots/orange.png")
	},
	"mixed":
	{
		"id": 1,
		"texture": preload("res://assets/ships/pilots/mixed.png")
	},
	"black":
	{
		"id": 2,
		"texture": preload("res://assets/ships/pilots/black.png")
	},
	"whitegrey":
	{
		"id": 3,
		"texture": preload("res://assets/ships/pilots/whitegrey.png")
	},
	"banana":
	{
		"id": 4,
		"texture": preload("res://assets/ships/pilots/banana.png")
	}
}
