class_name SkillTargetShape2D
extends Resource

func get_debug_label() -> String:
	return "Target Shape 2D"

func get_validation_errors(_skill: SkillDefinition) -> PackedStringArray:
	return PackedStringArray()

func contains_point(context: SkillCastContext, point: Vector2) -> bool:
	var origin := _get_origin(context)
	return origin.found and point.is_equal_approx(origin.position)

func contains_target(context: SkillCastContext, target: Node) -> bool:
	var target_position := SkillTargetingGeometry.try_get_position(target)
	return target_position.found and contains_point(context, target_position.position)

func get_preview_shape_for_context(_context: SkillCastContext) -> Resource:
	return null

func _get_origin(context: SkillCastContext) -> Dictionary:
	if context == null:
		return {"found": false, "position": Vector2.ZERO}
	return SkillTargetingGeometry.try_get_position(context.caster)

func _get_direction(context: SkillCastContext) -> Vector2:
	return SkillTargetingGeometry.get_forward_for_context(context)

func _skill_label(skill: SkillDefinition) -> String:
	return skill.get_label() if skill != null else "<unnamed skill>"
