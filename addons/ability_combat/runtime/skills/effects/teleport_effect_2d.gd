class_name TeleportEffect2D
extends SkillEffect

enum TargetScope { CASTER, TARGETS, CASTER_AND_TARGETS }
enum DestinationPolicy { TARGET_POSITION, AIM_DIRECTION_DISTANCE, TARGET_NODE }
enum ValidationMode { NONE, DESTINATION_ONLY, SWEEP_TO_DESTINATION, CLAMP_TO_LAST_VALID }
enum BlockedDestinationBehavior { REJECT, CLAMP_BACK }

@export var target_scope: TargetScope = TargetScope.CASTER
@export var destination_policy: DestinationPolicy = DestinationPolicy.TARGET_POSITION
@export var distance: FloatReference
@export var max_range: FloatReference
@export var reject_blocked_destination: bool = true
@export var validation_mode: ValidationMode = ValidationMode.DESTINATION_ONLY
@export var blocked_destination_behavior: BlockedDestinationBehavior = BlockedDestinationBehavior.REJECT
@export_range(1, 16, 1) var max_clamp_iterations: int = 8

var _warned_invalid_configuration: bool = false

func apply_context(context: SkillCastContext) -> void:
	if context == null or not _has_valid_configuration():
		return

	var applied_count := 0
	for target in _get_targets(context):
		if _teleport_target(context, target):
			applied_count += 1

	if _should_log():
		var skill_label := "<unknown skill>"
		if context.skill is SkillDefinition:
			skill_label = context.skill.get_label()
		print("[TeleportEffect2D] %s teleported %s target(s)" % [skill_label, applied_count])

func _teleport_target(context: SkillCastContext, target: Node) -> bool:
	var node_2d := SkillTargetingGeometry.get_node2d(target)
	if node_2d == null:
		return false

	var destination_result := _get_destination(context, node_2d)
	if not destination_result.found:
		return false

	var destination: Vector2 = destination_result.position
	destination = _clamp_to_max_range(node_2d.global_position, destination)
	var valid_destination := _get_valid_destination(node_2d, destination)
	if not valid_destination.found:
		return false

	node_2d.global_position = valid_destination.position
	return true

func _get_targets(context: SkillCastContext) -> Array[Node]:
	var nodes: Array[Node] = []
	if target_scope == TargetScope.CASTER or target_scope == TargetScope.CASTER_AND_TARGETS:
		if context.caster != null:
			nodes.append(context.caster)
	if target_scope == TargetScope.CASTER:
		return nodes
	for target in context.targets:
		if target != null and is_instance_valid(target):
			nodes.append(target)
	return nodes

func _get_valid_destination(node_2d: Node2D, destination: Vector2) -> Dictionary:
	if validation_mode == ValidationMode.NONE:
		return {"found": true, "position": destination}

	var start_position := node_2d.global_position
	if validation_mode == ValidationMode.SWEEP_TO_DESTINATION and _can_sweep_to_position(node_2d, start_position, destination):
		return {"found": true, "position": destination}
	if validation_mode == ValidationMode.DESTINATION_ONLY and _can_occupy_position(node_2d, destination):
		return {"found": true, "position": destination}
	if validation_mode == ValidationMode.CLAMP_TO_LAST_VALID:
		var clamped := _find_last_valid_destination(node_2d, start_position, destination)
		if clamped.found:
			return clamped

	if not reject_blocked_destination:
		return {"found": true, "position": destination}
	if blocked_destination_behavior == BlockedDestinationBehavior.CLAMP_BACK:
		return _find_last_valid_destination(node_2d, start_position, destination)
	return {"found": false, "position": Vector2.ZERO}

func _get_destination(context: SkillCastContext, target: Node2D) -> Dictionary:
	match destination_policy:
		DestinationPolicy.TARGET_POSITION:
			if context.has_target_position:
				return {"found": true, "position": context.target_position}
		DestinationPolicy.AIM_DIRECTION_DISTANCE:
			var direction := SkillTargetingGeometry.get_forward_for_context(context)
			if not direction.is_zero_approx():
				return {"found": true, "position": target.global_position + direction.normalized() * _get_distance()}
		DestinationPolicy.TARGET_NODE:
			return SkillTargetingGeometry.try_get_position(context.get_target_node_or_null())
	return {"found": false, "position": Vector2.ZERO}

func _clamp_to_max_range(from_position: Vector2, destination: Vector2) -> Vector2:
	var range_limit := _get_max_range()
	if range_limit <= 0.0:
		return destination
	var offset := destination - from_position
	if offset.length() <= range_limit:
		return destination
	return from_position + offset.normalized() * range_limit

func _can_occupy_position(node_2d: Node2D, destination: Vector2) -> bool:
	if node_2d is CharacterBody2D:
		var body := node_2d as CharacterBody2D
		var destination_transform := body.global_transform
		destination_transform.origin = destination
		return not body.test_move(destination_transform, Vector2.ZERO)
	return true

func _can_sweep_to_position(node_2d: Node2D, start_position: Vector2, destination: Vector2) -> bool:
	if node_2d is CharacterBody2D:
		var body := node_2d as CharacterBody2D
		var start_transform := body.global_transform
		start_transform.origin = start_position
		return not body.test_move(start_transform, destination - start_position)
	return true

func _find_last_valid_destination(node_2d: Node2D, start_position: Vector2, destination: Vector2) -> Dictionary:
	if not _can_occupy_position(node_2d, start_position):
		return {"found": false, "position": Vector2.ZERO}
	if _can_sweep_to_position(node_2d, start_position, destination) and _can_occupy_position(node_2d, destination):
		return {"found": true, "position": destination}

	var low := 0.0
	var high := 1.0
	var best := start_position
	for i in max_clamp_iterations:
		var midpoint := (low + high) * 0.5
		var candidate := start_position.lerp(destination, midpoint)
		if _can_sweep_to_position(node_2d, start_position, candidate) and _can_occupy_position(node_2d, candidate):
			best = candidate
			low = midpoint
		else:
			high = midpoint
	return {"found": true, "position": best}

func _get_distance() -> float:
	if distance == null:
		return 0.0
	return maxf(distance.get_value(), 0.0)

func _get_max_range() -> float:
	if max_range == null:
		return 0.0
	return maxf(max_range.get_value(), 0.0)

func _has_valid_configuration() -> bool:
	if destination_policy != DestinationPolicy.AIM_DIRECTION_DISTANCE or distance != null:
		return true
	if not _warned_invalid_configuration:
		_warned_invalid_configuration = true
		push_warning("TeleportEffect2D configuration is invalid: distance is required for AIM_DIRECTION_DISTANCE.")
	return false
