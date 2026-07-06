class_name MovementSpeedMultiplierStatusModule
extends StatusEffectModule

@export_range(0.0, 3.0, 0.01) var multiplier := 1.0

func get_movement_speed_multiplier(_instance, _controller) -> float:
	return multiplier
