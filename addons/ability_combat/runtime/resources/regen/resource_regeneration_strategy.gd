class_name ResourceRegenerationStrategy
extends Resource

func get_regeneration_amount(delta: float, stats_component: StatsComponent, rule: ResourceRegenerationRule, state: Dictionary) -> float:
	return 0.0

func reset_regeneration_state(state: Dictionary) -> void:
	state.clear()

func get_validation_errors() -> PackedStringArray:
	return PackedStringArray()

func get_debug_description() -> String:
	return get_class()
