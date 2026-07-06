@tool
class_name IntReference
extends Resource

@export var use_constant: bool = true
@export var constant_value: int = 0
@export var variable: IntVariable

func get_value() -> int:
	if use_constant or variable == null:
		return constant_value
	return variable.value

func set_value(new_value: int) -> void:
	if use_constant or variable == null:
		constant_value = new_value
		return
	variable.set_value(new_value)

func apply_change(amount: int) -> void:
	set_value(get_value() + amount)
