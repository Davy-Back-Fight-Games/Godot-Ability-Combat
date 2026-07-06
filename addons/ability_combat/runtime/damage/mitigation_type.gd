@tool
class_name MitigationType
extends ScriptableEnum

@export var mitigation_stat: StatId
@export var ignores_mitigation: bool = false

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not ignores_mitigation and mitigation_stat == null:
		errors.append("mitigation_stat is required unless ignores_mitigation is true.")
	return errors
