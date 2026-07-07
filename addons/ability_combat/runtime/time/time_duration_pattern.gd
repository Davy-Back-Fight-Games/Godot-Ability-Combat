class_name TimeDurationPattern
extends Resource

@export var duration_seconds: FloatReference
@export var infinite: bool = false

func create_state() -> Dictionary:
	return {
		"elapsed": 0.0,
	}

func reset_duration_state(state: Dictionary) -> void:
	state.clear()
	state["elapsed"] = 0.0

func advance(delta: float, state: Dictionary) -> void:
	if not state.has("elapsed"):
		reset_duration_state(state)
	state["elapsed"] = maxf(float(state.get("elapsed", 0.0)) + delta, 0.0)

func get_duration_seconds() -> float:
	if infinite:
		return INF
	if duration_seconds == null:
		return 0.0
	return maxf(duration_seconds.get_value(), 0.0)

func get_elapsed(state: Dictionary) -> float:
	return maxf(float(state.get("elapsed", 0.0)), 0.0)

func get_progress(state: Dictionary) -> float:
	if infinite:
		return 0.0
	var duration := get_duration_seconds()
	if duration <= 0.0:
		return 1.0
	return clampf(get_elapsed(state) / duration, 0.0, 1.0)

func get_remaining_time(state: Dictionary) -> float:
	if infinite:
		return INF
	return maxf(get_duration_seconds() - get_elapsed(state), 0.0)

func is_finished(state: Dictionary) -> bool:
	if infinite:
		return false
	return get_elapsed(state) >= get_duration_seconds()

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not infinite and duration_seconds != null and duration_seconds.get_value() < 0.0:
		errors.append("duration_seconds must be zero or greater.")
	return errors

func get_debug_description() -> String:
	if infinite:
		return "infinite duration"
	return "%s seconds" % get_duration_seconds()
