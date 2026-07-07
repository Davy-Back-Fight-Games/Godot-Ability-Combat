class_name CharacterAimState2D
extends Node

var aim_direction: Vector2 = Vector2.RIGHT
var target_position: Vector2 = Vector2.ZERO
var has_target_position: bool = false

func set_target_position(origin: Vector2, position: Vector2) -> void:
	target_position = position
	has_target_position = true
	var direction := position - origin
	if not direction.is_zero_approx():
		aim_direction = direction.normalized()

func set_aim_direction(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	aim_direction = direction.normalized()

func clear_target_position() -> void:
	has_target_position = false
