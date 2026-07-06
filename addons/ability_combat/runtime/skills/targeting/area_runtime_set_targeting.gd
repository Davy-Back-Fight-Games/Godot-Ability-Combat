class_name AreaRuntimeSetTargeting
extends FilteredRuntimeSetTargeting

@export var radius: float = 0.0

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
	shape.shape_type = SkillTargetPreviewShape.ShapeType.CIRCLE
	shape.origin = position.position
	shape.direction = SkillTargetingGeometry.get_forward_for_context(context) if context != null else SkillTargetingGeometry.get_forward(caster)
	shape.radius = radius
	return shape

func _accepts_shape(caster: Node, target: Node, _context: SkillCastContext = null) -> bool:
	if radius <= 0.0:
		return true

	var caster_position := SkillTargetingGeometry.try_get_position(caster)
	var target_position := SkillTargetingGeometry.try_get_position(target)
	if not caster_position.found or not target_position.found:
		return false

	var caster_point: Vector2 = caster_position.position
	var target_point: Vector2 = target_position.position
	return caster_point.distance_to(target_point) <= radius
