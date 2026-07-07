class_name TimeIntervalPattern
extends Resource

const MIN_INTERVAL_SECONDS := 0.001

@export var interval_seconds: FloatReference
@export var fire_immediately: bool = false
@export var max_ticks_per_step: int = 0

func create_state() -> Dictionary:
	return {
		"elapsed": 0.0,
		"fired_immediately": false,
	}

func reset_interval_state(state: Dictionary) -> void:
	state.clear()
	state["elapsed"] = 0.0
	state["fired_immediately"] = false

func advance(delta: float, state: Dictionary) -> int:
	if not state.has("elapsed"):
		reset_interval_state(state)

	var interval := get_interval_seconds()
	var ticks := 0
	if fire_immediately and not bool(state.get("fired_immediately", false)):
		ticks += 1
		state["fired_immediately"] = true

	var elapsed := maxf(float(state.get("elapsed", 0.0)) + delta, 0.0)
	var interval_ticks := int(floor(elapsed / interval))
	if interval_ticks > 0:
		var consumed_interval_ticks := interval_ticks
		if max_ticks_per_step > 0:
			consumed_interval_ticks = mini(interval_ticks, maxi(max_ticks_per_step - ticks, 0))
		ticks += consumed_interval_ticks
		elapsed -= consumed_interval_ticks * interval
	state["elapsed"] = elapsed

	if max_ticks_per_step > 0 and ticks > max_ticks_per_step:
		return max_ticks_per_step
	return ticks

func get_interval_seconds() -> float:
	if interval_seconds == null:
		return MIN_INTERVAL_SECONDS
	return maxf(interval_seconds.get_value(), MIN_INTERVAL_SECONDS)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if interval_seconds == null:
		errors.append("interval_seconds is required.")
	elif interval_seconds.get_value() <= 0.0:
		errors.append("interval_seconds must be greater than zero.")
	if max_ticks_per_step < 0:
		errors.append("max_ticks_per_step must be zero or greater.")
	return errors

func get_debug_description() -> String:
	var tick_limit := "unlimited"
	if max_ticks_per_step > 0:
		tick_limit = str(max_ticks_per_step)
	return "every %s seconds, fire_immediately=%s, max_ticks_per_step=%s" % [get_interval_seconds(), fire_immediately, tick_limit]
