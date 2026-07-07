class_name CharacterAnimationDriver2D
extends Node

@export var movement_state_path: NodePath = NodePath("../CharacterMovementState2D")
@export var aim_state_path: NodePath = NodePath("../CharacterAimState2D")
@export var direction_marker_path: NodePath

@onready var _movement_state: CharacterMovementState2D = get_node_or_null(movement_state_path) as CharacterMovementState2D
@onready var _aim_state: CharacterAimState2D = get_node_or_null(aim_state_path) as CharacterAimState2D
@onready var _direction_marker: Node2D = get_node_or_null(direction_marker_path) as Node2D

func _process(_delta: float) -> void:
	if _direction_marker == null:
		return
	var direction := _get_direction()
	if direction.is_zero_approx():
		return
	_direction_marker.rotation = direction.angle() + PI / 2.0

func _get_direction() -> Vector2:
	if _aim_state != null and not _aim_state.aim_direction.is_zero_approx():
		return _aim_state.aim_direction
	if _movement_state != null and _movement_state.wants_to_move:
		return _movement_state.move_direction
	return Vector2.ZERO
