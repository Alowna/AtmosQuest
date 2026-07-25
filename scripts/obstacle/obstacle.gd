extends CharacterBody2D
class_name Obstacle

@export var speed := 50.0
@export var delete_distance := 400.0

# Downward angle tilt in degrees (e.g., 30.0 for diagonal downward movement)
@export var drop_angle_degrees := 0.0

# If true, rotates the visual sprite to align with the trajectory direction
@export var rotate_sprite := false

# Reference to the trigger area used to detect the player
@onready var trigger_area: Area2D = $Area2D

var movement_direction := Vector2.RIGHT
var player_ref: Node2D
var obstacle_name = "Desconhecido"

func _ready():
	# Connect the trigger signal once when the obstacle is created
	trigger_area.body_entered.connect(_on_trigger_body_entered)

func setup(base_direction: Vector2, player: Node2D):
	player_ref = player

	# --- DIRECTION & INCLINATION CALCULATIONS ---
	var final_direction = base_direction

	# If a downward angle is defined, tilt the trajectory
	if drop_angle_degrees != 0.0:
		var angle_rad = deg_to_rad(drop_angle_degrees)

		if base_direction == Vector2.LEFT:
			# Coming from the right: rotate counter-clockwise to point diagonally downward
			final_direction = base_direction.rotated(-angle_rad)
		else:
			# Coming from the left: rotate clockwise to point diagonally downward
			final_direction = base_direction.rotated(angle_rad)

	movement_direction = final_direction.normalized()

	# --- AUTOMATIC SPRITE DETECTION ---
	var visual_node: Node2D = null
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			visual_node = child
			break

	# --- VISUAL FLIP & ROTATION LOGIC ---
	if is_instance_valid(visual_node):
		# Check if moving towards the left side (x < 0 covers horizontal & diagonal vectors)
		if movement_direction.x < 0:
			visual_node.flip_h = true
			if rotate_sprite:
				visual_node.rotation = -deg_to_rad(drop_angle_degrees)
		else:
			visual_node.flip_h = false
			if rotate_sprite:
				visual_node.rotation = deg_to_rad(drop_angle_degrees)

func _physics_process(_delta):
	move_obstacle(movement_direction)

	# Despawn obstacle if it moves beyond the specified distance threshold
	if is_instance_valid(player_ref):
		var distance = global_position.distance_to(player_ref.global_position)
		if distance > delete_distance:
			queue_free()

# Called when the player enters the obstacle trigger area
func _on_trigger_body_entered(body):
	if !body.is_in_group("player"):
		return

	get_tree().paused = true

	PlayerConfig.collisions += 1
	PlayerConfig.collisionDeathObject = obstacle_name

	var question_manager = get_tree().current_scene.get_node("CanvasLayer/Question/QuestionScreen/QuestionManager")
	var question = get_tree().current_scene.get_node("CanvasLayer/Question")

	if is_instance_valid(question_manager):
		# Prevent duplicate signal connections
		if !question_manager.question_finished.is_connected(_on_question_finished):
			question_manager.question_finished.connect(_on_question_finished)

		question.start()
		set_physics_process(false)

func move_obstacle(direction: Vector2):
	velocity = direction * speed
	move_and_slide()

func _on_question_finished(is_correct: bool):
	# Disconnect signal to avoid duplicate connections on future collisions
	var question_manager = get_tree().current_scene.get_node_or_null("CanvasLayer/Question/QuestionScreen/QuestionManager")
	if is_instance_valid(question_manager) and question_manager.question_finished.is_connected(_on_question_finished):
		question_manager.question_finished.disconnect(_on_question_finished)

	if is_correct:
		# Player answered correctly:
		# Disable the trigger so this obstacle can no longer activate a question.
		trigger_area.set_deferred("monitoring", false)

		show()
		set_physics_process(true)
	else:
		# Player answered incorrectly: remove the obstacle.
		queue_free()
