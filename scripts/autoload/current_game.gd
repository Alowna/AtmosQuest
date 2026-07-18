extends Node

# Autoload: CurrentGame.
# Stores the active game state and synchronizes data from the server.


# Current game information.
var game_key: String = ""

# Players currently inside the game.
var players: Array = []

# Server events history.
var events: Array = []

# ID used for the next game event.
var next_event_id: int = 1


# Game status flags.
var is_finished: bool = false
var has_started: bool = false


# ==================================================
# RESET
# Clears the current game data.
# ==================================================

func clear():

	game_key = ""

	players.clear()

	events.clear()

	next_event_id = 1

	is_finished = false

	has_started = false


# ==================================================
# DATA UPDATE
# Updates the game state from an API response.
# ==================================================

func update_from_dict(data: Dictionary):

	if data.has("key"):

		game_key = data["key"]

		has_started = true


	if data.has("isFinished"):

		is_finished = data["isFinished"]


	if data.has("nextEventId"):

		next_event_id = data["nextEventId"]


	if data.has("players"):

		players = data["players"]


	if data.has("events"):

		events = data["events"]


# ==================================================
# PLAYER SEARCH
# Finds a player by their online ID.
# ==================================================

func get_player(player_id: int) -> Dictionary:

	for p in players:

		if p.has("id") and p["id"] == player_id:

			return p


	push_warning(
		"Player with ID "
		+ str(player_id)
		+ " not found in CurrentGame."
	)

	return {}


# ==================================================
# LOCAL PLAYER
# Returns the current player's data.
# ==================================================

func get_local_player() -> Dictionary:

	return get_player(PlayerConfig.online_id)


# ==================================================
# GAME STATUS
# Checks if a game is currently active.
# ==================================================

func is_active() -> bool:

	return not game_key.is_empty()
