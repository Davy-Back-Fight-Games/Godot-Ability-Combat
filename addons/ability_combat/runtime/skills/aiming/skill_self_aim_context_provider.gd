class_name SkillSelfAimContextProvider
extends "res://addons/ability_combat/runtime/skills/aiming/skill_aim_context_provider.gd"

func get_debug_label() -> String:
	return "Self Aim"

func prepare_context(_context: SkillCastContext, _controller: SkillAimController) -> void:
	pass
