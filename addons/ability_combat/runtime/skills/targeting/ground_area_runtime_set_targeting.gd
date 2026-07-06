class_name GroundAreaRuntimeSetTargeting
extends FilteredRuntimeSetTargeting

@export var radius: float = 0.0
@export var max_cast_range: float = 0.0

func get_preview_shape(caster: Node, _skill: Resource) -> Resource:
	return _get_preview_shape(caster, null)

func get_preview_shape_for_context(context: SkillCastContext) -> Resource:
	if context == null:
		return null
	return _get_preview_shape(context.caster, context)

func _get_preview_shape(caster: Node, context: SkillCastContext) -> Resource:
	var ground_position := _get_ground_position(caster, context)
	if not ground_position.found:
		return null

	var shape := SkillTargetPreviewShape.new()
	shape.shape_type = SkillTargetPreviewShape.ShapeType.CIRCLE
	shape.origin = ground_position.position
	shape.direction = SkillTargetingGeometry.get_forward_for_context(context) if context != null else SkillTargetingGeometry.get_forward(caster)
	shape.radius = radius
	return shape

func _accepts_shape(caster: Node, target: Node, context: SkillCastContext = null) -> bool:
	if radius <= 0.0:
		return true

	var ground_position := _get_ground_position(caster, context)
	var target_position := SkillTargetingGeometry.try_get_position(target)
	if not ground_position.found or not target_position.found:
		return false

	return ground_position.position.distance_to(target_position.position) <= radius

func _get_ground_position(caster: Node, context: SkillCastContext = null) -> Dictionary:
	var target_position := SkillTargetingGeometry.try_get_target_position_for_context(context) if context != null else SkillTargetingGeometry.try_get_target_position(caster)
	if not target_position.found:
		target_position = SkillTargetingGeometry.try_get_position(caster)
	if not target_position.found or max_cast_range <= 0.0:
		return target_position

	var caster_position := SkillTargetingGeometry.try_get_position(caster)
	if not caster_position.found:
		return target_position

	var offset: Vector2 = target_position.position - caster_position.position
	if offset.length() <= max_cast_range:
		return target_position

	return {"found": true, "position": caster_position.position + offset.normalized() * max_cast_range}
