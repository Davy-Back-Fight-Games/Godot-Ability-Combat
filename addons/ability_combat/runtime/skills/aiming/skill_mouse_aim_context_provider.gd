class_name SkillMouseAimContextProvider
extends "res://addons/ability_combat/runtime/skills/aiming/skill_aim_context_provider.gd"

func get_debug_label() -> String:
	return "Mouse Aim"

func prepare_context(context: SkillCastContext, controller: SkillAimController) -> void:
	if context == null or controller == null or not controller.aim_with_mouse:
		return

	var aim_state := controller.get_aim_state()
	if aim_state != null:
		if aim_state.has_target_position:
			context.set_target_position(aim_state.target_position)
		context.set_aim_direction(aim_state.aim_direction)
		return

	var caster_position := SkillTargetingGeometry.try_get_position(context.caster)
	if not caster_position.found:
		return

	var caster_node_2d := SkillTargetingGeometry.get_node2d(context.caster)
	if caster_node_2d == null:
		return

	var target_position := caster_node_2d.get_global_mouse_position()
	context.set_target_position(target_position)

	var direction: Vector2 = target_position - caster_position.position
	if not direction.is_zero_approx():
		context.set_aim_direction(direction)
