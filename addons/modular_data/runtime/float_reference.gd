@tool
class_name FloatReference
extends Resource

@export var use_constant: bool = true
@export var constant_value: float = 0.0
@export var variable: FloatVariable

func get_value() -> float:
	if use_constant or variable == null:
		return constant_value
	return variable.value

func set_value(new_value: float) -> void:
	if use_constant or variable == null:
		constant_value = new_value
		return
	variable.set_value(new_value)

func apply_change(amount: float) -> void:
	set_value(get_value() + amount)
