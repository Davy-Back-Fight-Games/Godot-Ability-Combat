class_name RangeTargetFilter
extends SkillTargetFilter

@export var max_range: float = 0.0
@export var min_range: float = 0.0

func accepts_target(caster: Node, _skill: Resource, target: Node) -> bool:
	var caster_position := SkillTargetingGeometry.try_get_position(caster)
	var target_position := SkillTargetingGeometry.try_get_position(target)
	if not caster_position.found or not target_position.found:
		return false

	var caster_point: Vector2 = caster_position.position
	var target_point: Vector2 = target_position.position
	var distance: float = caster_point.distance_to(target_point)
	if min_range > 0.0 and distance < min_range:
		return false
	if max_range > 0.0 and distance > max_range:
		return false
	return true
