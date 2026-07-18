extends Node2D
class_name LobbyManager

# Available ship slots displayed in the lobby.
@export var lobby_ship_slots: Array[LobbyShip]

# Stores the previous lobby state.
# Used to avoid unnecessary updates.
var previous_players: Array = []


func _ready() -> void:

	# Polling is handled by the parent scene.
	# This script only updates the lobby visuals.
	pass


# ==================================================
# LOBBY REFRESH
# Updates the lobby ships using the latest player data.
# ==================================================

func update_lobby_ships(players: Array) -> void:

	# Remove ships whose players have left the lobby.
	for ship in lobby_ship_slots:

		if ship.player_id == -1:
			continue

		var player_still_exists := false

		for player in players:

			if int(player.get("id", -1)) == ship.player_id:

				player_still_exists = true
				break

		if not player_still_exists:
			ship.leave_animation()

	# Add new players and update changed skins.
	for player in players:

		var current_id := int(player.get("id", -1))
		var current_ship_skin := int(player.get("playerSkin", 0))

		var slot_already_occupied := false
		var skin_needs_update := false
		var target_ship_slot: LobbyShip = null

		# Check if this player is already assigned
		# to one of the lobby slots.
		for ship in lobby_ship_slots:

			if ship.player_id == current_id:

				slot_already_occupied = true
				target_ship_slot = ship

				# Check if the player's ship skin
				# changed while they were in the lobby.
				var active_skin = SkinManager.get_ship_skin_by_id(current_ship_skin)

				var expected_texture_path: String = active_skin.get(
					"example",
					active_skin.get("body", "")
				)

				if ship.ship_visual.texture == null \
				or ship.ship_visual.texture.resource_path != expected_texture_path:

					skin_needs_update = true

				break

		# Player is already assigned and nothing changed.
		if slot_already_occupied and not skin_needs_update:
			continue

		# Refresh the player's appearance.
		if slot_already_occupied and skin_needs_update:

			print(
				"Skin update detected for user: ",
				player.get("username", "Unknown"),
				" | New Skin ID: ",
				current_ship_skin
			)

			target_ship_slot.assign_player(player)

			continue

		# Assign a new player to the first available slot.
		for ship in lobby_ship_slots:

			if ship.player_id == -1:

				print(
					"Assigning raw entry: ",
					player.get("username", "Unknown"),
					" to slot node: ",
					ship.name
				)

				ship.assign_player(player)

				break

	# Store the current lobby state.
	previous_players = players.duplicate()
