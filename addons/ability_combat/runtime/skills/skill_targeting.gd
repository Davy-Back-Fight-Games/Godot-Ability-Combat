class_name SkillTargeting
extends Resource

const TargetableComponentScript := preload("res://addons/ability_combat/runtime/combat/targetable_component.gd")

@export var debug_log: bool = false

func resolve_targets(_caster: Node, _skill: Resource) -> Array[Node]:
	return []

func resolve_targets_for_context(context: SkillCastContext) -> Array[Node]:
	if context == null:
		return []
	return resolve_targets(context.caster, context.skill)

func resolve_preview_targets(caster: Node, skill: Resource) -> Array[Node]:
	return resolve_targets(caster, skill)

func resolve_preview_targets_for_context(context: SkillCastContext) -> Array[Node]:
	return resolve_targets_for_context(context)

func get_preview_shape(_caster: Node, _skill: Resource) -> Resource:
	return null

func get_preview_shape_for_context(context: SkillCastContext) -> Resource:
	if context == null:
		return null
	return get_preview_shape(context.caster, context.skill)

func _is_skill_targetable(target: Node) -> bool:
	if target == null:
		return false
	var targetable = TargetableComponentScript.find_for_node(target)
	if targetable != null:
		return targetable.is_skill_targetable()
	if target.has_method(&"is_skill_targetable"):
		return target.call(&"is_skill_targetable")
	return true

func _should_log() -> bool:
	return debug_log or ProjectSettings.get_setting("event_channels/debug_log_events", false)
