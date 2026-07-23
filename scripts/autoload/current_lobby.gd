extends Node

# Autoload: CurrentLobby.
# Stores the current lobby information and player list.

# Current lobby key.
var lobbyKey: String = ""

# ID of the player who created the lobby.
var owner_id: int = 0

# Players currently inside the lobby.
var players: Array = []


# ==================================================
# RESET
# Clears the current lobby data.
# ==================================================

func clear():
	lobbyKey = ""
	owner_id = 0
	players.clear()


# ==================================================
# DATA UPDATE
# Updates the lobby state from an API response.
# ==================================================

func update_from_dict(data: Dictionary):

	# Accept both possible API key formats.
	if data.has("lobbyKey"):
		lobbyKey = data["lobbyKey"]
	elif data.has("key"):
		lobbyKey = data["key"]

	# Update the lobby owner.
	if data.has("ownerId"):
		owner_id = data["ownerId"]

	# Update the players currently in the lobby.
	if data.has("players"):
		players = data["players"]
