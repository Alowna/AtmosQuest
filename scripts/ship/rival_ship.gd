extends PlayerShip

# ID of the player represented by this rival ship.
@export var remote_player_id: int

var remoteCurrentAtmosLayer = -1

# Maps each detachable part node
# to its corresponding ship skin key.
var parts_map: Dictionary = {
	"Propeller": "propeller",
	"Coffer": "coffer",
	"RightWing": "right_wing",
	"LeftWing": "left_wing"
}


func _ready():
	super._ready()
	# Clear inherited node references.
	propeller = null
	right_wing = null
	left_wing = null
	coffer = null

	# Disable UI references inherited from the local player.
	altitude_label = null
	lives_label = null
	atmosphere_label = null

	# Reassign the detachable parts.
	if has_node("Propeller"):
		propeller = get_node("Propeller")

	if has_node("RightWing"):
		right_wing = get_node("RightWing")

	if has_node("LeftWing"):
		left_wing = get_node("LeftWing")

	if has_node("Coffer"):
		coffer = get_node("Coffer")

	# Disable local-only components.
	if has_node("Camera2D"):
		get_node("Camera2D").enabled = false

	if has_node("CollisionPolygon2D"):
		get_node("CollisionPolygon2D").disabled = true

	# Apply this rival's selected skins.
	_apply_rival_skins()


# ==================================================
# LOCAL OVERRIDES
# Disable local player controls for rival ships.
# ==================================================

func _input(_event):
	pass


func _physics_process(_delta):
	pass


func _process(_delta: float):

	# Synchronize this ship with the server.
	_sync_with_server_state()


# ==================================================
# SERVER SYNCHRONIZATION
# Updates the rival ship using server data.
# ==================================================

func _sync_with_server_state():

	var player_data = CurrentGame.get_player(remote_player_id)

	if player_data.is_empty():
		return

	# Ignore players that are no longer alive.
	if not player_data["isAlive"]:
		kaboom()

	# Synchronize stage separation
	# using the server altitude.
	
	var remote_alt_km = player_data["altitude"]
	var atmosLayer = player_data["atmosLayer"]
	print("atmoslayer rival: ", player_data["atmosLayer"])
	_check_remote_detach_events(remote_alt_km)
	_check_remote_fire_event(atmosLayer)


func _check_remote_fire_event(remote_atmosLayer: int):
	
	if remote_atmosLayer != remoteCurrentAtmosLayer:
		remoteCurrentAtmosLayer = remote_atmosLayer
		Fire.enableFire(remoteCurrentAtmosLayer)

# ==================================================
# STAGE SEPARATION
# Detaches rocket parts using the remote altitude.
# ==================================================

func _check_remote_detach_events(remote_alt: float):
	
	if remote_alt >= 12 and not propeller_detached:

		propeller_detached = true
		print("propeller detached")
		if propeller:
			propeller.detach(0)

	if remote_alt >= 50 and not right_wing_detached:

		right_wing_detached = true

		if right_wing:
			right_wing.detach(0)

	if remote_alt >= 55 and not left_wing_detached:

		left_wing_detached = true

		if left_wing:
			left_wing.detach(0)

	if remote_alt >= 700 and not coffer_detached:

		coffer_detached = true

		if coffer:
			coffer.detach(0)


# ==================================================
# SKIN LOADING
# Applies the rival player's selected skins.
# ==================================================

func _apply_rival_skins():

	var rival_data = null

	# Find this rival in the current game data.
	for p in CurrentGame.players:

		if p.has("id") and p["id"] == remote_player_id:

			rival_data = p
			break

	if not rival_data:

		push_warning(
			"Rival data not found in CurrentGame for ID: "
			+ str(remote_player_id)
		)

		return

	var ship_skin_dict = SkinManager.get_ship_skin_by_id(
		rival_data["shipSkin"]
	)

	var pilot_skin_dict = SkinManager.get_pilot_skin_by_id(
		rival_data["pilotSkin"]
	)

	# Apply the ship body texture.
	if has_node("ShipFinal"):
		get_node("ShipFinal").texture = load(ship_skin_dict["body"])

	# Apply textures to every detachable part.
	for part_node_name in parts_map:

		var skin_key = parts_map[part_node_name]

		if has_node(part_node_name):

			var part_node = get_node(part_node_name)
			var sprite_node = part_node.get_node("Ship" + part_node_name)

			if sprite_node and ship_skin_dict.has(skin_key):
				sprite_node.texture = load(ship_skin_dict[skin_key])

	# Apply the pilot texture.
	if has_node("Pilot"):
		get_node("Pilot").texture = pilot_skin_dict["texture"]


# ==================================================
# REMOTE DETACH
# Forces a specific rocket part to detach.
# ==================================================

func detach_remote_part(part_name: String):

	if parts_map.has(part_name):

		if has_node(part_name):

			var part = get_node(part_name) as DetachablePart

			if part:
				part.detach(0)

	else:

		push_error("Invalid remote detach request: " + part_name)
