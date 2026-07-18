extends Node2D

# Autoload: SkinManager.
# Stores all available ship and pilot skins.
# Provides skin data to players, rivals and lobby ships.


# ==================================================
# SHIP SKIN SEARCH
# Returns a ship skin using its ID.
# ==================================================

func get_ship_skin_by_id(id: int) -> Dictionary:

	for skin_name in ship_skins:

		var skin = ship_skins[skin_name]

		if skin["id"] == id:

			return skin

	# Return the default skin if no match is found.
	return ship_skins["Classic"]



# ==================================================
# PILOT SKIN SEARCH
# Returns a pilot skin using its ID.
# ==================================================

func get_pilot_skin_by_id(id: int) -> Dictionary:

	for skin_name in pilot_skins:

		var skin = pilot_skins[skin_name]

		if skin["id"] == id:

			return skin

	# Return the default skin if no match is found.
	return pilot_skins["orange"]



# ==================================================
# SHIP SKINS
# Contains every available ship and its textures.
# ==================================================

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



# ==================================================
# PILOT SKINS
# Contains every available pilot texture.
# ==================================================

var pilot_skins: Dictionary = {

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
