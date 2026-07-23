extends Node

# Autoload: PlayerConfig.
# Stores player customization and account data between scenes.
# Also provides the player's information when communicating with the server.

# Player display name.
# Used as the player's identity in the lobby and server data.
var username = "Jogador(e)"


# Online ID assigned by the server.
# Used to identify this player in API requests.
var online_id: int = -1

###########
# IN-GAME #
###########

# Check if player is alive
var isAlive: bool = true

# Check if player finished game
var finished: bool = false

# Check players lives
var lives: int = 1#6 #1 of testing

#Check player altitude
var altitude: int = 0

var speed: int = 80
# Check maximum reached player altitude
var maxAltitude: int = 0

# Check players atmosphere layer
var atmosLayer = 0
# 0 = Troposphere
# 1 = Stratosphere
# 2 = Mesosphere
# 3 = Thermosphere
# 4 = Exosphere

# Check player points
var points: int = 0

# Check how much collisions player had
var collisions: int = 0

# Check player's correct and wrong answers
var correctAnswers: int = 0
var wrongAnswers: int = 0

var correctAnswersIds: Array[int] = []
var wrongAnswersIds: Array[int] = []

var answeredQuestions: Array[int] = []
# If dead, check player's killer
var collisionDeathObject : = "Unknown"


# Selected ship skin.
# This data is kept when changing scenes.
# The skin ID is sent to the server when needed.
var ship_skin = {
	"id": 0,
	"body": preload("res://assets/ships/ClassicShip/ClassicShipFinal.png"),
	"propeller": preload("res://assets/ships/ClassicShip/ClassicShipPropeller.png"),
	"left_wing": preload("res://assets/ships/ClassicShip/ClassicShipLeftWing.png"),
	"right_wing": preload("res://assets/ships/ClassicShip/ClassicShipRightWing.png"),
	"coffer": preload("res://assets/ships/ClassicShip/ClassicShipCoffer.png")
}

# ==================================================
# SHIP SKIN
# Returns the selected ship skin ID.
# ==================================================

func get_rocket_skin_id() -> int:

	return ship_skin.get("id", 0)
	

# Selected pilot skin.
# This data is used for visual customization
# and sent to the server when updating player information.
var pilot_skin = {
	"skin": preload("res://assets/ships/pilots/orange.png"),
	"id": 0
}
# ==================================================
# PILOT SKIN
# Returns the selected pilot skin ID.
# ==================================================

func get_pilot_skin_id() -> int:

	return pilot_skin.get("id", 0)

# Clear player info, setting everything to default
func clear() -> void:
	username = "Jogador(e)"
	online_id = -1
	isAlive = true
	finished = false
	lives = 6
	altitude = 0
	atmosLayer = 0
	maxAltitude = 0
	points = 0
	collisions = 0
	correctAnswers = 0
	wrongAnswers = 0
	collisionDeathObject= "Unknown"
	
var all_questions: Array = []

func _ready() -> void:
	load_questions_from_json("res://scripts/data/questions.json")

func load_questions_from_json(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var parsed_data = JSON.parse_string(json_string)
		
		if typeof(parsed_data) == TYPE_ARRAY:
			all_questions = parsed_data
		else:
			print("Error: JSON format is not an Array.")
		file.close()
	else:
		print("Error: Could not open the questions file.")

func correctAnswer() -> void:
	correctAnswers += 1
	points += 100

func wrongAnswer() -> void:
	wrongAnswers += 1
	lives -= 1
	if lives < 1:
		isAlive = false
	
# ==================================================
# GLOBAL NETWORK MONITOR (HEARTBEAT)
# ==================================================

var connected: bool = false
var is_checking_health: bool = false

var health_timer: float = 0.0
var health_interval: float = 3.0 # Check server status every 3 seconds

# Absolute path to your Main Menu scene. Update this string to match your project structure!
const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"


func _process(delta: float) -> void:
	# Global polling loop to continuously verify connection state.
	if not is_checking_health:
		health_timer += delta
		if health_timer >= health_interval:
			health_timer = 0.0
			_check_global_connection()


func _check_global_connection() -> void:
	is_checking_health = true
	
	# Ping the backend via Api Autoload
	var currently_online: bool = await Api.check_connection()
	
	is_checking_health = false
	
	# SCENARIO 1: Server was online and suddenly crashed/disconnected
	if not currently_online and connected:
		connected = false
		_handle_server_crash()
		
	# SCENARIO 2: Connection was established or recovered
	elif currently_online and not connected:
		connected = true
		print("PlayerConfig: Connection established successfully!")


# Executes globally whenever the server crashes or connection is lost
func _handle_server_crash() -> void:
	push_warning("PlayerConfig: Server connection lost! Forcing disconnect.")
	
	# 1. Clear session and game data from all Autoloads
	clear()
	CurrentLobby.clear()
	# CurrentGame.clear() # Add if your project implements a CurrentGame autoload
	
	# 2. Check if the active scene is already the Main Menu.
	# Prevents infinite scene reload loops while idling in the Main Menu.
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name != "MainMenu":
		print("PlayerConfig: Ejecting player to Main Menu.")
		get_tree().change_scene_to_file(MAIN_MENU_PATH)


# ==================================================
# SYSTEM NOTIFICATIONS (APP EXIT HANDLING)
# ==================================================

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_handle_application_quit()


func _handle_application_quit() -> void:
	# Prevent Godot from terminating immediately before sending API requests
	get_tree().auto_accept_quit = false
	
	# Fast-path for offline / singleplayer mode
	if online_id == 0 or not connected:
		get_tree().quit()
		return
		
	# Safety net kill switch: Force close after 1.5s if network stalls
	get_tree().create_timer(1.5).timeout.connect(
		func(): get_tree().quit()
	)
	
	# Graceful network cleanup order
	if CurrentGame.is_active():
		await Api.leave_game(CurrentGame.game_key, online_id)
		await Api.leave_server(online_id)
	elif not CurrentLobby.lobbyKey.is_empty():
		await Api.leave_lobby(CurrentLobby.lobbyKey, online_id)
		await Api.leave_server(online_id)
	else:
		await Api.leave_server(online_id)
		
	get_tree().quit()
