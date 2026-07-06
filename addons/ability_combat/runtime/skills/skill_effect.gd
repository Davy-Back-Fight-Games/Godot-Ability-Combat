class_name SkillEffect
extends Resource

@export var debug_log: bool = false

func apply(_caster: Node, _skill: Resource, _targets: Array[Node]) -> void:
	pass

func apply_context(context: SkillCastContext) -> void:
	if context == null:
		apply(null, null, [])
		return
	apply(context.caster, context.skill, context.targets)

func _should_log() -> bool:
	return debug_log or ProjectSettings.get_setting("event_channels/debug_log_events", false)
