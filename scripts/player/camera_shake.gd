extends Camera2D

var shaking := false
var shake_time := 0.0
var shake_strength := 0.0

var original_position := Vector2.ZERO


func _ready():
	original_position = position


func _process(delta):
	if shaking:
		shake_time -= delta

		if shake_time <= 0:
			shaking = false
			position = original_position
			return

		var intensity = shake_strength * (shake_time / 3.0)

		position = original_position + Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)


func shake(duration: float, strength: float):
	shaking = true
	shake_time = duration
	shake_strength = strength
