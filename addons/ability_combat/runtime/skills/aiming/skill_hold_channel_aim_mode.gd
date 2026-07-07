class_name SkillHoldChannelAimMode
extends "res://addons/ability_combat/runtime/skills/aiming/skill_instant_aim_mode.gd"

func get_debug_label() -> String:
	return "Hold Channel"

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := super.get_validation_errors(skill)
	if skill == null:
		return errors
	if not skill.should_cancel_channel_on_input_release():
		errors.append("%s Hold Channel aim mode expects cancel_channel_on_input_release" % skill.get_label())
	if skill.get_channel_duration_seconds() <= 0.0:
		errors.append("%s Hold Channel aim mode expects a channel duration" % skill.get_label())
	return errors
