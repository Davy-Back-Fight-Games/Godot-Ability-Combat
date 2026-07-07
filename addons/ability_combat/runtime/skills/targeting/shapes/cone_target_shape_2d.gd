class_name ConeTargetShape2D
extends SkillTargetShape2D

@export var radius: float = 0.0
@export_range(0.0, 360.0, 1.0, "degrees") var angle_degrees: float = 90.0

func get_debug_label() -> String:
	return "Cone Target Shape"

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	if radius < 0.0:
		errors.append("%s cone target shape radius cannot be negative" % _skill_label(skill))
	if angle_degrees < 0.0 or angle_degrees > 360.0:
		errors.append("%s cone target shape angle_degrees must be between 0 and 360" % _skill_label(skill))
	return errors

func contains_point(context: SkillCastContext, point: Vector2) -> bool:
	var origin := _get_origin(context)
	if not origin.found:
		return false

	var offset: Vector2 = point - origin.position
	var distance: float = offset.length()
	if radius > 0.0 and distance > radius:
		return false
	if distance == 0.0 or angle_degrees >= 360.0:
		return true

	var half_angle_radians: float = deg_to_rad(clampf(angle_degrees, 0.0, 360.0) * 0.5)
	return _get_direction(context).dot(offset.normalized()) >= cos(half_angle_radians)

func get_preview_shape_for_context(context: SkillCastContext) -> Resource:
	var origin := _get_origin(context)
	if not origin.found:
		return null
	var shape := SkillTargetPreviewShape.new()
	shape.shape_type = SkillTargetPreviewShape.ShapeType.CONE
	shape.origin = origin.position
	shape.direction = _get_direction(context)
	shape.radius = radius
	shape.angle_degrees = angle_degrees
	return shape
