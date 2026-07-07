class_name SkillInstantAimMode
extends "res://addons/ability_combat/runtime/skills/aiming/skill_aim_mode.gd"

func casts_on_press() -> bool:
	return true

func get_debug_label() -> String:
	return "Instant"
