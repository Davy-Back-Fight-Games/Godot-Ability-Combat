class_name SkillTargetingGeometry
extends RefCounted

static func get_node2d(node: Node) -> Node2D:
	if node is Node2D:
		return node
	if node != null and node.get_parent() is Node2D:
		return node.get_parent()
	return null

static func try_get_position(node: Node) -> Dictionary:
	var node_2d := get_node2d(node)
	if node_2d == null:
		return {"found": false, "position": Vector2.ZERO}
	return {"found": true, "position": node_2d.global_position}

static func try_get_target_position(node: Node) -> Dictionary:
	if node != null and node.has_meta(&"skill_target_position"):
		var position = node.get_meta(&"skill_target_position")
		if position is Vector2:
			return {"found": true, "position": position}

	var node_2d := get_node2d(node)
	if node_2d != null and node_2d.has_meta(&"skill_target_position"):
		var parent_position = node_2d.get_meta(&"skill_target_position")
		if parent_position is Vector2:
			return {"found": true, "position": parent_position}

	return {"found": false, "position": Vector2.ZERO}

static func try_get_target_position_for_context(context: SkillCastContext) -> Dictionary:
	if context != null and context.has_target_position:
		return {"found": true, "position": context.target_position}
	if context == null:
		return {"found": false, "position": Vector2.ZERO}
	return try_get_target_position(context.caster)

static func get_forward(node: Node) -> Vector2:
	var aim_direction := try_get_aim_direction(node)
	if aim_direction.found:
		return aim_direction.direction

	var node_2d := get_node2d(node)
	if node_2d == null:
		return Vector2.RIGHT
	return Vector2.RIGHT.rotated(node_2d.global_rotation).normalized()

static func get_forward_for_context(context: SkillCastContext) -> Vector2:
	if context != null and context.has_aim_direction:
		return context.get_aim_direction_or_default()
	if context == null:
		return Vector2.RIGHT
	return get_forward(context.caster)

static func try_get_aim_direction(node: Node) -> Dictionary:
	if node != null and node.has_meta(&"skill_aim_direction"):
		var direction = node.get_meta(&"skill_aim_direction")
		if direction is Vector2 and not direction.is_zero_approx():
			return {"found": true, "direction": direction.normalized()}

	var node_2d := get_node2d(node)
	if node_2d != null and node_2d.has_meta(&"skill_aim_direction"):
		var parent_direction = node_2d.get_meta(&"skill_aim_direction")
		if parent_direction is Vector2 and not parent_direction.is_zero_approx():
			return {"found": true, "direction": parent_direction.normalized()}

	return {"found": false, "direction": Vector2.RIGHT}
