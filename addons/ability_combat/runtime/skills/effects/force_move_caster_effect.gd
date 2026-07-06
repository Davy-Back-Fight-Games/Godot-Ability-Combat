class_name ForceMoveCasterEffect
extends SkillEffect

@export var distance: FloatReference
@export var duration: FloatReference
@export var prefer_movement_input: bool = true
@export var move_left_action: StringName = &"MoveLeft"
@export var move_right_action: StringName = &"MoveRight"
@export var move_up_action: StringName = &"MoveUp"
@export var move_down_action: StringName = &"MoveDown"

func apply_context(context: SkillCastContext) -> void:
	if context == null:
		return

	var node_2d := SkillTargetingGeometry.get_node2d(context.caster)
	if node_2d == null:
		return

	var forced_movement := _get_forced_movement_component(node_2d)
	if forced_movement == null:
		return

	var direction := _get_direction(context)
	if direction.is_zero_approx():
		return

	forced_movement.force_move_by(direction.normalized() * _get_distance(), _get_duration())

	if _should_log():
		print("[ForceMoveCasterEffect] force moving %s by %s over %.2fs" % [node_2d.name, _get_distance(), _get_duration()])

func _get_forced_movement_component(node_2d: Node2D) -> Node:
	for child in node_2d.get_children():
		if child is ForcedMovementComponent2D:
			return child
	return null

func _get_distance() -> float:
	if distance == null:
		return 0.0
	return distance.get_value()

func _get_duration() -> float:
	if duration == null:
		return 0.0
	return duration.get_value()

func _get_direction(context: SkillCastContext) -> Vector2:
	if prefer_movement_input and _has_movement_actions():
		var movement_direction := Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action)
		if not movement_direction.is_zero_approx():
			return movement_direction.normalized()

	return SkillTargetingGeometry.get_forward_for_context(context)

func _has_movement_actions() -> bool:
	return InputMap.has_action(move_left_action) \
		and InputMap.has_action(move_right_action) \
		and InputMap.has_action(move_up_action) \
		and InputMap.has_action(move_down_action)
