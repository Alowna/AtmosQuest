extends Node2D
# Controls a group of background sprites and recycles them
# to create an infinite scrolling effect.

@export var player: Node2D
# Reference to the player node.
# Set this in the Inspector by dragging the Ship node here.

@export var background_width: float
# Width of each background sprite in pixels.
# When a background goes too far away from the player,
# it will be moved by this amount.

var backgrounds = []
# Array that stores all background nodes.


func _ready():
	
	player = get_tree().get_first_node_in_group("player")
	# Loop through all children inside this Node2D.
	for child in get_children():
		
		# Add each background child to the array.
		backgrounds.append(child)
		# Get the width of the first background sprite automatically
		background_width = backgrounds[0].texture.get_width() * backgrounds[0].scale.x
	
	print(background_width)
	



func _process(delta):
	# Get the player's current horizontal position.
	var player_x = player.global_position.x


	# Check every background stored in the array.
	for bg in backgrounds:


		# Check if the player has moved past this background to the right.
		if player_x > bg.global_position.x + background_width:

			# Get the position of the background currently furthest to the right.
			var rightmost_x = get_rightmost_x()


			# Move this background to the right side of the group.
			# This keeps the backgrounds connected without empty spaces.
			bg.global_position.x = rightmost_x + background_width



		# Check if the player has moved past this background to the left.
		elif player_x < bg.global_position.x - background_width:

			# Get the position of the background currently furthest to the left.
			var leftmost_x = get_leftmost_x()


			# Move this background to the left side of the group.
			bg.global_position.x = leftmost_x - background_width




func get_rightmost_x():
	# Assume the first background is the one furthest to the right.
	var rightmost = backgrounds[0].global_position.x


	# Check every background position.
	for bg in backgrounds:

		# If this background is further right, update the value.
		if bg.global_position.x > rightmost:
			rightmost = bg.global_position.x


	# Return the X position of the rightmost background.
	return rightmost




func get_leftmost_x():
	# Assume the first background is the one furthest to the left.
	var leftmost = backgrounds[0].global_position.x


	# Check every background position.
	for bg in backgrounds:

		# If this background is further left, update the value.
		if bg.global_position.x < leftmost:
			leftmost = bg.global_position.x


	# Return the X position of the leftmost background.
	return leftmost
