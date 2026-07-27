extends Node2D


@onready var Player: Node2D = $Player
@onready var PilotTexture: Sprite2D = $Player/Pilot
@onready var ShipFinalTexture : Sprite2D = $Player/ShipFinal

@onready var Background: AnimatedSprite2D = $Background
@onready var OkCatBaloon: AnimatedSprite2D = $OkCat


# Player movement positions
const PLAYER_START_POS := Vector2(-71, 463) # Outside the screen on the left
const PLAYER_CENTER_POS := Vector2(106, 102) # Center position
const PLAYER_END_POS := Vector2(257, -157) # Outside the screen on the right


func _ready() -> void:
	# Make this sequence run even when the game is paused
	Player.process_mode = Node.PROCESS_MODE_ALWAYS
	Background.process_mode = Node.PROCESS_MODE_ALWAYS
	OkCatBaloon.process_mode = Node.PROCESS_MODE_ALWAYS
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Hide everything before the sequence starts
	Player.visible = false
	Background.visible = false
	OkCatBaloon.visible = false


func start() -> void:
	Player.visible = true
	Background.visible = true
	
	# Load player customization skins
	var ShipSkin = SkinManager.get_ship_skin_by_id(PlayerConfig.get_rocket_skin_id())
	var PilotSkin = SkinManager.get_pilot_skin_by_id(PlayerConfig.get_pilot_skin_id())
	
	ShipFinalTexture.texture = load(ShipSkin["body"])
	PilotTexture.texture = PilotSkin["texture"]


	# MOMENT 1:
	# Player enters from the left side while the background entrance animation plays
	Player.position = PLAYER_START_POS
	
	var enter_tween = create_tween()
	enter_tween.tween_property(
		Player,
		"position",
		PLAYER_CENTER_POS,
		1.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	AudioManager.play_game_sound("swoosh")
	
	Background.play("Entrance")
	await Background.animation_finished
	
	# Background stays looping in the middle section
	Background.play("Loop")


	# MOMENT 2:
	# Cat balloon appears and both background and cat stay looping
	OkCatBaloon.visible = true
	OkCatBaloon.play("Spawn")
	await OkCatBaloon.animation_finished
	
	OkCatBaloon.play("Loop")
	
	# Keep the scene active for 3 seconds
	await get_tree().create_timer(3.0).timeout


	# Cat balloon disappears
	OkCatBaloon.stop()
	OkCatBaloon.play("Despawn")
	await OkCatBaloon.animation_finished


	# MOMENT 3:
	# Player leaves the screen through the right side
	var exit_tween = create_tween()
	exit_tween.tween_property(
		Player,
		"position",
		PLAYER_END_POS,
		1.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	AudioManager.play_game_sound("swoosh")
	await exit_tween.finished


	# Wait 4 seconds after the player leaves before cleaning everything
	await get_tree().create_timer(2.0).timeout
	
	finish()


func finish() -> void:
	# Hide and stop all animations
	Player.visible = false
	Background.visible = false
	OkCatBaloon.visible = false
	
	OkCatBaloon.stop()
	Background.stop()


func _process(delta: float) -> void:
	pass
