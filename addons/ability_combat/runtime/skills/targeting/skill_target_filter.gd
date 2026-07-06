class_name SkillTargetFilter
extends Resource

@export var debug_log: bool = false

func accepts_target(_caster: Node, _skill: Resource, _target: Node) -> bool:
	return true

func _should_log() -> bool:
	return debug_log or ProjectSettings.get_setting("event_channels/debug_log_events", false)
