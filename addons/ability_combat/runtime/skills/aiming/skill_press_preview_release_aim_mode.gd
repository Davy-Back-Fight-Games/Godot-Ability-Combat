class_name SkillPressPreviewReleaseAimMode
extends "res://addons/ability_combat/runtime/skills/aiming/skill_aim_mode.gd"

func uses_preview() -> bool:
	return true

func casts_on_release() -> bool:
	return true

func get_debug_label() -> String:
	return "Preview Release"
