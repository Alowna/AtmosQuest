extends Node2D
class_name LobbyManager


# Array containing all available lobby ship slots
@export var lobby_ship_slots: Array[LobbyShip]


# Reference the HTTPRequest node
@onready var http_request: HTTPRequest = $HTTPRequest


# Used to compare the previous lobby state and detect players leaving/joining
var previous_players: Array = []


# Timer used for periodically requesting the lobby state
var lobby_timer: Timer



func _ready():

	# Connect HTTP response callback
	http_request.request_completed.connect(_on_request_completed)


	# Creates a timer to keep updating the lobby
	lobby_timer = Timer.new()
	lobby_timer.wait_time = 2.0
	lobby_timer.autostart = true

	lobby_timer.timeout.connect(request_lobby_state)

	add_child(lobby_timer)



func request_lobby_state():

	# Do nothing if there is no active lobby
	if CurrentLobby.lobbyKey == "":
		return


	var url = "http://" + Env.api_base_url \
		+ "/get_lobby/" \
		+ CurrentLobby.lobbyKey


	print("Requesting lobby state: ", url)


	var headers = [
		"Content-Type: application/json"
	]


	# Sends GET request to retrieve the current lobby players
	http_request.request(
		url,
		headers,
		HTTPClient.METHOD_GET
	)



func _on_request_completed(
	_result,
	response_code,
	_headers,
	body
):

	if response_code != 200:
		return


	var data = JSON.parse_string(
		body.get_string_from_utf8()
	)


	#print("Lobby response: ", data)


	CurrentLobby.players = data["players"]
	#print("Those are the players in currentLobby: ", CurrentLobby.players)

	update_lobby_ships(CurrentLobby.players)




	# Saves the current state for the next comparison
	previous_players = CurrentLobby.players.duplicate()



func update_lobby_ships(players):

	print("=== UPDATE LOBBY SHIPS ===")
	print("Players received:", players.size())
	print("Slots:", lobby_ship_slots.size())

	for ship in lobby_ship_slots:
		print(
			"Slot:",
			ship.name,
			" player_id:",
			ship.player_id
		)
		
	# Check for players that left the lobby
	for ship in lobby_ship_slots:

		if ship.player_id == -1:
			continue


		var player_exists := false


		for player in players:

			if int(player.id) == ship.player_id:

				player_exists = true
				break


		if not player_exists:

			ship.leave_animation()



	# Add new players
	for player in players:

		var player_id = int(player.id)

		var already_loaded := false


		# Check if this player already has a ship
		for ship in lobby_ship_slots:

			if ship.player_id == player_id:

				already_loaded = true
				break


		if already_loaded:
			continue



		# Find first empty slot
		for ship in lobby_ship_slots:

			if ship.player_id == -1:

				print("Assigning:", player.username, "to", ship.name)

				ship.assign_player(player)

				break
