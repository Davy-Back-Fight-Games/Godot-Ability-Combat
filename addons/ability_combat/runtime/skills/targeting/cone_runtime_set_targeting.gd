class_name ConeRuntimeSetTargeting
extends FilteredRuntimeSetTargeting

@export var radius: float = 0.0
@export_range(0.0, 360.0, 1.0, "degrees") var angle_degrees: float = 90.0

func get_preview_shape(caster: Node, _skill: Resource) -> Resource:
	return _get_preview_shape(caster, null)

func get_preview_shape_for_context(context: SkillCastContext) -> Resource:
	if context == null:
		return null
	return _get_preview_shape(context.caster, context)

func _get_preview_shape(caster: Node, context: SkillCastContext) -> Resource:
	var position := SkillTargetingGeometry.try_get_position(caster)
	if not position.found:
		return null

	var shape := SkillTargetPreviewShape.new()
	shape.shape_type = SkillTargetPreviewShape.ShapeType.CONE
	shape.origin = position.position
	shape.direction = SkillTargetingGeometry.get_forward_for_context(context) if context != null else SkillTargetingGeometry.get_forward(caster)
	shape.radius = radius
	shape.angle_degrees = angle_degrees
	return shape

func _accepts_shape(caster: Node, target: Node, context: SkillCastContext = null) -> bool:
	var caster_position := SkillTargetingGeometry.try_get_position(caster)
	var target_position := SkillTargetingGeometry.try_get_position(target)
	if not caster_position.found or not target_position.found:
		return false

	var caster_point: Vector2 = caster_position.position
	var target_point: Vector2 = target_position.position
	var offset: Vector2 = target_point - caster_point
	var distance: float = offset.length()
	if radius > 0.0 and distance > radius:
		return false
	if distance == 0.0 or angle_degrees >= 360.0:
		return true

	var forward: Vector2 = SkillTargetingGeometry.get_forward_for_context(context) if context != null else SkillTargetingGeometry.get_forward(caster)
	var half_angle_radians: float = deg_to_rad(clampf(angle_degrees, 0.0, 360.0) * 0.5)
	return forward.dot(offset.normalized()) >= cos(half_angle_radians)
