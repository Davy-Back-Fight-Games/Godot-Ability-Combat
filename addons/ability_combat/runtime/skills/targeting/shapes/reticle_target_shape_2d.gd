class_name ReticleTargetShape2D
extends SkillTargetShape2D

@export var radius: float = 28.0

func get_debug_label() -> String:
	return "Reticle Target Shape"

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	if radius < 0.0:
		errors.append("%s reticle target shape radius cannot be negative" % _skill_label(skill))
	return errors

func contains_point(context: SkillCastContext, point: Vector2) -> bool:
	var origin := _get_origin(context)
	return origin.found and origin.position.distance_to(point) <= radius

func get_preview_shape_for_context(context: SkillCastContext) -> Resource:
	var origin := _get_origin(context)
	if not origin.found:
		return null
	var shape := SkillTargetPreviewShape.new()
	shape.shape_type = SkillTargetPreviewShape.ShapeType.RETICLE
	shape.origin = origin.position
	shape.direction = _get_direction(context)
	shape.radius = radius
	return shape

func _get_origin(context: SkillCastContext) -> Dictionary:
	if context == null:
		return {"found": false, "position": Vector2.ZERO}
	var target := context.get_target_node_or_null()
	if target != null:
		return SkillTargetingGeometry.try_get_position(target)
	return SkillTargetingGeometry.try_get_target_position_for_context(context)
