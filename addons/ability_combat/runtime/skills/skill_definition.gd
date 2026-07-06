class_name SkillDefinition
extends Resource

enum CastMode {
	INSTANT,
	PRESS_PREVIEW_RELEASE_CAST,
	PRESS_PREVIEW_CONFIRM_CAST,
}

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cast_mode: CastMode = CastMode.INSTANT
@export var cost: SkillCost
@export var cooldown_seconds: FloatReference
@export var targeting: Resource
@export var allowed_slot_types: Array[SkillSlotType] = []
@export var requirements: Array[Resource] = []
@export var effects: Array[SkillEffect] = []
@export var debug_log: bool = false

func can_activate() -> bool:
	return cost == null or cost.can_pay()

func check_activation(caster: Node):
	return check_activation_context(SkillCastContext.new(caster, self))

func check_activation_context(context: SkillCastContext):
	if context == null:
		context = SkillCastContext.new(null, self)
	if context.skill == null:
		context.skill = self
	var targets := _resolve_targets_for_context(context)
	context.targets = targets
	for requirement in requirements:
		if requirement == null or not requirement.has_method("get_failure_reason"):
			continue
		var failure_reason: String = requirement.get_failure_reason(context.caster, self, targets)
		if failure_reason != "":
			_log("blocked by requirement: %s" % failure_reason)
			return _activation_result(false, failure_reason, targets)

	if cost != null and not cost.can_pay_context(context):
		_log("blocked by cost")
		return _activation_result(false, "cost", targets)

	return _activation_result(true, "", targets)

func get_activation_failure_reason(caster: Node) -> String:
	var result = check_activation(caster)
	return result.reason

func activate(caster: Node, activation = null) -> bool:
	return activate_context(SkillCastContext.new(caster, self), activation)

func activate_context(context: SkillCastContext, activation = null) -> bool:
	if context == null:
		context = SkillCastContext.new(null, self)
	if context.skill == null:
		context.skill = self
	if activation == null:
		activation = check_activation_context(context)

	if not activation.success:
		return false
	context.targets = activation.targets

	if cost != null and not cost.pay_context(context):
		return false

	for effect in effects:
		if effect == null:
			continue
		effect.apply_context(context)

	_log("activated")
	return true

func _resolve_targets(caster: Node) -> Array[Node]:
	return _resolve_targets_for_context(SkillCastContext.new(caster, self))

func _resolve_targets_for_context(context: SkillCastContext) -> Array[Node]:
	if targeting == null:
		if context == null or context.caster == null:
			return []
		return [context.caster]
	if targeting.has_method("resolve_targets_for_context"):
		return targeting.resolve_targets_for_context(context)
	if not targeting.has_method("resolve_targets") or context == null:
		return []
	return targeting.resolve_targets(context.caster, self)

func _activation_result(success: bool, reason: String, targets: Array[Node]):
	var result = SkillActivationResult.new()
	result.success = success
	result.reason = reason
	result.targets = targets
	return result

func get_cooldown_seconds() -> float:
	if cooldown_seconds == null:
		return 0.0
	return maxf(cooldown_seconds.get_value(), 0.0)

func can_assign_to_slot_type(slot_type: SkillSlotType) -> bool:
	if slot_type == null or allowed_slot_types.is_empty():
		return false
	return allowed_slot_types.has(slot_type)

func can_assign_to_slot(slot_definition: SkillSlotDefinition) -> bool:
	if slot_definition == null:
		return false
	return can_assign_to_slot_type(slot_definition.slot_type)

func get_allowed_slot_type_labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for slot_type in allowed_slot_types:
		if slot_type != null:
			labels.append(slot_type.get_label())
	return labels

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if allowed_slot_types.is_empty():
		errors.append("%s has no allowed_slot_types" % get_label())
	return errors

func get_label() -> String:
	if display_name != "":
		return display_name
	if resource_path != "":
		return resource_path
	return "<unnamed skill>"

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[SkillDefinition] %s %s" % [get_label(), message])
