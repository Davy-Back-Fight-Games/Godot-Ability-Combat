@tool
class_name SkillLifecycleEvent
extends TypedGameEvent

signal raised(payload: Resource)

func emit(payload: Resource, emitter: Object = null) -> void:
	_log_emit(payload, emitter)
	raised.emit(payload)

func get_payload_script() -> Script:
	return SkillLifecyclePayload
