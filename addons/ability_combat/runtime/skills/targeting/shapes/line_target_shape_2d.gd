class_name LineTargetShape2D
extends SkillTargetShape2D

@export var length: float = 0.0
@export var width: float = 0.0

func get_debug_label() -> String:
	return "Line Target Shape"

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	if length < 0.0:
		errors.append("%s line target shape length cannot be negative" % _skill_label(skill))
	if width < 0.0:
		errors.append("%s line target shape width cannot be negative" % _skill_label(skill))
	return errors

func contains_point(context: SkillCastContext, point: Vector2) -> bool:
	var origin := _get_origin(context)
	if not origin.found:
		return false

	var direction := _get_direction(context)
	var offset: Vector2 = point - origin.position
	var along: float = offset.dot(direction)
	if along < 0.0:
		return false
	if length > 0.0 and along > length:
		return false

	var perpendicular: float = absf(offset.cross(direction))
	if width > 0.0 and perpendicular > width * 0.5:
		return false
	return true

func get_preview_shape_for_context(context: SkillCastContext) -> Resource:
	var origin := _get_origin(context)
	if not origin.found:
		return null
	var shape := SkillTargetPreviewShape.new()
	shape.shape_type = SkillTargetPreviewShape.ShapeType.LINE
	shape.origin = origin.position
	shape.direction = _get_direction(context)
	shape.length = length
	shape.width = width
	return shape
