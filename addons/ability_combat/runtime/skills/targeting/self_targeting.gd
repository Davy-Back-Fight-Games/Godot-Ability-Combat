class_name SelfTargeting
extends SkillTargeting

func resolve_targets(caster: Node, _skill: Resource) -> Array[Node]:
	if caster == null:
		return []
	return [caster]

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
	shape.shape_type = SkillTargetPreviewShape.ShapeType.SELF
	shape.origin = position.position
	shape.direction = SkillTargetingGeometry.get_forward_for_context(context) if context != null else SkillTargetingGeometry.get_forward(caster)
	shape.radius = 32.0
	return shape
