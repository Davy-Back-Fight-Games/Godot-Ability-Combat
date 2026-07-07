class_name ApplyForcedMotionEffect2D
extends SkillEffect

const ForcedMotionRequest2DScript = preload("res://addons/ability_combat/runtime/character/forced_motion_request_2d.gd")

enum TargetScope { CASTER, TARGETS, CASTER_AND_TARGETS }
enum DirectionPolicy {
	AIM_DIRECTION,
	MOVEMENT_INPUT_OR_AIM,
	TOWARD_CASTER,
	AWAY_FROM_CASTER,
	TOWARD_TARGET_POSITION,
	AWAY_FROM_TARGET_POSITION,
	TOWARD_TARGET_NODE,
}
enum DestinationPolicy { NONE, TARGET_POSITION, TARGET_NODE, CASTER_POSITION }

@export var motion: Resource
@export var target_scope: TargetScope = TargetScope.CASTER
@export var direction_policy: DirectionPolicy = DirectionPolicy.MOVEMENT_INPUT_OR_AIM
@export var destination_policy: DestinationPolicy = DestinationPolicy.NONE
@export var move_left_action: StringName = &"MoveLeft"
@export var move_right_action: StringName = &"MoveRight"
@export var move_up_action: StringName = &"MoveUp"
@export var move_down_action: StringName = &"MoveDown"

var _warned_invalid_configuration: bool = false

func apply_context(context: SkillCastContext) -> void:
	if context == null or not _has_valid_configuration():
		return

	var applied_count := 0
	for target in _get_motion_targets(context):
		if _apply_to_target(context, target):
			applied_count += 1

	if _should_log():
		var skill_label := "<unknown skill>"
		if context.skill is SkillDefinition:
			skill_label = context.skill.get_label()
		print("[ApplyForcedMotionEffect2D] %s applied %s to %s target(s)" % [skill_label, motion.get_debug_description(), applied_count])

func _apply_to_target(context: SkillCastContext, target: Node) -> bool:
	var node_2d := SkillTargetingGeometry.get_node2d(target)
	if node_2d == null:
		return false

	var forced_motion := ForcedMotionQueue2D.find_for_node(node_2d)
	if forced_motion == null:
		return false

	var direction := _get_direction(context, node_2d)
	if motion.has_method(&"is_destination_based") and motion.is_destination_based():
		var destination := _get_destination(context)
		if destination.found:
			forced_motion.queue_request_to(motion, destination.position, direction, context.caster)
			return true

	if direction.is_zero_approx():
		return false
	forced_motion.queue_request(motion, direction, context.caster)
	return true

func _get_motion_targets(context: SkillCastContext) -> Array[Node]:
	var nodes: Array[Node] = []
	if target_scope == TargetScope.CASTER or target_scope == TargetScope.CASTER_AND_TARGETS:
		if context.caster != null:
			nodes.append(context.caster)
	if target_scope == TargetScope.TARGETS or target_scope == TargetScope.CASTER_AND_TARGETS:
		for target in context.targets:
			if target != null and is_instance_valid(target):
				nodes.append(target)
	return nodes

func _get_direction(context: SkillCastContext, target: Node2D) -> Vector2:
	match direction_policy:
		DirectionPolicy.MOVEMENT_INPUT_OR_AIM:
			var movement_direction := _get_movement_direction(context)
			if not movement_direction.is_zero_approx():
				return movement_direction
			return SkillTargetingGeometry.get_forward_for_context(context)
		DirectionPolicy.AIM_DIRECTION:
			return SkillTargetingGeometry.get_forward_for_context(context)
		DirectionPolicy.TOWARD_CASTER:
			var caster_position := _get_node_position(context.caster)
			return _direction_between(target.global_position, caster_position.position) if caster_position.found else Vector2.ZERO
		DirectionPolicy.AWAY_FROM_CASTER:
			var caster_position := _get_node_position(context.caster)
			return _direction_between(caster_position.position, target.global_position) if caster_position.found else Vector2.ZERO
		DirectionPolicy.TOWARD_TARGET_POSITION:
			return _direction_between(target.global_position, context.get_target_position_or_default(target.global_position))
		DirectionPolicy.AWAY_FROM_TARGET_POSITION:
			return _direction_between(context.get_target_position_or_default(target.global_position), target.global_position)
		DirectionPolicy.TOWARD_TARGET_NODE:
			var target_position := _get_node_position(context.get_target_node_or_null())
			return _direction_between(target.global_position, target_position.position) if target_position.found else Vector2.ZERO
	return Vector2.ZERO

func _get_destination(context: SkillCastContext) -> Dictionary:
	match destination_policy:
		DestinationPolicy.TARGET_POSITION:
			if context.has_target_position:
				return {"found": true, "position": context.target_position}
		DestinationPolicy.TARGET_NODE:
			return _get_node_position(context.get_target_node_or_null())
		DestinationPolicy.CASTER_POSITION:
			return _get_node_position(context.caster)
	return {"found": false, "position": Vector2.ZERO}

func _get_movement_direction(context: SkillCastContext) -> Vector2:
	var movement_state := _get_movement_state(context)
	if movement_state != null and movement_state.wants_to_move:
		return movement_state.move_direction.normalized()
	if _has_movement_actions():
		var movement_direction := Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action)
		if not movement_direction.is_zero_approx():
			return movement_direction.normalized()
	return Vector2.ZERO

func _get_movement_state(context: SkillCastContext) -> CharacterMovementState2D:
	if context == null:
		return null
	var node_2d := SkillTargetingGeometry.get_node2d(context.caster)
	var current: Node = node_2d
	while current != null:
		for child in current.get_children():
			if child is CharacterMovementState2D:
				return child
		current = current.get_parent()
	return null

func _get_node_position(node: Node) -> Dictionary:
	return SkillTargetingGeometry.try_get_position(node)

func _direction_between(from_position: Vector2, to_position: Vector2) -> Vector2:
	var direction := to_position - from_position
	if direction.is_zero_approx():
		return Vector2.ZERO
	return direction.normalized()

func _has_movement_actions() -> bool:
	return InputMap.has_action(move_left_action) \
		and InputMap.has_action(move_right_action) \
		and InputMap.has_action(move_up_action) \
		and InputMap.has_action(move_down_action)

func _has_valid_configuration() -> bool:
	if motion != null and motion is ForcedMotionRequest2DScript:
		return true
	if not _warned_invalid_configuration:
		_warned_invalid_configuration = true
		push_warning("ApplyForcedMotionEffect2D configuration is invalid: motion must be a ForcedMotionRequest2D resource.")
	return false
