class_name SkillDefinition
extends Resource

const TimeIntervalPattern = preload("res://addons/ability_combat/runtime/time/time_interval_pattern.gd")
const TimeDurationPattern = preload("res://addons/ability_combat/runtime/time/time_duration_pattern.gd")

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var aim_mode: Resource
@export var cost: SkillCost
@export var cooldown_seconds: FloatReference
@export var max_charges: int = 1
@export var recharge_seconds: float = 0.0
@export var recast_window_seconds: float = 0.0
@export var cooldown_group: StringName = &""
@export var cooldown_group_seconds: float = 0.0
@export var cast_duration_pattern: TimeDurationPattern
@export var cast_point_seconds: float = 0.0
@export var channel_duration_pattern: TimeDurationPattern
@export var channel_tick_interval_pattern: TimeIntervalPattern
@export var cancel_channel_on_input_release: bool = false
@export var interruptible_by_status: bool = true
@export var interruptible_by_movement: bool = false
@export var targeting: Resource
@export var allowed_slot_types: Array[SkillSlotType] = []
@export var requirements: Array[Resource] = []
@export var effects: Array[SkillEffect] = []
@export var timed_effects: Array[Resource] = []
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

func get_max_charges() -> int:
	return maxi(max_charges, 1)

func get_recharge_seconds() -> float:
	return maxf(recharge_seconds, 0.0)

func get_recast_window_seconds() -> float:
	return maxf(recast_window_seconds, 0.0)

func get_cooldown_group() -> StringName:
	return cooldown_group

func get_cooldown_group_seconds() -> float:
	if cooldown_group == &"":
		return 0.0
	if cooldown_group_seconds > 0.0:
		return cooldown_group_seconds
	return get_cooldown_seconds()

func get_cast_time_seconds() -> float:
	if cast_duration_pattern != null:
		return cast_duration_pattern.get_duration_seconds()
	return 0.0

func get_cast_point_seconds() -> float:
	var cast_time := get_cast_time_seconds()
	if cast_time <= 0.0:
		return 0.0
	if cast_point_seconds <= 0.0:
		return cast_time
	return clampf(cast_point_seconds, 0.0, cast_time)

func get_channel_duration_seconds() -> float:
	if channel_duration_pattern != null:
		return channel_duration_pattern.get_duration_seconds()
	return 0.0

func get_channel_tick_interval_pattern() -> TimeIntervalPattern:
	if get_channel_duration_seconds() <= 0.0:
		return null
	return channel_tick_interval_pattern

func should_cancel_channel_on_input_release() -> bool:
	return cancel_channel_on_input_release

func is_interruptible_by_status() -> bool:
	return interruptible_by_status

func is_interruptible_by_movement() -> bool:
	return interruptible_by_movement

func can_assign_to_slot_type(slot_type: SkillSlotType) -> bool:
	if slot_type == null or allowed_slot_types.is_empty():
		return false
	return allowed_slot_types.has(slot_type)

func can_assign_to_slot(slot_definition: SkillSlotDefinition) -> bool:
	if slot_definition == null:
		return false
	return can_assign_to_slot_type(slot_definition.slot_type)

func get_aim_mode() -> Resource:
	return aim_mode

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
	var resolved_aim_mode := get_aim_mode()
	if resolved_aim_mode == null:
		errors.append("%s has no aim mode" % get_label())
	else:
		var aim_mode_errors := _get_aim_mode_interface_errors(resolved_aim_mode)
		if not aim_mode_errors.is_empty():
			for aim_mode_error in aim_mode_errors:
				errors.append("%s aim_mode %s" % [get_label(), aim_mode_error])
		if resolved_aim_mode.has_method("get_validation_errors"):
			for error in resolved_aim_mode.get_validation_errors(self):
				errors.append(error)
	if targeting != null and targeting.has_method("get_validation_errors"):
		for error in targeting.get_validation_errors(self):
			errors.append(error)
	if cast_duration_pattern != null:
		for error in cast_duration_pattern.get_validation_errors():
			errors.append("%s cast_duration_pattern %s" % [get_label(), error])
	if channel_duration_pattern != null:
		for error in channel_duration_pattern.get_validation_errors():
			errors.append("%s channel_duration_pattern %s" % [get_label(), error])
	if channel_tick_interval_pattern != null:
		for error in channel_tick_interval_pattern.get_validation_errors():
			errors.append("%s channel_tick_interval_pattern %s" % [get_label(), error])
	for timed_effect in timed_effects:
		if timed_effect == null:
			continue
		if timed_effect.has_method("get_validation_errors"):
			for error in timed_effect.get_validation_errors():
				errors.append(error)
	return errors

func _is_aim_mode_valid(value: Resource) -> bool:
	return _get_aim_mode_interface_errors(value).is_empty()

func _get_aim_mode_interface_errors(value: Resource) -> PackedStringArray:
	var errors := PackedStringArray()
	if value == null:
		errors.append("is null")
		return errors
	if not value.has_method("casts_on_press"):
		errors.append("is missing casts_on_press")
	if not value.has_method("uses_preview"):
		errors.append("is missing uses_preview")
	if not value.has_method("casts_on_release"):
		errors.append("is missing casts_on_release")
	if not value.has_method("casts_on_confirm"):
		errors.append("is missing casts_on_confirm")
	if not value.has_method("get_validation_errors"):
		errors.append("is missing get_validation_errors")
	if not value.has_method("get_debug_label"):
		errors.append("is missing get_debug_label")
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
