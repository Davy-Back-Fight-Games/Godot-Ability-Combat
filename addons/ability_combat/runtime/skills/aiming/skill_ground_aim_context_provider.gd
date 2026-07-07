class_name SkillGroundAimContextProvider
extends "res://addons/ability_combat/runtime/skills/aiming/skill_aim_context_provider.gd"

@export var max_cast_range: float = 0.0

func get_debug_label() -> String:
	return "Ground Aim"

func prepare_context(context: SkillCastContext, controller: SkillAimController) -> void:
	if context == null or controller == null:
		return

	var target_position := _get_target_position(context, controller)
	if not target_position.found:
		return

	var final_position := _clamp_to_cast_range(context.caster, target_position.position)
	context.set_target_position(final_position)

	var caster_position := SkillTargetingGeometry.try_get_position(context.caster)
	if not caster_position.found:
		return

	var direction: Vector2 = final_position - caster_position.position
	if not direction.is_zero_approx():
		context.set_aim_direction(direction)

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	if max_cast_range < 0.0:
		var skill_label := skill.get_label() if skill != null else "<unnamed skill>"
		errors.append("%s ground aim max_cast_range cannot be negative" % skill_label)
	return errors

func _get_target_position(context: SkillCastContext, controller: SkillAimController) -> Dictionary:
	var aim_state := controller.get_aim_state()
	if aim_state != null and aim_state.has_target_position:
		return {"found": true, "position": aim_state.target_position}

	if not controller.aim_with_mouse:
		return SkillTargetingGeometry.try_get_target_position_for_context(context)

	var caster_node_2d := SkillTargetingGeometry.get_node2d(context.caster)
	if caster_node_2d == null:
		return SkillTargetingGeometry.try_get_target_position_for_context(context)

	return {"found": true, "position": caster_node_2d.get_global_mouse_position()}

func _clamp_to_cast_range(caster: Node, target_position: Vector2) -> Vector2:
	if max_cast_range <= 0.0:
		return target_position

	var caster_position := SkillTargetingGeometry.try_get_position(caster)
	if not caster_position.found:
		return target_position

	var offset: Vector2 = target_position - caster_position.position
	if offset.length() <= max_cast_range:
		return target_position

	return caster_position.position + offset.normalized() * max_cast_range
