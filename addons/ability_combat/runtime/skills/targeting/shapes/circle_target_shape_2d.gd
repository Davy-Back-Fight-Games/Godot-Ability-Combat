class_name CircleTargetShape2D
extends SkillTargetShape2D

@export var radius: float = 0.0

func get_debug_label() -> String:
	return "Circle Target Shape"

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	if radius < 0.0:
		errors.append("%s circle target shape radius cannot be negative" % _skill_label(skill))
	return errors

func contains_point(context: SkillCastContext, point: Vector2) -> bool:
	if radius <= 0.0:
		return true
	var origin := _get_origin(context)
	return origin.found and origin.position.distance_to(point) <= radius

func get_preview_shape_for_context(context: SkillCastContext) -> Resource:
	var origin := _get_origin(context)
	if not origin.found:
		return null
	var shape := SkillTargetPreviewShape.new()
	shape.shape_type = SkillTargetPreviewShape.ShapeType.CIRCLE
	shape.origin = origin.position
	shape.direction = _get_direction(context)
	shape.radius = radius
	return shape
