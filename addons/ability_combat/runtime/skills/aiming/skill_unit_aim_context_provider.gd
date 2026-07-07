class_name SkillUnitAimContextProvider
extends "res://addons/ability_combat/runtime/skills/aiming/skill_aim_context_provider.gd"

const TargetableComponentScript := preload("res://addons/ability_combat/runtime/combat/targetable_component.gd")

@export var selectable_runtime_set: RuntimeSet
@export var selection_controller_path: NodePath
@export var prefer_mouse_hover: bool = true
@export var fallback_to_selection: bool = true
@export var require_selectable: bool = true
@export var require_skill_targetable_for_acquisition: bool = false
@export var max_pick_distance: float = 0.0

func get_debug_label() -> String:
	return "Unit Aim"

func prepare_context(context: SkillCastContext, controller: SkillAimController) -> void:
	if context == null or controller == null:
		return

	var selected_target: Node = null
	if prefer_mouse_hover:
		selected_target = _get_hover_target(context, controller)
	if selected_target == null and fallback_to_selection:
		selected_target = _get_selection_target(controller)

	if selected_target == null:
		context.clear_target_node()
		return

	context.set_target_node(selected_target)
	var target_position := SkillTargetingGeometry.try_get_position(selected_target)
	if target_position.found:
		context.set_target_position(target_position.position)
		var caster_position := SkillTargetingGeometry.try_get_position(context.caster)
		if caster_position.found:
			var direction: Vector2 = target_position.position - caster_position.position
			if not direction.is_zero_approx():
				context.set_aim_direction(direction)

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	var skill_label := skill.get_label() if skill != null else "<unnamed skill>"
	if prefer_mouse_hover and selectable_runtime_set == null:
		errors.append("%s unit aim selectable_runtime_set is required for hover acquisition" % skill_label)
	if fallback_to_selection and selection_controller_path.is_empty():
		errors.append("%s unit aim selection_controller_path is required for selected-unit fallback" % skill_label)
	if max_pick_distance < 0.0:
		errors.append("%s unit aim max_pick_distance cannot be negative" % skill_label)
	return errors

func _get_hover_target(context: SkillCastContext, controller: SkillAimController) -> Node:
	if selectable_runtime_set == null:
		return null
	var mouse_position := _get_mouse_position(context, controller)
	if not mouse_position.found:
		return null

	var best_target: Node = null
	var best_distance_squared := INF
	for item in selectable_runtime_set.get_items():
		var selectable := _get_selectable_component(item)
		if selectable == null or not _is_selectable_available(selectable):
			continue
		var owner := _get_selectable_owner(selectable)
		if owner == null:
			continue
		if require_skill_targetable_for_acquisition and not _is_skill_targetable(owner):
			continue
		var target_position := SkillTargetingGeometry.try_get_position(owner)
		if not target_position.found:
			continue
		var pick_distance := _get_pick_distance(selectable)
		var distance_squared: float = mouse_position.position.distance_squared_to(target_position.position)
		if distance_squared > pick_distance * pick_distance:
			continue
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_target = owner

	return best_target

func _get_selection_target(controller: SkillAimController) -> Node:
	var selection_controller := _get_selection_controller(controller)
	if selection_controller == null:
		return null
	var selected_component: Node = null
	if selection_controller.has_method(&"get_selected_component"):
		selected_component = selection_controller.call(&"get_selected_component")
	if selected_component != null:
		if require_selectable and not _is_selectable_available(selected_component):
			return null
		if require_skill_targetable_for_acquisition:
			var owner := _get_selectable_owner(selected_component)
			if owner == null or not _is_skill_targetable(owner):
				return null
			return owner
		return _get_selectable_owner(selected_component)
	if selection_controller.has_method(&"get_selected"):
		return selection_controller.call(&"get_selected")
	return null

func _get_selection_controller(controller: SkillAimController) -> Node:
	if controller == null or selection_controller_path.is_empty():
		return null
	return controller.get_node_or_null(selection_controller_path)

func _get_mouse_position(context: SkillCastContext, controller: SkillAimController) -> Dictionary:
	var aim_state := controller.get_aim_state()
	if aim_state != null and aim_state.has_target_position:
		return {"found": true, "position": aim_state.target_position}
	var caster_node_2d := SkillTargetingGeometry.get_node2d(context.caster)
	if caster_node_2d == null:
		return SkillTargetingGeometry.try_get_target_position_for_context(context)
	return {"found": true, "position": caster_node_2d.get_global_mouse_position()}

func _get_selectable_component(item: Node) -> Node:
	if item == null or not is_instance_valid(item):
		return null
	if not require_selectable:
		return item
	if item.has_method(&"is_selectable") and item.has_method(&"get_selectable_owner"):
		return item
	if item.has_method(&"get_children"):
		for child in item.get_children():
			if child.has_method(&"is_selectable") and child.has_method(&"get_selectable_owner"):
				return child
	return null

func _is_selectable_available(selectable: Node) -> bool:
	if selectable == null or not is_instance_valid(selectable):
		return false
	if require_selectable and selectable.has_method(&"is_selectable"):
		return selectable.call(&"is_selectable")
	return true

func _get_selectable_owner(selectable: Node) -> Node:
	if selectable == null or not is_instance_valid(selectable):
		return null
	if selectable.has_method(&"get_selectable_owner"):
		return selectable.call(&"get_selectable_owner")
	return selectable

func _get_pick_distance(selectable: Node) -> float:
	if max_pick_distance > 0.0:
		return max_pick_distance
	var pick_radius = selectable.get(&"pick_radius")
	if pick_radius is float or pick_radius is int:
		return maxf(float(pick_radius), 0.0)
	return 0.0

func _is_skill_targetable(target: Node) -> bool:
	if target == null:
		return false
	var targetable = TargetableComponentScript.find_for_node(target)
	if targetable != null:
		return targetable.is_skill_targetable()
	if target.has_method(&"is_skill_targetable"):
		return target.call(&"is_skill_targetable")
	return true
