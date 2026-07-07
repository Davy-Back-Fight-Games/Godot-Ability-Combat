class_name SkillDirectionAimContextProvider
extends "res://addons/ability_combat/runtime/skills/aiming/skill_aim_context_provider.gd"

@export var use_caster_forward_fallback: bool = true

func get_debug_label() -> String:
	return "Direction Aim"

func prepare_context(context: SkillCastContext, controller: SkillAimController) -> void:
	if context == null or controller == null:
		return

	if not controller.aim_with_mouse:
		if not context.has_aim_direction and use_caster_forward_fallback:
			context.set_aim_direction(SkillTargetingGeometry.get_forward(context.caster))
		return

	var aim_state := controller.get_aim_state()
	if aim_state != null and not aim_state.aim_direction.is_zero_approx():
		context.set_aim_direction(aim_state.aim_direction)
		return

	var caster_position := SkillTargetingGeometry.try_get_position(context.caster)
	if caster_position.found:
		var caster_node_2d := SkillTargetingGeometry.get_node2d(context.caster)
		if caster_node_2d != null:
			var direction: Vector2 = caster_node_2d.get_global_mouse_position() - caster_position.position
			if not direction.is_zero_approx():
				context.set_aim_direction(direction)
				return

	if use_caster_forward_fallback:
		context.set_aim_direction(SkillTargetingGeometry.get_forward(context.caster))
