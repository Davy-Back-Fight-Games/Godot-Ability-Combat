class_name LinearRegenerationStrategy
extends ResourceRegenerationStrategy

@export var amount_per_second: FloatReference

func get_regeneration_amount(delta: float, stats_component: StatsComponent, rule: ResourceRegenerationRule, state: Dictionary) -> float:
	return maxf(get_amount_per_second(), 0.0) * delta

func get_amount_per_second() -> float:
	if amount_per_second == null:
		return 0.0
	return amount_per_second.get_value()

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if amount_per_second != null and amount_per_second.get_value() < 0.0:
		errors.append("amount_per_second must be non-negative.")
	return errors

func get_debug_description() -> String:
	return "%s per second" % get_amount_per_second()
