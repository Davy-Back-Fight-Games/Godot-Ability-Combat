class_name LineRuntimeSetTargeting
extends FilteredRuntimeSetTargeting

@export var length: float = 0.0
@export var width: float = 0.0

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
	shape.shape_type = SkillTargetPreviewShape.ShapeType.LINE
	shape.origin = position.position
	shape.direction = SkillTargetingGeometry.get_forward_for_context(context) if context != null else SkillTargetingGeometry.get_forward(caster)
	shape.length = length
	shape.width = width
	return shape

func _accepts_shape(caster: Node, target: Node, context: SkillCastContext = null) -> bool:
	var caster_position := SkillTargetingGeometry.try_get_position(caster)
	var target_position := SkillTargetingGeometry.try_get_position(target)
	if not caster_position.found or not target_position.found:
		return false

	var caster_point: Vector2 = caster_position.position
	var target_point: Vector2 = target_position.position
	var forward: Vector2 = SkillTargetingGeometry.get_forward_for_context(context) if context != null else SkillTargetingGeometry.get_forward(caster)
	var offset: Vector2 = target_point - caster_point
	var along: float = offset.dot(forward)
	if along < 0.0:
		return false
	if length > 0.0 and along > length:
		return false

	var perpendicular: float = absf(offset.cross(forward))
	if width > 0.0 and perpendicular > width * 0.5:
		return false
	return true
