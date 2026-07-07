class_name GroundCircleTargetShape2D
extends CircleTargetShape2D

@export var max_cast_range: float = 0.0

func get_debug_label() -> String:
	return "Ground Circle Target Shape"

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := super.get_validation_errors(skill)
	if max_cast_range < 0.0:
		errors.append("%s ground circle target shape max_cast_range cannot be negative" % _skill_label(skill))
	return errors

func _get_origin(context: SkillCastContext) -> Dictionary:
	if context == null:
		return {"found": false, "position": Vector2.ZERO}
	var target_position := SkillTargetingGeometry.try_get_target_position_for_context(context)
	if not target_position.found:
		target_position = SkillTargetingGeometry.try_get_position(context.caster)
	if not target_position.found or max_cast_range <= 0.0:
		return target_position

	var caster_position := SkillTargetingGeometry.try_get_position(context.caster)
	if not caster_position.found:
		return target_position

	var offset: Vector2 = target_position.position - caster_position.position
	if offset.length() <= max_cast_range:
		return target_position
	return {"found": true, "position": caster_position.position + offset.normalized() * max_cast_range}
