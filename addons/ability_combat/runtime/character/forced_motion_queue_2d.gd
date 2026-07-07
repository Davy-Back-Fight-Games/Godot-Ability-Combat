class_name ForcedMotionQueue2D
extends Node

const ForcedMotionRequest2DScript = preload("res://addons/ability_combat/runtime/character/forced_motion_request_2d.gd")

@export var target_path: NodePath = NodePath("..")
@export var blocking: bool = true

var active: bool = false

var _target: Node2D
var _queue: Array[Dictionary] = []
var _remaining_offset: Vector2 = Vector2.ZERO
var _remaining_duration: float = 0.0
var _active_blocking: bool = true
var _active_collision_policy: int = ForcedMotionRequest2DScript.CollisionPolicy.SLIDE
var _active_motion_kind: int = ForcedMotionRequest2DScript.MotionKind.CUSTOM
var _active_source: Node

func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D

func force_move_by(offset: Vector2, duration: float) -> void:
	queue_motion(offset, duration, blocking, ForcedMotionRequest2DScript.CollisionPolicy.SLIDE)

func force_move_to(target_position: Vector2, duration: float) -> void:
	var target := _get_target()
	if target == null:
		return
	queue_motion_to_position(target_position, duration, blocking, ForcedMotionRequest2DScript.CollisionPolicy.SLIDE)

func queue_request(request: Resource, direction: Vector2, source: Node = null) -> void:
	if request == null or direction.is_zero_approx() or not request.has_method(&"get_distance") or not request.has_method(&"get_duration"):
		return
	queue_motion(
		request.get_offset_for_direction(direction) if request.has_method(&"get_offset_for_direction") else direction.normalized() * request.get_distance(),
		request.get_duration(),
		request.blocking,
		request.collision_policy,
		request.motion_kind,
		source
	)

func queue_request_to(request: Resource, destination: Vector2, fallback_direction: Vector2 = Vector2.ZERO, source: Node = null) -> void:
	var target := _get_target()
	if request == null or target == null or not request.has_method(&"get_offset_for_destination") or not request.has_method(&"get_duration"):
		return
	queue_motion(
		request.get_offset_for_destination(target.global_position, destination, fallback_direction),
		request.get_duration(),
		request.blocking,
		request.collision_policy,
		request.motion_kind,
		source
	)

func queue_motion_to_position(target_position: Vector2, duration: float, motion_blocking: bool = true, collision_policy: int = ForcedMotionRequest2DScript.CollisionPolicy.SLIDE, motion_kind: int = ForcedMotionRequest2DScript.MotionKind.CUSTOM, source: Node = null) -> void:
	var target := _get_target()
	if target == null:
		return
	queue_motion(target_position - target.global_position, duration, motion_blocking, collision_policy, motion_kind, source)

func queue_motion(offset: Vector2, duration: float, motion_blocking: bool = true, collision_policy: int = ForcedMotionRequest2DScript.CollisionPolicy.SLIDE, motion_kind: int = ForcedMotionRequest2DScript.MotionKind.CUSTOM, source: Node = null) -> void:
	if offset.is_zero_approx():
		return
	_queue.append({
		"offset": offset,
		"duration": maxf(duration, 0.0),
		"blocking": motion_blocking,
		"collision_policy": collision_policy,
		"motion_kind": motion_kind,
		"source": source,
	})
	if not active:
		_start_next_motion()

func clear() -> void:
	_queue.clear()
	_remaining_offset = Vector2.ZERO
	_remaining_duration = 0.0
	_active_source = null
	active = false

func is_blocking() -> bool:
	return active and _active_blocking

func notify_collision() -> void:
	if active and _active_collision_policy == ForcedMotionRequest2DScript.CollisionPolicy.STOP_ON_COLLISION:
		_finish_current_motion()

func get_debug_state() -> Dictionary:
	return {
		"active": active,
		"queued_count": _queue.size(),
		"remaining_offset": _remaining_offset,
		"remaining_duration": _remaining_duration,
		"blocking": _active_blocking,
		"collision_policy": _active_collision_policy,
		"motion_kind": _active_motion_kind,
		"source": _active_source,
	}

static func find_for_node(node: Node) -> ForcedMotionQueue2D:
	var current := node
	while current != null:
		for child in current.get_children():
			if child is ForcedMotionQueue2D:
				return child
		current = current.get_parent()
	return null

func consume_velocity(delta: float) -> Vector2:
	if delta <= 0.0:
		return Vector2.ZERO
	if not active:
		_start_next_motion()
	if not active:
		return Vector2.ZERO

	if _remaining_duration <= 0.0:
		var instant_velocity := _remaining_offset / delta
		_finish_current_motion()
		return instant_velocity

	var step_duration := minf(delta, _remaining_duration)
	var velocity := _remaining_offset / _remaining_duration
	_remaining_offset -= velocity * step_duration
	_remaining_duration -= step_duration
	if _remaining_duration <= 0.0001 or _remaining_offset.is_zero_approx():
		_finish_current_motion()
	return velocity

func _start_next_motion() -> void:
	if _queue.is_empty():
		active = false
		return
	var motion: Dictionary = _queue.pop_front()
	_remaining_offset = motion.get("offset", Vector2.ZERO)
	_remaining_duration = float(motion.get("duration", 0.0))
	_active_blocking = bool(motion.get("blocking", blocking))
	_active_collision_policy = int(motion.get("collision_policy", ForcedMotionRequest2DScript.CollisionPolicy.SLIDE))
	_active_motion_kind = int(motion.get("motion_kind", ForcedMotionRequest2DScript.MotionKind.CUSTOM))
	_active_source = motion.get("source", null)
	active = not _remaining_offset.is_zero_approx()
	if not active:
		_start_next_motion()

func _finish_current_motion() -> void:
	_remaining_offset = Vector2.ZERO
	_remaining_duration = 0.0
	_active_source = null
	active = false
	_start_next_motion()

func _get_target() -> Node2D:
	if _target != null:
		return _target
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node2D
	return _target
