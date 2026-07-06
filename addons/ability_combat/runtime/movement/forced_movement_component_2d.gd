class_name ForcedMovementComponent2D
extends Node

@export var target_path: NodePath = NodePath("..")
@export var blocking: bool = true

var active: bool = false

var _target: Node2D
var _start_position: Vector2
var _target_position: Vector2
var _duration: float = 0.0
var _elapsed: float = 0.0

func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D

func _physics_process(delta: float) -> void:
	if not active or _target == null:
		return

	_elapsed += delta
	var weight := 1.0
	if _duration > 0.0:
		weight = clampf(_elapsed / _duration, 0.0, 1.0)

	_target.global_position = _start_position.lerp(_target_position, weight)
	if weight >= 1.0:
		active = false

func force_move_by(offset: Vector2, duration: float) -> void:
	if _target == null:
		_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		return
	force_move_to(_target.global_position + offset, duration)

func force_move_to(target_position: Vector2, duration: float) -> void:
	if _target == null:
		_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		return

	_start_position = _target.global_position
	_target_position = target_position
	_duration = maxf(duration, 0.0)
	_elapsed = 0.0
	active = true

func is_blocking() -> bool:
	return active and blocking
