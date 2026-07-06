@tool
class_name DamageType
extends ScriptableEnum

@export var mitigation_type: MitigationType

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if mitigation_type == null:
		errors.append("mitigation_type is required.")
		return errors

	for error in mitigation_type.get_validation_errors():
		errors.append("mitigation_type: %s" % error)
	return errors
