class_name SkillRequirement
extends Resource

@export var debug_log: bool = false

func get_failure_reason(_caster: Node, _skill: Resource, _targets: Array[Node]) -> String:
	return ""

func _should_log() -> bool:
	return debug_log or ProjectSettings.get_setting("event_channels/debug_log_events", false)
