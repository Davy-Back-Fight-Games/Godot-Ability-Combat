class_name PulseRegenerationStrategy
extends ResourceRegenerationStrategy

const TimeIntervalPattern = preload("res://addons/ability_combat/runtime/time/time_interval_pattern.gd")

@export var amount: FloatReference
@export var interval_seconds: float = 1.0
@export var interval_pattern: TimeIntervalPattern

func get_regeneration_amount(delta: float, stats_component: StatsComponent, rule: ResourceRegenerationRule, state: Dictionary) -> float:
	var pulse_amount := maxf(get_amount(), 0.0)
	if pulse_amount <= 0.0:
		return 0.0
	if interval_pattern != null:
		var tick_state: Dictionary = state.get("interval_pattern", {})
		if tick_state.is_empty():
			tick_state = interval_pattern.create_state()
			state["interval_pattern"] = tick_state
		return interval_pattern.advance(delta, tick_state) * pulse_amount

	var interval := interval_seconds
	if interval <= 0.0:
		return 0.0

	var elapsed := float(state.get("elapsed", 0.0)) + delta
	var pulse_count := int(floor(elapsed / interval))
	state["elapsed"] = fmod(elapsed, interval)
	return pulse_count * pulse_amount

func reset_regeneration_state(state: Dictionary) -> void:
	state.clear()
	if interval_pattern != null:
		state["interval_pattern"] = interval_pattern.create_state()
	else:
		state["elapsed"] = 0.0

func get_amount() -> float:
	if amount == null:
		return 0.0
	return amount.get_value()

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if interval_pattern != null:
		errors.append_array(interval_pattern.get_validation_errors())
	elif interval_seconds <= 0.0:
		errors.append("interval_seconds must be greater than zero.")
	if amount != null and amount.get_value() < 0.0:
		errors.append("amount must be non-negative.")
	return errors

func get_debug_description() -> String:
	if interval_pattern != null:
		return "%s %s" % [get_amount(), interval_pattern.get_debug_description()]
	return "%s every %s seconds" % [get_amount(), interval_seconds]
