class_name SkillAimContextProvider
extends Resource

func prepare_context(_context: SkillCastContext, _controller: SkillAimController) -> void:
	pass

func get_debug_label() -> String:
	return "Aim Context"

func get_validation_errors(_skill: SkillDefinition) -> PackedStringArray:
	return PackedStringArray()
