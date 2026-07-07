class_name UnitTargeting
extends SkillTargeting

@export var filters: Array[Resource] = []
@export var exclude_caster: bool = false

func resolve_targets_for_context(context: SkillCastContext) -> Array[Node]:
	return _resolve_targets(context)

func resolve_preview_targets_for_context(context: SkillCastContext) -> Array[Node]:
	return _resolve_targets(context)

func get_preview_shape_for_context(context: SkillCastContext) -> Resource:
	if context == null:
		return null
	var target := context.get_target_node_or_null()
	if target == null:
		return null
	var position := SkillTargetingGeometry.try_get_position(target)
	if not position.found:
		return null

	var shape := SkillTargetPreviewShape.new()
	shape.shape_type = SkillTargetPreviewShape.ShapeType.RETICLE
	shape.origin = position.position
	shape.direction = SkillTargetingGeometry.get_forward_for_context(context)
	shape.radius = 28.0
	return shape

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	for filter in filters:
		if filter == null:
			continue
		if not filter.has_method(&"accepts_target"):
			var skill_label := skill.get_label() if skill != null else "<unnamed skill>"
			errors.append("%s unit targeting filter %s is missing accepts_target" % [skill_label, _resource_label(filter)])
	return errors

func get_debug_label() -> String:
	return "Unit Targeting"

func _resolve_targets(context: SkillCastContext) -> Array[Node]:
	if context == null:
		return []
	var target := context.get_target_node_or_null()
	if target == null:
		_log_resolved(null, false)
		return []
	if exclude_caster and target == context.caster:
		_log_resolved(target, false)
		return []
	if not _is_skill_targetable(target):
		_log_resolved(target, false)
		return []
	if not _accepts_filters(context.caster, context.skill, target):
		_log_resolved(target, false)
		return []

	_log_resolved(target, true)
	return [target]

func _accepts_filters(caster: Node, skill: Resource, target: Node) -> bool:
	for filter in filters:
		if filter == null or not filter.has_method(&"accepts_target"):
			continue
		if not filter.accepts_target(caster, skill, target):
			return false
	return true

func _log_resolved(target: Node, accepted: bool) -> void:
	if not _should_log():
		return
	var target_label := target.name if target != null else "<none>"
	print("[UnitTargeting] target=%s accepted=%s" % [target_label, accepted])

func _resource_label(value: Resource) -> String:
	if value.resource_path != "":
		return value.resource_path
	return value.get_class()
