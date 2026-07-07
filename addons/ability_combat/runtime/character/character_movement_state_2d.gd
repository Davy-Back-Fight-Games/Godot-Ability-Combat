class_name CharacterMovementState2D
extends Node

var move_direction: Vector2 = Vector2.ZERO
var wants_to_move: bool = false

func set_move_direction(direction: Vector2) -> void:
	move_direction = direction.normalized() if direction.length_squared() > 1.0 else direction
	wants_to_move = not move_direction.is_zero_approx()

func clear() -> void:
	move_direction = Vector2.ZERO
	wants_to_move = false
