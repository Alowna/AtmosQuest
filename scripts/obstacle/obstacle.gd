extends CharacterBody2D
class_name Obstacle

@export var speed := 50.0
@export var delete_distance := 400.0
# The movement speed of this obstacle.

var movement_direction := Vector2.RIGHT
# The current movement direction.
var player_ref: Node2D
# Reference to the player node.

func setup(direction: Vector2, player: Node2D):
	# Defines the movement direction and player reference when the obstacle is spawned.
	movement_direction = direction
	player_ref = player
	
	# --- AUTOMATIC SPRITE DETECTION ---
	var visual_node: Node2D = null
	
	# Iterate through all children of this obstacle.
	for child in get_children():
		# If the child is a Sprite2D or AnimatedSprite2D, capture the reference.
		if child is Sprite2D or child is AnimatedSprite2D:
			visual_node = child
			break # Found the visual node, exit the loop.
	
	# --- VISUAL FLIP LOGIC ---
	if is_instance_valid(visual_node):
		# Flip the sprite horizontally if moving to the left.
		# Both Sprite2D and AnimatedSprite2D support the 'flip_h' property.
		if direction == Vector2.LEFT:
			visual_node.flip_h = true
		else:
			visual_node.flip_h = false

func _physics_process(_delta):
	# Moves the obstacle using its configured velocity.
	move_obstacle(movement_direction)
	
	# Check if the player reference exists and calculate the distance.
	if is_instance_valid(player_ref):
		var distance = global_position.distance_to(player_ref.global_position)
		# If the obstacle is too far from the player, remove it from memory.
		if distance > delete_distance:
			queue_free()
	
	if get_slide_collision_count() > 0:
		get_tree().paused = true
		
		var collision = get_slide_collision(0)

		if collision.get_collider().is_in_group("player"):
			get_tree().paused = true
			
			var question_manager = get_tree().current_scene.get_node("CanvasLayer/Question/QuestionScreen/QuestionManager")
			
			var question = get_tree().current_scene.get_node("CanvasLayer/Question")
			if is_instance_valid(question_manager):
				question_manager.question_finished.connect(_on_question_finished)
				question.start()

				hide()
				set_physics_process(false)

func move_obstacle(direction: Vector2):
	# Calculate the movement velocity based on the given direction.
	velocity = direction * speed
	
	# Apply the velocity and move the CharacterBody2D.
	move_and_slide()

func _on_question_finished():
	queue_free()
