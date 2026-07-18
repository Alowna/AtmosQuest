extends Node2D
class_name LobbyShip

# UI and visual references.
@onready var username_label = $Username
@onready var ship_visual = $ShipVisual
@onready var pilot_visual = $PilotVisual


# ID of the player currently assigned to this slot.
# A value of -1 means the slot is empty.
var player_id: int = -1

# Original position used by the entrance,
# idle and leave animations.
var spawn_position: Vector2

# Tween used for the floating idle animation.
var idle_tween: Tween


func _ready():

	# Store the original position.
	spawn_position = position

	# Hide the slot until a player is assigned.
	visible = false


# ==================================================
# PLAYER ASSIGNMENT
# Loads the player's information and visuals.
# ==================================================

func assign_player(player: Dictionary):

	# Store the player's ID and username.
	player_id = int(player.get("id", -1))
	username_label.text = str(player.get("username", "Unknown"))

	# Get the selected ship and pilot skin IDs.
	var ship_skin_id = int(player.get("shipSkin", 0))
	var pilot_skin_id = int(player.get("pilotSkin", 0))

	# Retrieve the skin data.
	var ship_skin = SkinManager.get_ship_skin_by_id(ship_skin_id)
	var pilot_skin = SkinManager.get_pilot_skin_by_id(pilot_skin_id)

	print(
		"LobbyShip: Applying for ",
		username_label.text,
		" | SkinID: ",
		ship_skin_id,
		" | Dict: ",
		ship_skin
	)

	# Apply the ship texture.
	if ship_skin.has("example"):
		ship_visual.texture = load(ship_skin["example"])

	elif ship_skin.has("body"):
		ship_visual.texture = load(ship_skin["body"])

	else:
		push_warning(
			"LobbyShip: No valid texture found for skin ID: ",
			ship_skin_id
		)

	# Apply the pilot texture.
	if pilot_skin and pilot_skin.has("texture"):
		pilot_visual.texture = pilot_skin["texture"]

	else:
		push_warning(
			"LobbyShip: No texture found for pilot ID: ",
			pilot_skin_id
		)

	# Show the slot and play the entrance animation.
	visible = true

	enter_animation()


# ==================================================
# ENTRANCE ANIMATION
# Moves the ship into its lobby position.
# ==================================================

func enter_animation():

	# Stop any previous idle animation.
	if idle_tween:
		idle_tween.kill()

	# Start below the final position.
	position = spawn_position + Vector2(0, 300)

	var tween = create_tween()

	tween.tween_property(
		self,
		"position",
		spawn_position,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.finished.connect(idle_animation)


# ==================================================
# IDLE ANIMATION
# Makes the ship float up and down continuously.
# ==================================================

func idle_animation():

	if idle_tween:
		idle_tween.kill()

	idle_tween = create_tween().set_loops()

	idle_tween.tween_property(
		self,
		"position:y",
		spawn_position.y + 3,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	idle_tween.tween_property(
		self,
		"position:y",
		spawn_position.y - 3,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ==================================================
# LEAVE ANIMATION
# Moves the ship out of the lobby.
# ==================================================

func leave_animation():

	# Stop the idle animation.
	if idle_tween:
		idle_tween.kill()

	var tween = create_tween()

	tween.tween_property(
		self,
		"position:y",
		spawn_position.y - 500,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.finished.connect(clear_slot)


# ==================================================
# SLOT RESET
# Clears the slot after the player leaves.
# ==================================================

func clear_slot():

	player_id = -1

	username_label.text = ""

	ship_visual.texture = null
	pilot_visual.texture = null

	position = spawn_position

	visible = false
