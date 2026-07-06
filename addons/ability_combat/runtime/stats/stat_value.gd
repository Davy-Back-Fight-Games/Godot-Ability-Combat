class_name StatValue
extends Resource

signal value_changed(value: float)

@export var id: StatId
@export var initial_value: float = 0.0
@export var value: float = 0.0:
	set(new_value):
		if is_equal_approx(value, new_value):
			return
		value = new_value
		value_changed.emit(value)

func reset_to_initial_value() -> void:
	set_value(initial_value)

func set_value(new_value: float) -> void:
	value = new_value

func apply_change(amount: float) -> void:
	set_value(value + amount)
